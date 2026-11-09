package com.hbh.entity;

import static org.junit.Assert.*;

import java.math.BigDecimal;
import java.time.LocalDate;

import org.junit.Test;

public class ReturnWarningCriteriaTest {
    private final LocalDate today = LocalDate.of(2026, 11, 10);

    @Test
    public void reportingPeriodIncludesTodayAndCrossesYearBoundary() {
        ReturnWarningCriteria criteria = new ReturnWarningCriteria(30, 10,
                new BigDecimal("20"), LocalDate.of(2026, 1, 10));
        assertEquals("2025-12-12", criteria.getStartDate().toString());
        assertEquals("2026-01-10", criteria.getEndDate().toString());
        ReturnWarningCriteria oneDay = new ReturnWarningCriteria(1, 1,
                new BigDecimal("0.01"), today);
        assertEquals(oneDay.getStartDate(), oneDay.getEndDate());
    }

    @Test
    public void defaultsUseExpectedThresholds() {
        ReturnWarningCriteria criteria = ReturnWarningCriteria.defaults();
        assertEquals(30, criteria.getDays());
        assertEquals(10, criteria.getQuantityThreshold());
        assertEquals(0, new BigDecimal("20").compareTo(criteria.getRateThreshold()));
        assertEquals(ReturnWarningCriteria.today().toString(), criteria.getEndDate().toString());
    }

    @Test
    public void invalidThresholdsAreRejected() {
        assertInvalid(0, 10, "20");
        assertInvalid(366, 10, "20");
        assertInvalid(30, 0, "20");
        assertInvalid(30, 10, "0");
        assertInvalid(30, 10, "100.01");
        assertInvalid(30, 10, "0.001");
        assertInvalid(30, 10, null);
        new ReturnWarningCriteria(365, Integer.MAX_VALUE, new BigDecimal("100.00"), today);
    }

    private void assertInvalid(int days, int quantity, String rate) {
        try {
            new ReturnWarningCriteria(days, quantity, rate == null ? null : new BigDecimal(rate), today);
            fail("Expected invalid criteria to be rejected");
        } catch (IllegalArgumentException expected) {
            assertNotNull(expected.getMessage());
        }
    }
}
