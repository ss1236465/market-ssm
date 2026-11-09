<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<c:url var="warningUrl" value="${rolePath}/return-warning" />
<div class="right_col" role="main">
  <div class="page-title"><div class="title_left"><h3>退货预警</h3></div></div>
  <div class="clearfix"></div>
  <div class="x_panel">
    <div class="x_title">
      <h2>顾客退货异常监测</h2>
      <div class="clearfix"></div>
    </div>
    <div class="x_content">
      <form class="form-inline" action="${warningUrl}" method="get" style="margin-bottom: 20px;">
        <div class="form-group" style="margin: 0 15px 10px 0;">
          <label for="warning-days">统计天数</label>
          <input id="warning-days" name="days" type="number" min="1" max="365" required
                 class="form-control" style="width: 90px;" value="${criteria.days}">
        </div>
        <div class="form-group" style="margin: 0 15px 10px 0;">
          <label for="warning-quantity">退货数量阈值</label>
          <input id="warning-quantity" name="quantityThreshold" type="number" min="1" max="2147483647" required
                 class="form-control" style="width: 110px;" value="${criteria.quantityThreshold}">
        </div>
        <div class="form-group" style="margin: 0 15px 10px 0;">
          <label for="warning-rate">退货率阈值（%）</label>
          <input id="warning-rate" name="rateThreshold" type="number" min="0.01" max="100" step="0.01" required
                 class="form-control" style="width: 90px;" value="${criteria.rateThreshold}">
        </div>
        <button type="submit" class="btn btn-primary">查询预警</button>
        <a href="${warningUrl}" class="btn btn-default">恢复默认</a>
      </form>

      <div class="alert alert-info" role="status">
        统计期间：<fmt:formatDate value="${criteria.startDate}" pattern="yyyy-MM-dd" />
        至 <fmt:formatDate value="${criteria.endDate}" pattern="yyyy-MM-dd" />（含首尾日期），
        共 <strong>${pageInfo.total}</strong> 种商品触发预警。
        退货数量 ≥ ${criteria.quantityThreshold} 或退货率 ≥ ${criteria.rateThreshold}% 即触发。
      </div>

      <div class="table-responsive">
        <table class="table table-striped table-bordered table-hover">
          <thead><tr>
            <th>商品 ID</th><th>商品名称</th><th>同期销量</th><th>退货数量</th>
            <th>退货率</th><th>最近退货日期</th><th>预警原因</th><th>操作</th>
          </tr></thead>
          <tbody>
            <c:forEach items="${pageInfo.list}" var="warning">
              <tr>
                <td><c:out value="${warning.proid}" /></td>
                <td><c:out value="${warning.pname}" /></td>
                <td>${warning.saleQuantity}</td>
                <td>${warning.returnQuantity}</td>
                <td>
                  <c:choose>
                    <c:when test="${warning.returnRate != null}"><fmt:formatNumber value="${warning.returnRate}" minFractionDigits="2" maxFractionDigits="2" />%</c:when>
                    <c:otherwise><span class="text-muted">无法计算（无同期销量）</span></c:otherwise>
                  </c:choose>
                </td>
                <td><fmt:formatDate value="${warning.lastReturnDate}" pattern="yyyy-MM-dd" /></td>
                <td>
                  <c:if test="${warning.quantityWarning}"><span class="label label-warning">退货数量过高</span> </c:if>
                  <c:if test="${warning.rateWarning}"><span class="label label-danger">退货率过高</span></c:if>
                </td>
                <td>
                  <c:url var="returnDetailUrl" value="${rolePath}/cusretire/getbyparams"><c:param name="proid" value="${warning.proid}" /></c:url>
                  <a class="btn btn-default btn-xs" href="${returnDetailUrl}">查看退货记录</a>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty pageInfo.list}">
              <tr><td colspan="8" class="text-center" style="padding: 35px;">当前条件下暂无退货预警。</td></tr>
            </c:if>
          </tbody>
        </table>
      </div>
      <p class="text-muted">
        退货率 = 统计期内退货数量 ÷ 同期销售数量 × 100%。销售和退货分别按销售日期、退货日期统计；
        跨期退货可能使退货率超过 100%。未填写日期的记录及非正数量不计入统计。
        查询条件仅对本次查询生效，首页按默认规则统计。
      </p>
      <c:if test="${pageInfo.pages > 1}">
        <nav aria-label="退货预警分页">
          <ul class="pagination">
            <c:if test="${pageInfo.hasPreviousPage}">
              <c:url var="previousUrl" value="${rolePath}/return-warning">
                <c:param name="days" value="${criteria.days}" /><c:param name="quantityThreshold" value="${criteria.quantityThreshold}" />
                <c:param name="rateThreshold" value="${criteria.rateThreshold}" /><c:param name="pn" value="${pageInfo.prePage}" />
              </c:url>
              <li><a href="${previousUrl}">上一页</a></li>
            </c:if>
            <c:forEach items="${pageInfo.navigatepageNums}" var="number">
              <c:url var="pageUrl" value="${rolePath}/return-warning">
                <c:param name="days" value="${criteria.days}" /><c:param name="quantityThreshold" value="${criteria.quantityThreshold}" />
                <c:param name="rateThreshold" value="${criteria.rateThreshold}" /><c:param name="pn" value="${number}" />
              </c:url>
              <li class="${number == pageInfo.pageNum ? 'active' : ''}"><a href="${pageUrl}">${number}</a></li>
            </c:forEach>
            <c:if test="${pageInfo.hasNextPage}">
              <c:url var="nextUrl" value="${rolePath}/return-warning">
                <c:param name="days" value="${criteria.days}" /><c:param name="quantityThreshold" value="${criteria.quantityThreshold}" />
                <c:param name="rateThreshold" value="${criteria.rateThreshold}" /><c:param name="pn" value="${pageInfo.nextPage}" />
              </c:url>
              <li><a href="${nextUrl}">下一页</a></li>
            </c:if>
          </ul>
          <p>当前第 ${pageInfo.pageNum} 页，共 ${pageInfo.pages} 页</p>
        </nav>
      </c:if>
    </div>
  </div>
  <div class="clearfix"></div>
</div>
