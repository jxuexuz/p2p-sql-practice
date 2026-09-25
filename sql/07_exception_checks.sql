USE p2p_portfolio_demo;
-- 首次创建视图；以后只重复执行末尾SELECT。均为事后检测，不是写入拦截。
CREATE VIEW v_data_issues AS
SELECT 'OVER_RECEIPT' AS issue_code,order_id AS record_id,'累计入库超过订单数量' AS explanation
FROM v_order_summary WHERE received_qty>ordered_qty
UNION ALL
SELECT 'OVER_RETURN',r.receipt_id,'累计退货超过原入库数量'
FROM goods_receipts r JOIN purchase_returns t ON t.receipt_id=r.receipt_id
GROUP BY r.receipt_id,r.received_qty HAVING SUM(t.returned_qty)>r.received_qty
UNION ALL
SELECT 'OVER_ALLOCATION',payment_id,'累计核销超过付款金额'
FROM v_payment_balances WHERE unallocated_amount<0
UNION ALL
SELECT 'NEGATIVE_AP',payable_id,'应付冲减和核销合计超过原应付'
FROM v_payable_balances WHERE outstanding_amount<0
UNION ALL
SELECT 'SUPPLIER_MISMATCH',a.allocation_id,'付款供应商与应付供应商不一致'
FROM payment_allocations a JOIN payments p ON p.payment_id=a.payment_id
JOIN v_payable_balances b ON b.payable_id=a.payable_id WHERE p.supplier_id<>b.supplier_id
UNION ALL
SELECT 'RETURN_AP_MISMATCH',c.credit_id,'退货与应付不属于同一入库单'
FROM payable_credits c JOIN purchase_returns t ON t.return_id=c.return_id
JOIN payables a ON a.payable_id=c.payable_id WHERE t.receipt_id<>a.receipt_id
UNION ALL
SELECT 'AP_AMOUNT_MISMATCH',a.payable_id,'应付原额不符合本项目入库数量乘订单单价约定'
FROM payables a JOIN goods_receipts r ON r.receipt_id=a.receipt_id
JOIN purchase_orders o ON o.order_id=r.order_id WHERE a.original_amount<>r.received_qty*o.unit_price
UNION ALL
SELECT 'CREDIT_AMOUNT_MISMATCH',c.credit_id,'冲减金额不符合本项目退货数量乘订单单价约定'
FROM payable_credits c JOIN purchase_returns t ON t.return_id=c.return_id
JOIN goods_receipts r ON r.receipt_id=t.receipt_id
JOIN purchase_orders o ON o.order_id=r.order_id WHERE c.amount<>t.returned_qty*o.unit_price
UNION ALL
SELECT 'RECEIPT_DATE',r.receipt_id,'入库日期早于订单日期'
FROM goods_receipts r JOIN purchase_orders o ON o.order_id=r.order_id WHERE r.received_date<o.order_date
UNION ALL
SELECT 'RETURN_DATE',t.return_id,'退货日期早于原入库日期'
FROM purchase_returns t JOIN goods_receipts r ON r.receipt_id=t.receipt_id WHERE t.returned_date<r.received_date
UNION ALL
SELECT 'AP_DATE',a.payable_id,'应付确认早于验收入库，不符合演示流程'
FROM payables a JOIN goods_receipts r ON r.receipt_id=a.receipt_id WHERE a.recognized_date<r.received_date
UNION ALL
SELECT 'CREDIT_DATE',c.credit_id,'冲减早于退货或应付确认'
FROM payable_credits c JOIN purchase_returns t ON t.return_id=c.return_id
JOIN payables a ON a.payable_id=c.payable_id
WHERE c.credit_date<t.returned_date OR c.credit_date<a.recognized_date
UNION ALL
SELECT 'ALLOCATION_DATE',a.allocation_id,'核销早于付款或应付确认'
FROM payment_allocations a JOIN payments p ON p.payment_id=a.payment_id
JOIN payables b ON b.payable_id=a.payable_id
WHERE a.allocated_date<p.payment_date OR a.allocated_date<b.recognized_date;

-- 正常种子数据应返回0行；不代表所有可能的ERP异常均已覆盖。
SELECT * FROM v_data_issues ORDER BY issue_code,record_id;

-- 待办单据，不等同于错误：已入库未确认应付、已退货未冲减、付款未核销。
SELECT 'RECEIPT_WITHOUT_AP' AS pending_type,r.receipt_id AS record_id
FROM goods_receipts r LEFT JOIN payables a ON a.receipt_id=r.receipt_id WHERE a.payable_id IS NULL
UNION ALL
SELECT 'RETURN_WITHOUT_CREDIT',t.return_id FROM purchase_returns t
LEFT JOIN payable_credits c ON c.return_id=t.return_id WHERE c.credit_id IS NULL
UNION ALL
SELECT 'UNALLOCATED_PAYMENT',payment_id FROM v_payment_balances WHERE unallocated_amount>0;
