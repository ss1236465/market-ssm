package com.hbh.entity;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.ZoneId;

/** Request-scoped thresholds; both ends of the reporting period are inclusive. */
public class ReturnWarningCriteria {
    public static final int DEFAULT_DAYS = 30;
    public static final int DEFAULT_QUANTITY = 10;
    public static final BigDecimal DEFAULT_RATE = new BigDecimal("20");

    private final int days;
    private final int quantityThreshold;
    private final BigDecimal rateThreshold;
    private final Date startDate;
    private final Date endDate;

    public ReturnWarningCriteria(int days, int quantityThreshold, BigDecimal rateThreshold,
            LocalDate today) {
        if (days < 1 || days > 365) {
            throw new IllegalArgumentException("统计天数应为 1 到 365 的整数");
        }
        if (quantityThreshold < 1) {
            throw new IllegalArgumentException("退货数量阈值应为正整数");
        }
        if (rateThreshold == null || rateThreshold.compareTo(BigDecimal.ZERO) <= 0
                || rateThreshold.compareTo(new BigDecimal("100")) > 0
                || rateThreshold.stripTrailingZeros().scale() > 2) {
            throw new IllegalArgumentException("退货率阈值应大于 0 且不超过 100，最多两位小数");
        }
        this.days = days;
        this.quantityThreshold = quantityThreshold;
        this.rateThreshold = rateThreshold;
        this.startDate = Date.valueOf(today.minusDays(days - 1L));
        this.endDate = Date.valueOf(today);
    }

    public static ReturnWarningCriteria defaults() {
        return new ReturnWarningCriteria(DEFAULT_DAYS, DEFAULT_QUANTITY, DEFAULT_RATE, today());
    }

    public static LocalDate today() {
        return LocalDate.now(ZoneId.of("Asia/Shanghai"));
    }

    public int getDays() { return days; }
    public int getQuantityThreshold() { return quantityThreshold; }
    public BigDecimal getRateThreshold() { return rateThreshold; }
    public Date getStartDate() { return startDate; }
    public Date getEndDate() { return endDate; }
}
