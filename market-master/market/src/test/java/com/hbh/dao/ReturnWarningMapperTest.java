package com.hbh.dao;

import static org.junit.Assert.*;

import java.io.FileInputStream;
import java.io.InputStream;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.List;
import java.util.Properties;

import org.apache.ibatis.builder.xml.XMLMapperBuilder;
import org.apache.ibatis.datasource.unpooled.UnpooledDataSource;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.junit.After;
import org.junit.Assume;
import org.junit.Before;
import org.junit.Test;

import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.github.pagehelper.PageInterceptor;
import com.hbh.entity.ReturnWarning;
import com.hbh.entity.ReturnWarningCriteria;
import com.hbh.service.ReturnWarningService;

/** Opt-in MySQL checks. Connection-local temporary tables shadow the real tables. */
public class ReturnWarningMapperTest {
    private SqlSession session;
    private ReturnWarningMapper mapper;
    private Connection connection;
    private final LocalDate today = LocalDate.of(2026, 11, 10);
    private final ReturnWarningCriteria criteria = new ReturnWarningCriteria(30, 10,
            new BigDecimal("20"), today);

    @Before
    public void setUp() throws Exception {
        String propertiesPath = System.getProperty("market.test.db");
        Assume.assumeTrue("Set -Dmarket.test.db to a local db.properties file", propertiesPath != null);
        Properties properties = new Properties();
        try (InputStream input = new FileInputStream(propertiesPath)) {
            properties.load(input);
        }
        UnpooledDataSource dataSource = new UnpooledDataSource(properties.getProperty("driver"),
                properties.getProperty("url"), properties.getProperty("user"), properties.getProperty("password"));
        Configuration configuration = new Configuration(new Environment("return-warning-test",
                new JdbcTransactionFactory(), dataSource));
        PageInterceptor pageInterceptor = new PageInterceptor();
        pageInterceptor.setProperties(new Properties());
        configuration.addInterceptor(pageInterceptor);
        String resource = "mapper/ReturnWarningMapper.xml";
        try (InputStream input = getClass().getClassLoader().getResourceAsStream(resource)) {
            new XMLMapperBuilder(input, configuration, resource, configuration.getSqlFragments()).parse();
        }
        session = new SqlSessionFactoryBuilder().build(configuration).openSession();
        connection = session.getConnection();
        try (Statement statement = connection.createStatement()) {
            statement.execute("CREATE TEMPORARY TABLE sale (proid INT, num INT, saledate DATE)");
            statement.execute("CREATE TEMPORARY TABLE cusretire (proid INT, pname VARCHAR(100), num INT, retdate DATE)");
            statement.execute("CREATE TEMPORARY TABLE product (proid INT PRIMARY KEY, pname VARCHAR(100))");
        }
        mapper = session.getMapper(ReturnWarningMapper.class);
    }

    @After
    public void tearDown() {
        PageHelper.clearPage();
        if (session != null) {
            session.rollback();
            session.close();
        }
    }

    @Test
    public void independentlyAggregatesMultipleSalesAndReturns() throws Exception {
        sale(1, 100, today);
        sale(1, 100, today.minusDays(1));
        returned(1, 10, today);
        returned(1, 5, today.minusDays(1));
        sale(2, 10, today);
        returned(2, 2, today);
        List<ReturnWarning> warnings = mapper.selectWarnings(criteria);
        assertEquals(2, warnings.size());
        ReturnWarning first = warnings.get(0);
        assertEquals("1", first.getProid());
        assertEquals(200, first.getSaleQuantity());
        assertEquals(15, first.getReturnQuantity());
        assertRate("7.50", first);
        assertTrue(first.isQuantityWarning());
        assertFalse(first.isRateWarning());
        assertFalse(warnings.get(1).isQuantityWarning());
        assertTrue(warnings.get(1).isRateWarning());
        assertRate("20.00", warnings.get(1));
        assertEquals(2, mapper.countWarnings(criteria));
    }

