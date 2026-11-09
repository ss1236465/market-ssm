package com.hbh.dao;

import java.util.List;

import com.hbh.entity.ReturnWarning;
import com.hbh.entity.ReturnWarningCriteria;

public interface ReturnWarningMapper {
    List<ReturnWarning> selectWarnings(ReturnWarningCriteria criteria);
    long countWarnings(ReturnWarningCriteria criteria);
}
