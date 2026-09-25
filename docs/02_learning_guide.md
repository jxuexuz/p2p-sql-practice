# 分阶段运行与讲解

不要把代码全部运行一遍就当作完成。每阶段保存结果并回答问题；不会解释时，回到相关SQL对照数据。

## 阶段一 连接和建表

1. 解压作品包，在DBeaver打开01。确认上方连接不是`<none>`，选择本地MySQL连接。
2. 单独执行`SHOW DATABASES LIKE 'p2p_portfolio_demo';`。如果0行，再执行01。
3. 每次切换脚本后，先执行该文件的`USE p2p_portfolio_demo;`，再执行`SELECT DATABASE();`，结果必须是`p2p_portfolio_demo`。不要只依赖工具栏显示的库名。
4. 执行`SHOW FULL TABLES;`。此时应有8张BASE TABLE。后续创建视图后还会看到4个VIEW。
5. 截图保存为本地`01_tables.png`。公开上传前裁掉账户、其他项目名称或私密窗口。

讲解问题：订单100支是否等于已经收到100支？为什么付款和核销需要分开？

## 阶段二 初始化数据

执行02，遇错停止。INSERT无错误再COMMIT；异常时ROLLBACK。核对README中的8张表行数，然后执行03创建视图。

查这三张原表：

```sql
USE p2p_portfolio_demo;
SELECT * FROM goods_receipts WHERE order_id=1 ORDER BY receipt_id;
SELECT * FROM payables WHERE receipt_id IN (1,2) ORDER BY payable_id;
SELECT * FROM payment_allocations WHERE payable_id IN (1,2) ORDER BY allocation_id;
```

先自己算订单1：入库60＋40，退货10，冲减20；原应付120＋80；核销50＋30＋10；余额200－20－90＝90。

## 阶段三 订单与核销

执行04，共3个结果集。订单报表5行，付款报表5行，核销明细5行。

截图：`02_order_report.png`、`03_payment_report.png`。

讲解问题：

- 订单4没有入库，应付为0，为什么不能叫“已经付清”？
- 付款5已经付出20元，为什么应付总余额还是390？
- 订单1退货10支后，为什么“净收货90”但“待交货0”？
- 付款2如何分配给两笔应付？

## 阶段四 账龄与交货

先执行05中的SET，再执行完整WITH查询。按基准日对照三家供应商的账龄结果。然后执行06，查看供应商及时率和6行到货明细。

截图：`04_aging.png`、`05_delivery.png`。

讲解问题：

- 账龄和逾期有什么区别？
- 订单1在9月8日到60支、9月12日到40支，承诺9月10日，是否足量准时？
- 订单2只到了30/50，为什么即使第一批准时仍不能计入“足量准时订单”？
- 供应商3及时率为什么为空？

## 阶段五 验收与异常

首次执行07创建异常视图。异常结果0行，待办结果只有付款5。执行08，检查3组结果均为PASS。

可选运行09，每个START TRANSACTION到ROLLBACK作为一个完整实验。截图保留一次超量退货结果、一次付款超核销结果，最后核对390恢复不变。不要将测试异常提交。

截图：`06_acceptance.png`、`07_exception_demo.png`。图片是学习者实际执行的证据，不要把别人结果改名当自己的。

## 阶段六 发布前解释

用自己的话讲3分钟：业务需求是什么、8张表为什么这样分、订单1余额怎么来、账龄与逾期怎么区分、你测试了什么、哪些地方尚未实现。

把实际MySQL版本、运行日期、遇到的错误和截图名称填入`docs/06_verification.md`。理解和复跑完成后再使用简历项目表述。
