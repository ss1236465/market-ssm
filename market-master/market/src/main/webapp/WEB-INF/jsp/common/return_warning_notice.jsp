<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<c:url var="homeWarningUrl" value="${rolePath}/return-warning" />
<div class="alert ${returnWarningCount > 0 ? 'alert-warning' : 'alert-info'}" role="status" style="margin-top: 20px;">
  <strong>退货预警：</strong>
  <c:choose>
    <c:when test="${returnWarningCount > 0}">近 30 天有 ${returnWarningCount} 种商品退货异常，请及时核查。</c:when>
    <c:otherwise>近 30 天暂无商品触发退货预警。</c:otherwise>
  </c:choose>
  <a href="${homeWarningUrl}" class="alert-link">查看退货预警</a>
  <div>默认规则：退货数量达到 10 或退货率达到 20%。</div>
</div>
