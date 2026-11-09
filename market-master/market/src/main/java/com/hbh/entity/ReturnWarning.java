package com.hbh.entity;

import java.math.BigDecimal;
import java.util.Date;

/** A product whose customer returns exceeded one or both warning thresholds. */
public class ReturnWarning {
    private String proid;
    private String pname;
    private long saleQuantity;
    private long returnQuantity;
    private BigDecimal returnRate;
    private Date lastReturnDate;
    private boolean quantityWarning;
    private boolean rateWarning;

    public String getProid() { return proid; }
    public void setProid(String proid) { this.proid = proid; }
    public String getPname() { return pname; }
    public void setPname(String pname) { this.pname = pname; }
    public long getSaleQuantity() { return saleQuantity; }
    public void setSaleQuantity(long saleQuantity) { this.saleQuantity = saleQuantity; }
    public long getReturnQuantity() { return returnQuantity; }
    public void setReturnQuantity(long returnQuantity) { this.returnQuantity = returnQuantity; }
    public BigDecimal getReturnRate() { return returnRate; }
    public void setReturnRate(BigDecimal returnRate) { this.returnRate = returnRate; }
    public Date getLastReturnDate() { return lastReturnDate; }
    public void setLastReturnDate(Date lastReturnDate) { this.lastReturnDate = lastReturnDate; }
    public boolean isQuantityWarning() { return quantityWarning; }
    public void setQuantityWarning(boolean quantityWarning) { this.quantityWarning = quantityWarning; }
    public boolean isRateWarning() { return rateWarning; }
    public void setRateWarning(boolean rateWarning) { this.rateWarning = rateWarning; }
}
