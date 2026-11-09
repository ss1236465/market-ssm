<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@include file="common/head.jsp"%>
        <div class="right_col" role="main"> 
        	<h3>欢迎：${staffSession.stafftype }<strong>${staffSession.staffname }</strong>登录</h3>
        <%@include file="common/return_warning_notice.jsp"%>
        
	<div class="clearfix"></div>
</div>
<%@include file="common/footer.jsp"%>
