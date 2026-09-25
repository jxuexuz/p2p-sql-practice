USE p2p_portfolio_demo;
-- 可选进阶：先完成01～08。在同一连接执行每个完整的事务块。
-- 禁止将末尾ROLLBACK换成COMMIT。遇到错误立即ROLLBACK。
-- 全部新增记录只存在于事务内，回滚后种子数据保持不变。

-- A：原入库60，已有退货10，再退51，累计61；预期一行OVER_RETURN。
START TRANSACTION;
INSERT INTO purchase_returns VALUES (901,1,51,'2026-09-25','模拟超量测试，回滚');
SELECT * FROM v_data_issues ORDER BY issue_code,record_id;
ROLLBACK;

-- B：付款5金额20，核销21；预期一行OVER_ALLOCATION。
START TRANSACTION;
INSERT INTO payment_allocations VALUES (902,5,2,'2026-09-25',21.00);
SELECT * FROM v_data_issues ORDER BY issue_code,record_id;
ROLLBACK;

-- C：付款3属于供应商2，却核销供应商1的应付；预期供应商错配和付款超核销两行。
START TRANSACTION;
INSERT INTO payment_allocations VALUES (903,3,1,'2026-09-25',1.00);
SELECT * FROM v_data_issues ORDER BY issue_code,record_id;
ROLLBACK;

-- D：应付1剩20，新付款21全用于应付1；预期一行NEGATIVE_AP。
START TRANSACTION;
INSERT INTO payments VALUES (904,1,'2026-09-25',21.00);
INSERT INTO payment_allocations VALUES (904,904,1,'2026-09-25',21.00);
SELECT * FROM v_data_issues ORDER BY issue_code,record_id;
ROLLBACK;

-- 最后预期0行、总余额390。
SELECT * FROM v_data_issues;
SELECT SUM(outstanding_amount) AS outstanding_amount FROM v_payable_balances;
