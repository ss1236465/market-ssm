package com.hbh.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.hbh.dao.ReturnWarningMapper;
import com.hbh.entity.ReturnWarning;
import com.hbh.entity.ReturnWarningCriteria;

@Service
public class ReturnWarningService {
    private final ReturnWarningMapper returnWarningMapper;

    @Autowired
    public ReturnWarningService(ReturnWarningMapper returnWarningMapper) {
        this.returnWarningMapper = returnWarningMapper;
    }

    public PageInfo<ReturnWarning> getWarnings(ReturnWarningCriteria criteria, int pageNumber) {
        PageHelper.startPage(pageNumber, 10).setReasonable(true);
        try {
            return new PageInfo<ReturnWarning>(returnWarningMapper.selectWarnings(criteria));
        } finally {
            PageHelper.clearPage();
        }
    }

    public long getDefaultWarningCount() {
        return returnWarningMapper.countWarnings(ReturnWarningCriteria.defaults());
    }
}
