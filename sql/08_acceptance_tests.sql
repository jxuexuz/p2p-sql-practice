USE p2p_portfolio_demo;
-- 只读验收：全部预期为PASS；这不是覆盖所有场景的证明。
SELECT 'T01_order_1_balance_90' AS test_name, IF((SELECT outstanding_amount FROM v_order_summary WHERE order_id=1)=90,'PASS','FAIL') AS result
UNION ALL SELECT 'T02_order_2_partial_30_of_50',IF((SELECT received_qty FROM v_order_summary WHERE order_id=2)=30,'PASS','FAIL')
UNION ALL SELECT 'T03_order_4_no_receipt',IF((SELECT receipt_status FROM v_order_summary WHERE order_id=4)='未入库','PASS','FAIL')
UNION ALL SELECT 'T04_order_5_closed',IF((SELECT settlement_status FROM v_order_summary WHERE order_id=5)='已结清','PASS','FAIL')
UNION ALL SELECT 'T05_total_original_700',IF((SELECT SUM(original_amount) FROM payables)=700,'PASS','FAIL')
UNION ALL SELECT 'T06_total_credit_20',IF((SELECT SUM(amount) FROM payable_credits)=20,'PASS','FAIL')
UNION ALL SELECT 'T07_total_allocated_290',IF((SELECT SUM(amount) FROM payment_allocations)=290,'PASS','FAIL')
UNION ALL SELECT 'T08_total_outstanding_390',IF((SELECT SUM(outstanding_amount) FROM v_payable_balances)=390,'PASS','FAIL')
UNION ALL SELECT 'T09_cash_paid_310',IF((SELECT SUM(amount) FROM payments)=310,'PASS','FAIL')
UNION ALL SELECT 'T10_unallocated_20',IF((SELECT SUM(unallocated_amount) FROM v_payment_balances)=20,'PASS','FAIL')
UNION ALL SELECT 'T11_no_detected_issues',IF((SELECT COUNT(*) FROM v_data_issues)=0,'PASS','FAIL')
UNION ALL SELECT 'T12_order_1_net_receipt_90',IF((SELECT net_received_qty FROM v_order_summary WHERE order_id=1)=90,'PASS','FAIL');

-- 不写表的边界测试：相等不是超量；年龄30/31/60/61分界互不重叠。
WITH cases AS (
 SELECT 1 AS n,'退货恰好等于入库' AS case_name,60 AS actual,60 AS limit_value,0 AS expected
 UNION ALL SELECT 2,'累计退货超量',61,60,1
 UNION ALL SELECT 3,'核销恰好等于付款',20,20,0
 UNION ALL SELECT 4,'核销超过付款',21,20,1
)
SELECT case_name,actual,limit_value,IF((actual>limit_value)=expected,'PASS','FAIL') AS result FROM cases ORDER BY n;

WITH cases AS (
 SELECT 0 AS age_days,'0-30' AS expected
 UNION ALL SELECT 30,'0-30' UNION ALL SELECT 31,'31-60'
 UNION ALL SELECT 60,'31-60' UNION ALL SELECT 61,'61+'
), actual AS (
 SELECT age_days,expected,CASE WHEN age_days BETWEEN 0 AND 30 THEN '0-30'
 WHEN age_days BETWEEN 31 AND 60 THEN '31-60' ELSE '61+' END AS actual_bucket FROM cases
)
SELECT age_days,actual_bucket,IF(expected=actual_bucket,'PASS','FAIL') AS result FROM actual ORDER BY age_days;
