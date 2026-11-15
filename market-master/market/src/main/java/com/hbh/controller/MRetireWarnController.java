package com.hbh.controller;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.hbh.entity.Ckin;
import com.hbh.entity.Ckretire;
import com.hbh.entity.CusRetire;
import com.hbh.entity.Product;
import com.hbh.entity.Sale;
import com.hbh.service.imp.CkinServiceImp;
import com.hbh.service.imp.CkretireServiceImp;
import com.hbh.service.imp.CusRetireServiceImp;
import com.hbh.service.imp.ProductServiceImp;
import com.hbh.service.imp.SaleServiceImp;

/**
 * 退货的预警：按商品汇总顾客退货率、退供应商比例，并找出异常退货单。
 * 预警等级阈值由前端页面调整，这里只提供原始统计数据。
 */
@Controller
@RequestMapping("/manager/flatform/retirewarn")
public class MRetireWarnController {

	@Autowired
	SaleServiceImp saleServiceImp;
	@Autowired
	CusRetireServiceImp cusRetireServiceImp;
	@Autowired
	CkinServiceImp ckinServiceImp;
	@Autowired
	CkretireServiceImp ckretireServiceImp;
	@Autowired
	ProductServiceImp productServiceImp;

	@RequestMapping("/index")
	public String index() {
		return "manager/retirewarn";
	}

