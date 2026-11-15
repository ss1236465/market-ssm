<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@include file="common/head.jsp"%>
<style>
  .rw-wrap { padding: 10px 0 30px; }
  .rw-head { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 10px; margin-bottom: 14px; }
  .rw-head h2 { margin: 0; font-size: 22px; color: #2A3F54; }
  .rw-head h2 small { font-size: 13px; color: #8a96a3; margin-left: 8px; }
  .rw-kpis { display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 14px; }
  .rw-kpi { flex: 1 1 180px; background: #fff; border: 1px solid #e6e9ed; border-radius: 4px; padding: 14px 16px; border-left: 4px solid #ccc; }
  .rw-kpi .lbl { color: #73879C; font-size: 13px; }
  .rw-kpi .val { font-size: 30px; font-weight: 600; line-height: 1.2; margin-top: 4px; color: #2A3F54; }
  .rw-kpi .sub { color: #9aa5b1; font-size: 12px; }
  .rw-kpi.high { border-left-color: #d9534f; } .rw-kpi.high .val { color: #d9534f; }
  .rw-kpi.medium { border-left-color: #f0ad4e; } .rw-kpi.medium .val { color: #e08e0b; }
  .rw-kpi.ok { border-left-color: #26B99A; }
  .rw-kpi.info { border-left-color: #3498DB; }
  .rw-settings { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 14px; }
  .rw-settings .form-group { margin: 0; }
  .rw-settings label { display: block; font-weight: normal; color: #73879C; font-size: 12px; margin-bottom: 3px; }
  .rw-settings .input-group { width: 120px; }
  .rw-badge { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 12px; color: #fff; white-space: nowrap; }
  .rw-badge.high { background: #d9534f; } .rw-badge.medium { background: #f0ad4e; }
  .rw-badge.ok { background: #26B99A; } .rw-badge.info { background: #3498DB; } .rw-badge.none { background: #b0b8c1; }
  .rw-bar { position: relative; height: 8px; background: #edf0f3; border-radius: 4px; min-width: 90px; margin-top: 4px; }
  .rw-bar > span { position: absolute; left: 0; top: 0; bottom: 0; border-radius: 4px; }
  .rw-table td, .rw-table th { vertical-align: middle !important; }
  .rw-table th { white-space: nowrap; }
  .rw-table tr.lv-high { background: #fdf3f2; }
  .rw-table tr.lv-medium { background: #fef9ef; }
  .rw-reasons { color: #73879C; font-size: 12px; }
  .rw-empty { text-align: center; color: #9aa5b1; padding: 24px 0 !important; }
  #rwChart { width: 100%; height: 320px; }
  .rw-filter .btn.active { box-shadow: none; }
  .rw-table-wrap { overflow-x: auto; }
</style>

<div class="right_col" role="main">
<div class="clearfix"></div>
<div class="col-md-12 col-sm-12 col-xs-12 rw-wrap">

  <div class="rw-head">
    <h2><i class="fa fa-exclamation-triangle" style="color:#d9534f"></i> 退货的预警 <small id="rwUpdated">正在加载…</small></h2>
    <button type="button" class="btn btn-default btn-sm" id="rwRefresh"><i class="fa fa-refresh"></i> 刷新数据</button>
  </div>

  <div class="alert alert-danger" id="rwError" style="display:none"></div>

  <!-- 指标卡 -->
  <div class="rw-kpis">
    <div class="rw-kpi high"><div class="lbl">高危商品</div><div class="val" id="kHigh">-</div><div class="sub">退货率达到高危阈值</div></div>
    <div class="rw-kpi medium"><div class="lbl">需关注商品</div><div class="val" id="kMedium">-</div><div class="sub">退货率或退供比例偏高</div></div>
    <div class="rw-kpi info"><div class="lbl">整体顾客退货率</div><div class="val" id="kRate">-</div><div class="sub" id="kRateSub">&nbsp;</div></div>
    <div class="rw-kpi ok"><div class="lbl">异常退货单</div><div class="val" id="kAnom">-</div><div class="sub">高危 / 中等异常，不含提示</div></div>
  </div>

  <!-- 阈值设置 -->
  <div class="x_panel">
    <div class="x_title"><h2>预警阈值 <small>修改后立即生效，并保存在本浏览器</small></h2><div class="clearfix"></div></div>
    <div class="x_content">
      <form class="rw-settings" onsubmit="return false;">
        <div class="form-group">
          <label for="tHigh">顾客退货率 · 高危 ≥</label>
          <div class="input-group input-group-sm"><input type="number" min="0" max="100" step="1" class="form-control" id="tHigh"><span class="input-group-addon">%</span></div>
        </div>
        <div class="form-group">
          <label for="tMid">顾客退货率 · 关注 ≥</label>
          <div class="input-group input-group-sm"><input type="number" min="0" max="100" step="1" class="form-control" id="tMid"><span class="input-group-addon">%</span></div>
        </div>
        <div class="form-group">
          <label for="tSup">退供应商比例 · 关注 ≥</label>
          <div class="input-group input-group-sm"><input type="number" min="0" max="100" step="1" class="form-control" id="tSup"><span class="input-group-addon">%</span></div>
        </div>
        <div class="form-group">
          <label for="tCnt">退货单数 · 关注 ≥</label>
          <div class="input-group input-group-sm"><input type="number" min="1" step="1" class="form-control" id="tCnt"><span class="input-group-addon">单</span></div>
        </div>
        <div class="form-group">
          <button type="button" class="btn btn-link btn-sm" id="rwReset">恢复默认</button>
        </div>
      </form>
    </div>
  </div>

  <!-- 图表 -->
  <div class="x_panel">
    <div class="x_title"><h2>各商品顾客退货率 <small>虚线为关注 / 高危阈值</small></h2><div class="clearfix"></div></div>
    <div class="x_content"><div id="rwChart"></div></div>
  </div>

  <!-- 商品预警列表 -->
  <div class="x_panel">
    <div class="x_title">
      <h2>商品退货的预警 <small id="rwProdCount"></small></h2>
      <div class="pull-right">
        <label style="font-weight:normal;margin:0"><input type="checkbox" id="rwOnlyWarn"> 只看预警商品</label>
      </div>
      <div class="clearfix"></div>
    </div>
    <div class="x_content rw-table-wrap">
      <table class="table table-bordered table-hover rw-table">
        <thead>
          <tr>
            <th>预警等级</th><th>商品id</th><th>名称</th><th>供应商</th>
            <th>销售数量</th><th>顾客退货</th><th style="min-width:130px">顾客退货率</th>
            <th>进货数量</th><th>退供应商</th><th style="min-width:130px">退供比例</th>
            <th>最近退货</th><th>预警原因</th><th>操作</th>
          </tr>
        </thead>
        <tbody id="rwProdBody"><tr><td colspan="13" class="rw-empty">正在加载…</td></tr></tbody>
      </table>
    </div>
  </div>

  <!-- 异常退货单 -->
  <div class="x_panel">
    <div class="x_title">
      <h2>异常退货单 <small id="rwAnomCount"></small></h2>
      <div class="pull-right btn-group btn-group-xs rw-filter" id="rwAnomFilter">
        <button type="button" class="btn btn-default active" data-lv="all">全部</button>
        <button type="button" class="btn btn-default" data-lv="high">高危</button>
        <button type="button" class="btn btn-default" data-lv="medium">中等</button>
        <button type="button" class="btn btn-default" data-lv="info">提示</button>
      </div>
      <div class="clearfix"></div>
    </div>
    <div class="x_content rw-table-wrap">
      <table class="table table-bordered table-hover rw-table">
        <thead>
          <tr><th>等级</th><th>类型</th><th>单号</th><th>商品id</th><th>名称</th><th>退货数量</th><th>原单数量</th><th>退货日期</th><th>问题</th><th>操作</th></tr>
        </thead>
        <tbody id="rwAnomBody"><tr><td colspan="10" class="rw-empty">正在加载…</td></tr></tbody>
      </table>
    </div>
  </div>

</div>
<div class="clearfix"></div>
</div>

<%@include file="common/footer.jsp"%>
<script src="${pageContext.request.contextPath }/statics/js/echarts.min.js"></script>
<script type="text/javascript">
(function () {
  var CTX = '${pageContext.request.contextPath}';
  var DEFAULTS = { high: 20, mid: 8, sup: 20, cnt: 3 };
  var STORE_KEY = 'market.retirewarn.thresholds';
  var LV_TEXT = { high: '高危', medium: '关注', ok: '正常', none: '无数据', info: '提示' };
  var LV_ORDER = { high: 0, medium: 1, ok: 2, none: 3 };
  var COLORS = { high: '#d9534f', medium: '#f0ad4e', ok: '#26B99A', none: '#b0b8c1' };
  var raw = null, chart = null, anomFilter = 'all';

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function pct(v) { return v == null ? '—' : (v * 100).toFixed(1) + '%'; }
  function badge(lv, text) { return '<span class="rw-badge ' + lv + '">' + esc(text || LV_TEXT[lv]) + '</span>'; }
  function bar(v, lv) {
    if (v == null) return '<span class="text-muted">—</span>';
    var w = Math.min(100, v * 100);
    return pct(v) + '<div class="rw-bar"><span style="width:' + w + '%;background:' + COLORS[lv] + '"></span></div>';
  }

  // ---- 阈值 ----
  function loadThresholds() {
    var t = {};
    try { t = JSON.parse(localStorage.getItem(STORE_KEY)) || {}; } catch (e) { t = {}; }
    return {
      high: isFinite(t.high) ? t.high : DEFAULTS.high,
      mid: isFinite(t.mid) ? t.mid : DEFAULTS.mid,
      sup: isFinite(t.sup) ? t.sup : DEFAULTS.sup,
      cnt: isFinite(t.cnt) ? t.cnt : DEFAULTS.cnt
    };
  }
  function readThresholds() {
    function v(id, d) { var n = parseFloat($(id).val()); return isFinite(n) && n >= 0 ? n : d; }
    var t = { high: v('#tHigh', DEFAULTS.high), mid: v('#tMid', DEFAULTS.mid), sup: v('#tSup', DEFAULTS.sup), cnt: v('#tCnt', DEFAULTS.cnt) };
    if (t.mid > t.high) t.mid = t.high;
    try { localStorage.setItem(STORE_KEY, JSON.stringify(t)); } catch (e) {}
    return t;
  }
  function fillThresholds(t) { $('#tHigh').val(t.high); $('#tMid').val(t.mid); $('#tSup').val(t.sup); $('#tCnt').val(t.cnt); }

  // ---- 计算每个商品的预警等级 ----
  function evaluate(p, t) {
    var r = $.extend({}, p);
    r.cusRate = p.soldQty > 0 ? p.cusRetQty / p.soldQty : null;
    r.supRate = p.inQty > 0 ? p.supRetQty / p.inQty : null;
    var reasons = [], lv = 'ok';
    function raise(to) { if (LV_ORDER[to] < LV_ORDER[lv]) lv = to; }

    if (p.soldQty === 0 && p.cusRetQty > 0) { raise('high'); reasons.push('无销售记录却有顾客退货'); }
    if (r.cusRate != null && r.cusRate * 100 >= t.high) { raise('high'); reasons.push('顾客退货率 ' + pct(r.cusRate) + ' ≥ ' + t.high + '%'); }
    else if (r.cusRate != null && p.cusRetQty > 0 && r.cusRate * 100 >= t.mid) { raise('medium'); reasons.push('顾客退货率 ' + pct(r.cusRate) + ' ≥ ' + t.mid + '%'); }
    if (r.supRate != null && p.supRetQty > 0 && r.supRate * 100 >= t.sup) { raise('medium'); reasons.push('退供比例 ' + pct(r.supRate) + ' ≥ ' + t.sup + '%'); }
    if (p.inQty === 0 && p.supRetQty > 0) { raise('medium'); reasons.push('无进货记录却有退供'); }
    var cnt = p.cusRetCount + p.supRetCount;
    if (cnt >= t.cnt) { raise('medium'); reasons.push('累计退货 ' + cnt + ' 单'); }
    if (lv === 'ok' && p.soldQty === 0 && p.inQty === 0 && cnt === 0) lv = 'none';

    r.level = lv;
    r.reasons = reasons;
    return r;
  }

  // ---- 渲染 ----
  function render() {
    if (!raw) return;
    var t = readThresholds();
    var rows = $.map(raw.products, function (p) { return evaluate(p, t); });
    rows.sort(function (a, b) {
      return (LV_ORDER[a.level] - LV_ORDER[b.level]) || ((b.cusRate || 0) - (a.cusRate || 0)) || ((b.supRate || 0) - (a.supRate || 0));
    });

    var nHigh = 0, nMid = 0, sold = 0, ret = 0;
    $.each(rows, function (_, r) {
      if (r.level === 'high') nHigh++; else if (r.level === 'medium') nMid++;
      sold += r.soldQty; ret += r.cusRetQty;
    });
    var anomSerious = $.grep(raw.anomalies, function (a) { return a.level !== 'info'; }).length;
    $('#kHigh').text(nHigh);
    $('#kMedium').text(nMid);
    $('#kRate').text(sold > 0 ? pct(ret / sold) : '—');
    $('#kRateSub').text('退货 ' + ret + ' / 销售 ' + sold);
    $('#kAnom').text(anomSerious);
    $('#kAnom').closest('.rw-kpi').toggleClass('ok', anomSerious === 0).toggleClass('high', anomSerious > 0);

    renderProducts(rows);
    renderChart(rows, t);
    renderAnomalies();
  }

  function renderProducts(rows) {
    var only = $('#rwOnlyWarn').prop('checked');
    var shown = only ? $.grep(rows, function (r) { return r.level === 'high' || r.level === 'medium'; }) : rows;
    $('#rwProdCount').text('共 ' + rows.length + ' 个商品，显示 ' + shown.length + ' 个');
    if (!shown.length) {
      $('#rwProdBody').html('<tr><td colspan="13" class="rw-empty">' + (only ? '当前阈值下没有预警商品' : '暂无商品数据') + '</td></tr>');
      return;
    }
    var html = $.map(shown, function (r) {
      var cusLv = r.cusRate == null ? 'none' : (r.reasons.join().indexOf('顾客退货率') >= 0 ? r.level : 'ok');
      var supLv = r.supRate == null ? 'none' : (r.reasons.join().indexOf('退供比例') >= 0 ? 'medium' : 'ok');
      var pid = encodeURIComponent(r.proid);
      return '<tr class="lv-' + r.level + '">' +
        '<td>' + badge(r.level) + '</td>' +
        '<td>' + esc(r.proid) + '</td>' +
        '<td><strong>' + esc(r.pname) + '</strong>' + (r.protype ? '<br><small class="text-muted">' + esc(r.protype) + '</small>' : '') + '</td>' +
        '<td>' + esc(r.supname || '—') + '</td>' +
        '<td>' + r.soldQty + '</td>' +
        '<td>' + r.cusRetQty + ' <small class="text-muted">(' + r.cusRetCount + '单)</small></td>' +
        '<td>' + bar(r.cusRate, cusLv) + '</td>' +
        '<td>' + r.inQty + '</td>' +
        '<td>' + r.supRetQty + ' <small class="text-muted">(' + r.supRetCount + '单)</small></td>' +
        '<td>' + bar(r.supRate, supLv) + '</td>' +
        '<td>' + esc(r.lastRetDate || '—') + '</td>' +
        '<td class="rw-reasons">' + (r.reasons.length ? esc(r.reasons.join('；')) : '—') + '</td>' +
        '<td style="white-space:nowrap">' +
          '<a class="btn btn-xs btn-default" href="' + CTX + '/manager/flatform/cusretire/getbyparams?proid=' + pid + '">顾客退货</a> ' +
          '<a class="btn btn-xs btn-default" href="' + CTX + '/manager/flatform/ckretire/getbyparams?proid=' + pid + '">退供记录</a>' +
        '</td></tr>';
    }).join('');
    $('#rwProdBody').html(html);
  }

  function renderChart(rows, t) {
    var data = $.grep(rows, function (r) { return r.cusRate != null || r.cusRetQty > 0; });
    data = data.slice().sort(function (a, b) { return (a.cusRate || 0) - (b.cusRate || 0); });
    $('#rwChart').css('height', Math.max(220, data.length * 46 + 40) + 'px');
    if (!chart) chart = echarts.init(document.getElementById('rwChart'));
    else chart.resize();
    var maxRate = 0;
    $.each(data, function (_, r) { maxRate = Math.max(maxRate, (r.cusRate || 0) * 100); });
    chart.setOption({
      grid: { left: 10, right: 50, top: 20, bottom: 10, containLabel: true },
      tooltip: {
        trigger: 'axis', axisPointer: { type: 'shadow' },
        formatter: function (ps) {
          var r = data[ps[0].dataIndex];
          return esc(r.pname) + '<br>顾客退货率：' + pct(r.cusRate) + '<br>退货 ' + r.cusRetQty + ' / 销售 ' + r.soldQty + '<br>等级：' + LV_TEXT[r.level];
        }
      },
      xAxis: { type: 'value', max: Math.ceil(Math.max(maxRate, t.high) * 1.15), axisLabel: { formatter: '{value}%' }, splitLine: { lineStyle: { color: '#eef1f4' } } },
      yAxis: { type: 'category', data: $.map(data, function (r) { return String(r.pname || r.proid); }), axisTick: { show: false } },
      series: [{
        type: 'bar', barMaxWidth: 26,
        data: $.map(data, function (r) {
          return { value: r.cusRate == null ? 0 : +(r.cusRate * 100).toFixed(2), itemStyle: { color: COLORS[r.level] } };
        }),
        label: { show: true, position: 'right', formatter: function (p) { return p.value.toFixed(1) + '%'; }, color: '#5a6b7b' },
        markLine: {
          silent: true, symbol: 'none', label: { formatter: '{b} {c}%' },
          data: [
            { name: '关注', xAxis: t.mid, lineStyle: { color: COLORS.medium, type: 'dashed' } },
            { name: '高危', xAxis: t.high, lineStyle: { color: COLORS.high, type: 'dashed' } }
          ]
        }
      }]
    }, true);
  }

  function renderAnomalies() {
    var list = raw.anomalies;
    var shown = anomFilter === 'all' ? list : $.grep(list, function (a) { return a.level === anomFilter; });
    var order = { high: 0, medium: 1, info: 2 };
    shown = shown.slice().sort(function (a, b) { return order[a.level] - order[b.level]; });
    var counts = { high: 0, medium: 0, info: 0 };
    $.each(list, function (_, a) { counts[a.level]++; });
    $('#rwAnomCount').text('高危 ' + counts.high + ' · 中等 ' + counts.medium + ' · 提示 ' + counts.info);
    if (!shown.length) {
      $('#rwAnomBody').html('<tr><td colspan="10" class="rw-empty">没有符合条件的异常退货单</td></tr>');
      return;
    }
    var lvText = { high: '高危', medium: '中等', info: '提示' };
    var html = $.map(shown, function (a) {
      var isCus = a.kind === '顾客退货';
      var link = isCus
        ? CTX + '/manager/flatform/cusretire/edit?saleid=' + encodeURIComponent(a.orderId)
        : CTX + '/manager/flatform/ckretire/edit?inid=' + encodeURIComponent(a.orderId);
      return '<tr class="lv-' + (a.level === 'info' ? '' : a.level) + '">' +
        '<td>' + badge(a.level, lvText[a.level]) + '</td>' +
        '<td>' + esc(a.kind) + '</td>' +
        '<td>' + esc(a.orderId) + '</td>' +
        '<td>' + esc(a.proid) + '</td>' +
        '<td>' + esc(a.pname) + '</td>' +
        '<td>' + a.retQty + '</td>' +
        '<td>' + (a.baseQty == null ? '—' : a.baseQty) + '</td>' +
        '<td>' + esc(a.retdate || '—') + '</td>' +
        '<td>' + esc(a.message) + '</td>' +
        '<td><a class="btn btn-xs btn-primary" href="' + link + '">处理</a></td></tr>';
    }).join('');
    $('#rwAnomBody').html(html);
  }

  // ---- 数据加载 ----
  function load() {
    $('#rwRefresh').prop('disabled', true);
    $.ajax({
      url: CTX + '/manager/flatform/retirewarn/data',
      method: 'post',
      dataType: 'json',
      cache: false
    }).done(function (data) {
      raw = data;
      $('#rwError').hide();
      $('#rwUpdated').text('数据更新于 ' + data.generatedAt);
      render();
    }).fail(function (xhr) {
      $('#rwError').text('加载退货数据失败（HTTP ' + xhr.status + '），请稍后刷新重试。').show();
      $('#rwUpdated').text('');
    }).always(function () {
      $('#rwRefresh').prop('disabled', false);
    });
  }

  fillThresholds(loadThresholds());
  $('#tHigh, #tMid, #tSup, #tCnt').on('input change', render);
  $('#rwReset').on('click', function () { fillThresholds(DEFAULTS); render(); });
  $('#rwOnlyWarn').on('change', render);
  $('#rwRefresh').on('click', load);
  $('#rwAnomFilter').on('click', 'button', function () {
    $(this).addClass('active').siblings().removeClass('active');
    anomFilter = $(this).data('lv');
    if (raw) renderAnomalies();
  });
  $(window).on('resize', function () { if (chart) chart.resize(); });
  load();
})();
</script>
