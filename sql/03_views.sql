USE p2p_portfolio_demo;
-- 仅首次创建。以下视图按当前全部记录汇总；历史账龄另由05独立计算。
CREATE VIEW v_payable_balances AS
WITH credits AS (
 SELECT payable_id,SUM(amount) AS credit_amount FROM payable_credits GROUP BY payable_id
), allocated AS (
 SELECT payable_id,SUM(amount) AS allocated_amount FROM payment_allocations GROUP BY payable_id
)
SELECT a.payable_id,a.receipt_id,r.order_id,o.supplier_id,
 a.recognized_date,a.due_date,a.original_amount,
 COALESCE(c.credit_amount,0) AS credit_amount,
 COALESCE(p.allocated_amount,0) AS allocated_amount,
 a.original_amount-COALESCE(c.credit_amount,0)-COALESCE(p.allocated_amount,0) AS outstanding_amount
FROM payables a JOIN goods_receipts r ON r.receipt_id=a.receipt_id
JOIN purchase_orders o ON o.order_id=r.order_id
LEFT JOIN credits c ON c.payable_id=a.payable_id
LEFT JOIN allocated p ON p.payable_id=a.payable_id;

CREATE VIEW v_payment_balances AS
SELECT p.payment_id,p.supplier_id,p.payment_date,p.amount,
 COALESCE(SUM(a.amount),0) AS allocated_amount,
 p.amount-COALESCE(SUM(a.amount),0) AS unallocated_amount
FROM payments p LEFT JOIN payment_allocations a ON a.payment_id=p.payment_id
GROUP BY p.payment_id,p.supplier_id,p.payment_date,p.amount;

CREATE VIEW v_order_summary AS
WITH received AS (
 SELECT order_id,SUM(received_qty) AS received_qty FROM goods_receipts GROUP BY order_id
), returned AS (
 SELECT r.order_id,SUM(t.returned_qty) AS returned_qty FROM purchase_returns t
 JOIN goods_receipts r ON r.receipt_id=t.receipt_id GROUP BY r.order_id
), ap AS (
 SELECT order_id,SUM(original_amount) AS original_amount,SUM(credit_amount) AS credit_amount,
 SUM(allocated_amount) AS allocated_amount,SUM(outstanding_amount) AS outstanding_amount
 FROM v_payable_balances GROUP BY order_id
)
SELECT o.order_id,o.supplier_id,o.item_name,o.unit,o.ordered_qty,o.unit_price,
 o.ordered_qty*o.unit_price AS order_amount,
 COALESCE(r.received_qty,0) AS received_qty,
 COALESCE(t.returned_qty,0) AS returned_qty,
 COALESCE(r.received_qty,0)-COALESCE(t.returned_qty,0) AS net_received_qty,
 o.ordered_qty-COALESCE(r.received_qty,0) AS pending_delivery_qty,
 CASE WHEN COALESCE(r.received_qty,0)=0 THEN '未入库'
      WHEN r.received_qty<o.ordered_qty THEN '部分入库'
      WHEN r.received_qty=o.ordered_qty THEN '全部入库' ELSE '超量入库' END AS receipt_status,
 COALESCE(a.original_amount,0) AS original_amount,
 COALESCE(a.credit_amount,0) AS credit_amount,
 COALESCE(a.allocated_amount,0) AS allocated_amount,
 COALESCE(a.outstanding_amount,0) AS outstanding_amount,
 CASE WHEN a.order_id IS NULL THEN '未确认应付'
      WHEN a.outstanding_amount<0 THEN '应付超核销'
      WHEN a.outstanding_amount=0 THEN '已结清'
      WHEN a.allocated_amount=0 THEN '未付款核销' ELSE '部分付款核销' END AS settlement_status
FROM purchase_orders o LEFT JOIN received r ON r.order_id=o.order_id
LEFT JOIN returned t ON t.order_id=o.order_id LEFT JOIN ap a ON a.order_id=o.order_id;
