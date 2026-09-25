USE p2p_portfolio_demo;
-- 先执行 START TRANSACTION 和 INSERT；没有任何错误才执行 COMMIT。
-- 如果出错，执行 ROLLBACK，不要忽略错误继续提交。仅执行一次。
START TRANSACTION;
INSERT INTO suppliers VALUES (1,'启明文具（模拟）'),(2,'云杉办公（模拟）'),(3,'远航用品（模拟）');
INSERT INTO purchase_orders VALUES
(1,1,'中性笔','支',100,2.00,'2026-09-01','2026-09-10'),
(2,2,'笔记本','本',50,10.00,'2026-08-01','2026-08-10'),
(3,2,'文件夹','个',20,5.00,'2026-06-01','2026-06-10'),
(4,1,'订书机','台',10,20.00,'2026-09-20','2026-09-30'),
(5,1,'打印纸','包',10,10.00,'2026-07-01','2026-07-10');
INSERT INTO goods_receipts VALUES
(1,1,60,'2026-09-08'),(2,1,40,'2026-09-12'),
(3,2,30,'2026-08-09'),(4,3,20,'2026-06-10'),(5,5,10,'2026-07-10');
-- 演示约定：验收后人工确认应付，不等同于U8实际会计配置。
INSERT INTO payables VALUES
(1,1,'2026-09-08','2026-10-08',120.00),
(2,2,'2026-09-12','2026-10-12',80.00),
(3,3,'2026-08-10','2026-09-09',300.00),
(4,4,'2026-06-11','2026-07-11',100.00),
(5,5,'2026-07-10','2026-08-10',100.00);
INSERT INTO purchase_returns VALUES (1,1,10,'2026-09-15','模拟退货：包装破损，不要求补货');
INSERT INTO payable_credits VALUES (1,1,1,'2026-09-16',20.00);
INSERT INTO payments VALUES
(1,1,'2026-09-18',50.00),(2,1,'2026-09-20',40.00),
(3,2,'2026-08-20',100.00),(4,1,'2026-07-15',100.00),
(5,1,'2026-09-22',20.00);
-- 付款2分配到两个应付；应付1由两次付款核销；付款5尚未核销。
INSERT INTO payment_allocations VALUES
(1,1,1,'2026-09-18',50.00),(2,2,1,'2026-09-20',30.00),
(3,2,2,'2026-09-20',10.00),(4,3,3,'2026-08-20',100.00),
(5,4,5,'2026-07-15',100.00);
-- 确认以上全部成功后，单独执行下一行。
COMMIT;

SELECT 'suppliers' AS table_name, COUNT(*) AS row_count FROM suppliers
UNION ALL SELECT 'purchase_orders',COUNT(*) FROM purchase_orders
UNION ALL SELECT 'goods_receipts',COUNT(*) FROM goods_receipts
UNION ALL SELECT 'payables',COUNT(*) FROM payables
UNION ALL SELECT 'payments',COUNT(*) FROM payments
UNION ALL SELECT 'purchase_returns',COUNT(*) FROM purchase_returns
UNION ALL SELECT 'payable_credits',COUNT(*) FROM payable_credits
UNION ALL SELECT 'payment_allocations',COUNT(*) FROM payment_allocations;
