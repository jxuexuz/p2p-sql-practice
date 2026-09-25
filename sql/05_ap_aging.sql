USE p2p_portfolio_demo;
-- 必须连同SET一起执行；固定日期便于复现，不依赖电脑当天日期。
SET @as_of_date = DATE('2026-09-25');
-- 账龄从应付确认日算，逾期从到期日算；仅把正的未结清余额放入账龄桶。
-- 在截止日前的核销和冲减才有效；截止日之后确认的应付不参与。
WITH credits AS (
 SELECT payable_id,SUM(amount) AS amount FROM payable_credits
 WHERE credit_date<=@as_of_date GROUP BY payable_id
), allocated AS (
 SELECT a.payable_id,SUM(a.amount) AS amount FROM payment_allocations a
 JOIN payments p ON p.payment_id=a.payment_id
 WHERE a.allocated_date<=@as_of_date AND p.payment_date<=@as_of_date GROUP BY a.payable_id
), balances AS (
 SELECT b.payable_id,o.supplier_id,b.recognized_date,b.due_date,
 b.original_amount-COALESCE(c.amount,0)-COALESCE(a.amount,0) AS balance
 FROM payables b JOIN goods_receipts r ON r.receipt_id=b.receipt_id
 JOIN purchase_orders o ON o.order_id=r.order_id
 LEFT JOIN credits c ON c.payable_id=b.payable_id
 LEFT JOIN allocated a ON a.payable_id=b.payable_id
 WHERE b.recognized_date<=@as_of_date
)
SELECT s.supplier_id,s.supplier_name,
 COALESCE(SUM(CASE WHEN b.balance>0 THEN b.balance ELSE 0 END),0) AS outstanding_amount,
 COALESCE(SUM(CASE WHEN b.balance>0 AND DATEDIFF(@as_of_date,b.recognized_date) BETWEEN 0 AND 30 THEN b.balance ELSE 0 END),0) AS age_0_30,
 COALESCE(SUM(CASE WHEN b.balance>0 AND DATEDIFF(@as_of_date,b.recognized_date) BETWEEN 31 AND 60 THEN b.balance ELSE 0 END),0) AS age_31_60,
 COALESCE(SUM(CASE WHEN b.balance>0 AND DATEDIFF(@as_of_date,b.recognized_date)>60 THEN b.balance ELSE 0 END),0) AS age_61_plus,
 COALESCE(SUM(CASE WHEN b.balance>0 AND b.due_date<@as_of_date THEN b.balance ELSE 0 END),0) AS overdue_amount,
 COALESCE(SUM(CASE WHEN b.balance<0 THEN -b.balance ELSE 0 END),0) AS abnormal_negative_balance
FROM suppliers s LEFT JOIN balances b ON b.supplier_id=s.supplier_id
GROUP BY s.supplier_id,s.supplier_name ORDER BY s.supplier_id;
