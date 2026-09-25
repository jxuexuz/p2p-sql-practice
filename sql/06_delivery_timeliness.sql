USE p2p_portfolio_demo;
SET @as_of_date = DATE('2026-09-25');
-- 指标定义：截止日已到交货期的订单中，约定交货日及之前已足量入库的订单占比。
-- 未到期订单不参与；退货不追溯修改首次交货表现；不把不同单位数量合计。
WITH delivery AS (
 SELECT o.order_id,o.supplier_id,o.promised_date,o.ordered_qty,
 COALESCE(SUM(CASE WHEN r.received_date<=o.promised_date AND r.received_date<=@as_of_date THEN r.received_qty ELSE 0 END),0) AS on_time_qty
 FROM purchase_orders o LEFT JOIN goods_receipts r ON r.order_id=o.order_id
 WHERE o.order_date<=@as_of_date
 GROUP BY o.order_id,o.supplier_id,o.promised_date,o.ordered_qty
)
SELECT s.supplier_id,s.supplier_name,
 SUM(CASE WHEN d.promised_date<=@as_of_date THEN 1 ELSE 0 END) AS due_orders,
 SUM(CASE WHEN d.promised_date<=@as_of_date AND d.on_time_qty>=d.ordered_qty THEN 1 ELSE 0 END) AS on_time_full_orders,
 ROUND(100.0*SUM(CASE WHEN d.promised_date<=@as_of_date AND d.on_time_qty>=d.ordered_qty THEN 1 ELSE 0 END)
 /NULLIF(SUM(CASE WHEN d.promised_date<=@as_of_date THEN 1 ELSE 0 END),0),2) AS on_time_full_rate_pct
FROM suppliers s LEFT JOIN delivery d ON d.supplier_id=s.supplier_id
GROUP BY s.supplier_id,s.supplier_name ORDER BY s.supplier_id;

-- 逐笔到货记录，帮助解释为何订单1首次准时但最终不满足足量准时。
SELECT o.order_id,o.item_name,o.promised_date,r.receipt_id,r.received_date,r.received_qty,
 CASE WHEN r.receipt_id IS NULL THEN '未入库'
 WHEN r.received_date<=o.promised_date THEN '按时入库' ELSE '迟到入库' END AS receipt_timing
FROM purchase_orders o LEFT JOIN goods_receipts r
 ON r.order_id=o.order_id AND r.received_date<=@as_of_date
WHERE o.order_date<=@as_of_date ORDER BY o.order_id,r.receipt_id;