	@RequestMapping("/data")
	@ResponseBody
	public Map<String, Object> data() {
		List<Sale> sales = saleServiceImp.getall();
		List<CusRetire> cusRetires = cusRetireServiceImp.getall();
		List<Ckin> ckins = ckinServiceImp.getall();
		List<Ckretire> ckretires = ckretireServiceImp.getall();
		List<Product> products = productServiceImp.getlist();

		Map<String, Map<String, Object>> byProduct = new LinkedHashMap<String, Map<String, Object>>();
		for (Product p : products) {
			Map<String, Object> row = productRow(byProduct, p.getProid(), p.getPname());
			row.put("supname", p.getSupname());
			row.put("protype", p.getProtype());
		}

		Map<String, Sale> saleById = new HashMap<String, Sale>();
		for (Sale s : sales) {
			saleById.put(s.getSaleid(), s);
			add(productRow(byProduct, s.getProid(), s.getPname()), "soldQty", num(s.getNum()));
		}
		Map<String, Ckin> ckinById = new HashMap<String, Ckin>();
		for (Ckin c : ckins) {
			ckinById.put(c.getInid(), c);
			add(productRow(byProduct, c.getProid(), c.getPname()), "inQty", num(c.getNum()));
		}

		List<Map<String, Object>> anomalies = new ArrayList<Map<String, Object>>();

		for (CusRetire r : cusRetires) {
			Map<String, Object> row = productRow(byProduct, r.getProid(), r.getPname());
			add(row, "cusRetQty", num(r.getNum()));
			add(row, "cusRetCount", 1);
			latest(row, "lastRetDate", r.getRetdate());

			Sale s = saleById.get(r.getSaleid());
			if (s == null) {
				anomalies.add(anomaly("high", "顾客退货", r.getSaleid(), r.getProid(), r.getPname(),
						num(r.getNum()), null, r.getRetdate(), "原销售订单不存在"));
			} else if (num(r.getNum()) > num(s.getNum())) {
				anomalies.add(anomaly("high", "顾客退货", r.getSaleid(), r.getProid(), r.getPname(),
						num(r.getNum()), num(s.getNum()), r.getRetdate(), "退货数量超过原订单销售数量"));
			} else if (s.getProid() != null && !s.getProid().equals(r.getProid())) {
				anomalies.add(anomaly("medium", "顾客退货", r.getSaleid(), r.getProid(), r.getPname(),
						num(r.getNum()), num(s.getNum()), r.getRetdate(), "退货商品与原订单商品不一致"));
			}
			if (isBlank(r.getReason())) {
				anomalies.add(anomaly("info", "顾客退货", r.getSaleid(), r.getProid(), r.getPname(),
						num(r.getNum()), s == null ? null : num(s.getNum()), r.getRetdate(), "未填写退货原因"));
			}
		}

		for (Ckretire r : ckretires) {
			Map<String, Object> row = productRow(byProduct, r.getProid(), r.getPname());
			add(row, "supRetQty", num(r.getNum()));
			add(row, "supRetCount", 1);
			latest(row, "lastRetDate", r.getRetdate());

			Ckin c = ckinById.get(r.getInid());
			if (c == null) {
				anomalies.add(anomaly("high", "退供应商", r.getInid(), r.getProid(), r.getPname(),
						num(r.getNum()), null, r.getRetdate(), "原进货单不存在"));
			} else if (num(r.getNum()) > num(c.getNum())) {
				anomalies.add(anomaly("high", "退供应商", r.getInid(), r.getProid(), r.getPname(),
						num(r.getNum()), num(c.getNum()), r.getRetdate(), "退货数量超过原进货数量"));
			} else if (num(c.getNum()) > 0 && num(r.getNum()) == num(c.getNum())) {
				anomalies.add(anomaly("medium", "退供应商", r.getInid(), r.getProid(), r.getPname(),
						num(r.getNum()), num(c.getNum()), r.getRetdate(), "整批退回供应商"));
			}
			if (isBlank(r.getReason())) {
				anomalies.add(anomaly("info", "退供应商", r.getInid(), r.getProid(), r.getPname(),
						num(r.getNum()), c == null ? null : num(c.getNum()), r.getRetdate(), "未填写退货原因"));
			}
		}

		SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd");
		List<Map<String, Object>> products2 = new ArrayList<Map<String, Object>>();
		for (Map<String, Object> row : byProduct.values()) {
			Object d = row.get("lastRetDate");
			row.put("lastRetDate", d == null ? "" : fmt.format((Date) d));
			products2.add(row);
		}

		Map<String, Object> result = new LinkedHashMap<String, Object>();
		result.put("products", products2);
		result.put("anomalies", anomalies);
		result.put("generatedAt", new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
		return result;
	}

	private static Map<String, Object> productRow(Map<String, Map<String, Object>> byProduct, String proid, String pname) {
		String key = proid == null ? "" : proid;
		Map<String, Object> row = byProduct.get(key);
		if (row == null) {
			row = new LinkedHashMap<String, Object>();
			row.put("proid", key);
			row.put("pname", pname);
			row.put("supname", "");
			row.put("protype", "");
			row.put("soldQty", 0);
			row.put("cusRetQty", 0);
			row.put("cusRetCount", 0);
			row.put("inQty", 0);
			row.put("supRetQty", 0);
			row.put("supRetCount", 0);
			row.put("lastRetDate", null);
			byProduct.put(key, row);
		} else if (row.get("pname") == null && pname != null) {
			row.put("pname", pname);
		}
		return row;
	}

	private static Map<String, Object> anomaly(String level, String kind, String orderId, String proid, String pname,
			int retQty, Integer baseQty, Date retdate, String message) {
		Map<String, Object> a = new LinkedHashMap<String, Object>();
		a.put("level", level);
		a.put("kind", kind);
		a.put("orderId", orderId);
		a.put("proid", proid);
		a.put("pname", pname);
		a.put("retQty", retQty);
		a.put("baseQty", baseQty);
		a.put("retdate", retdate == null ? "" : new SimpleDateFormat("yyyy-MM-dd").format(retdate));
		a.put("message", message);
		return a;
	}

	private static void add(Map<String, Object> row, String key, int delta) {
		row.put(key, ((Integer) row.get(key)) + delta);
	}

	private static void latest(Map<String, Object> row, String key, Date d) {
		if (d == null) return;
		Date cur = (Date) row.get(key);
		if (cur == null || d.after(cur)) row.put(key, d);
	}

	private static int num(Integer n) {
		return n == null ? 0 : n.intValue();
	}

	private static boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}
}