    @Test
    public void includesExactThresholdsButExcludesBelowThreshold() throws Exception {
        returned(1, 10, today);
        sale(2, 5, today);
        returned(2, 1, today);
        sale(3, 100, today);
        returned(3, 9, today);
        assertEquals(2, mapper.countWarnings(criteria));
        ReturnWarning noSales = mapper.selectWarnings(criteria).get(0);
        assertEquals(0, noSales.getSaleQuantity());
        assertNull(noSales.getReturnRate());
        assertFalse(noSales.isRateWarning());
    }

    @Test
    public void respectsInclusiveDateBoundsAndIgnoresMissingDatesAndNonpositiveQuantities() throws Exception {
        returned(1, 5, today.minusDays(29));
        returned(1, 5, today);
        returned(1, 500, today.minusDays(30));
        returned(1, 500, today.plusDays(1));
        returned(1, 500, null);
        returned(1, 0, today);
        returned(1, -50, today);
        sale(1, 25, today.minusDays(29));
        sale(1, 25, today);
        sale(1, 500, today.minusDays(30));
        sale(1, 500, today.plusDays(1));
        sale(1, 500, null);
        sale(1, -50, today);
        ReturnWarning warning = mapper.selectWarnings(criteria).get(0);
        assertEquals(10, warning.getReturnQuantity());
        assertEquals(50, warning.getSaleQuantity());
        assertRate("20.00", warning);
        assertTrue(warning.isQuantityWarning());
        assertTrue(warning.isRateWarning());
        assertEquals(Date.valueOf(today), warning.getLastReturnDate());
    }

    @Test
    public void retainsReturnsForDeletedProductsAndSupportsRatesAboveOneHundred() throws Exception {
        sale(1, 1, today);
        returned(1, 3, today);
        ReturnWarning warning = mapper.selectWarnings(criteria).get(0);
        assertEquals("product-1", warning.getPname());
        assertRate("300.00", warning);
        assertTrue(warning.isRateWarning());
    }

    @Test
    public void comparesUnroundedRateAndAppliesCustomThresholds() throws Exception {
        sale(1, 5001, today);
        returned(1, 1000, today);
        ReturnWarningCriteria custom = new ReturnWarningCriteria(1, 1001, new BigDecimal("20"), today);
        assertEquals(0, mapper.countWarnings(custom));
        custom = new ReturnWarningCriteria(1, 1001, new BigDecimal("19.99"), today);
        assertEquals(1, mapper.countWarnings(custom));
    }

    @Test
    public void paginatesAndClampsOutOfRangePagesWithoutLeakingPageState() throws Exception {
        for (int id = 1; id <= 12; id++) {
            returned(id, 10, today);
        }
        ReturnWarningService service = new ReturnWarningService(mapper);
        PageInfo<ReturnWarning> firstPage = service.getWarnings(criteria, 1);
        assertEquals(12, firstPage.getTotal());
        assertEquals(10, firstPage.getList().size());
        assertEquals("1", firstPage.getList().get(0).getProid());
        PageInfo<ReturnWarning> lastPage = service.getWarnings(criteria, 999);
        assertEquals(2, lastPage.getPageNum());
        assertEquals(2, lastPage.getList().size());
        assertEquals("11", lastPage.getList().get(0).getProid());
        assertNull(PageHelper.getLocalPage());
        assertEquals(12, mapper.selectWarnings(criteria).size());
    }

    @Test
    public void returnsEmptyResultsWhenThereAreNoDatedReturns() {
        assertTrue(mapper.selectWarnings(criteria).isEmpty());
        assertEquals(0, mapper.countWarnings(criteria));
    }

    private void sale(int id, int quantity, LocalDate date) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("INSERT INTO sale VALUES (?, ?, ?)")) {
            statement.setInt(1, id);
            statement.setInt(2, quantity);
            statement.setDate(3, date == null ? null : Date.valueOf(date));
            statement.executeUpdate();
        }
    }

    private void returned(int id, int quantity, LocalDate date) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("INSERT INTO cusretire VALUES (?, ?, ?, ?)")) {
            statement.setInt(1, id);
            statement.setString(2, "product-" + id);
            statement.setInt(3, quantity);
            statement.setDate(4, date == null ? null : Date.valueOf(date));
            statement.executeUpdate();
        }
    }

    private void assertRate(String expected, ReturnWarning warning) {
        assertEquals(0, new BigDecimal(expected).compareTo(warning.getReturnRate()));
    }
}
