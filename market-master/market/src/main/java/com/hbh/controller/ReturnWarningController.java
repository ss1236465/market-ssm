package com.hbh.controller;

import java.math.BigDecimal;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.ServletRequestBindingException;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.hbh.entity.ReturnWarningCriteria;
import com.hbh.service.ReturnWarningService;
import com.hbh.tools.Constants;

@Controller
public class ReturnWarningController {
    @Autowired
    private ReturnWarningService returnWarningService;

    @RequestMapping(value = {"/staff/flatform/return-warning", "/manager/flatform/return-warning"},
            method = RequestMethod.GET)
    public String warnings(HttpServletRequest request, HttpSession session, Model model,
            @RequestParam(defaultValue = "30") int days,
            @RequestParam(defaultValue = "10") int quantityThreshold,
            @RequestParam(defaultValue = "20") BigDecimal rateThreshold,
            @RequestParam(defaultValue = "1", value = "pn") int pageNumber)
            throws ServletRequestBindingException {
        boolean manager = request.getServletPath().startsWith("/manager/");
        String role = manager ? "manager" : "staff";
        if (session.getAttribute(manager ? Constants.Manager_SESSION : Constants.Staff_SESSION) == null) {
            return "redirect:/" + role + "/login";
        }

        ReturnWarningCriteria criteria;
        try {
            criteria = new ReturnWarningCriteria(days, quantityThreshold, rateThreshold,
                    ReturnWarningCriteria.today());
            if (pageNumber < 1) {
                throw new IllegalArgumentException("页码应为正整数");
            }
        } catch (IllegalArgumentException ex) {
            throw new ServletRequestBindingException(ex.getMessage());
        }
        model.addAttribute("criteria", criteria);
        model.addAttribute("pageInfo", returnWarningService.getWarnings(criteria, pageNumber));
        model.addAttribute("rolePath", "/" + role + "/flatform");
        return manager ? "manager/return_warning" : "return_warning";
    }
}
