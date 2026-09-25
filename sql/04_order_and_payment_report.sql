USE p2p_portfolio_demo;
-- 报表一：订单履约与应付余额，预期5行；订单1余额90，订单2余额200。
SELECT o.order_id,s.supplier_name,o.item_name,o.unit,o.ordered_qty,o.order_amount,
 o.received_qty,o.returned_qty,o.net_received_qty,o.pending_delivery_qty,
 o.receipt_status,o.original_amount,o.credit_amount,o.allocated_amount,
 o.outstanding_amount,o.settlement_status
FROM v_order_summary o JOIN suppliers s ON s.supplier_id=o.supplier_id ORDER BY o.order_id;

-- 报表二：付款不是核销，付款5的20元尚未分配，不减少任何应付余额。
SELECT * FROM v_payment_balances ORDER BY payment_id;

-- 报表三：单据追溯。这里是核销明细，不要对重复出现的原应付金额直接求和。
SELECT a.allocation_id,p.payment_id,p.payment_date,a.allocated_date,a.amount AS allocated_amount,
 b.payable_id,b.receipt_id,r.order_id,o.supplier_id
FROM payment_allocations a JOIN payments p ON p.payment_id=a.payment_id
JOIN payables b ON b.payable_id=a.payable_id
JOIN goods_receipts r ON r.receipt_id=b.receipt_id
JOIN purchase_orders o ON o.order_id=r.order_id ORDER BY a.allocation_id;
