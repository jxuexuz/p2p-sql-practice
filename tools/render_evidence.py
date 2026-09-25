"""Render recorded MySQL outputs as uniform result images, not application screenshots.
Optional: Python 3 + Pillow. Run from any directory after evidence JSON exists.
Does not connect to a database or alter query results.
"""
from pathlib import Path
import json
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'evidence'
data=json.loads((OUT/'verification_results.json').read_text(encoding='utf-8'))
font_path=os.environ.get('P2P_FONT_PATH', 'C:/Windows/Fonts/msyh.ttc')
if not Path(font_path).is_file():
    raise SystemExit('Set P2P_FONT_PATH to an installed Chinese-capable TrueType/OpenType font.')

def font(size): return ImageFont.truetype(font_path,size)
def rows(name): return [s.split('\t') for s in data['raw_results'][name].splitlines()]

def render(filename,title,sections,note):
    im=Image.new('RGB',(1600,1000),'white')
    d=ImageDraw.Draw(im)
    d.text((50,30),title,font=font(36),fill='#16324f')
    d.text((50,88),'独立测试实例 · MySQL '+data['mysql_version']+' · 业务截止日 '+data['report_as_of'],font=font(23),fill='#354657')
    d.text((50,125),'真实SQL输出整理图｜非DBeaver截图，非学习者操作截图',font=font(23),fill='#805319')
    y=185
    for label,headers,values,widths in sections:
        d.text((50,y),label,font=font(25),fill='#16324f'); y+=44
        height=40
        for ri,row in enumerate([headers]+values):
            x=50
            d.rectangle((50,y,1550,y+height),fill='#e8eef4' if ri==0 else ('#f7f9fb' if ri%2 else 'white'))
            for cell,width in zip(row,widths):
                value=str(cell)
                chosen=font(21)
                assert d.textbbox((0,0),value,font=chosen)[2] < width-16,(filename,value,width)
                d.text((x+8,y+5),value,font=chosen,fill='#17232f')
                x+=width
            d.line((50,y+height,1550,y+height),fill='#d7dfe7',width=1)
            y+=height
        y+=30
    assert y<875,(filename,y)
    d.text((50,880),note,font=font(21),fill='#354657')
    d.text((50,925),'来源：evidence/verification_results.json；SQL文件摘要随结果保存。',font=font(21),fill='#354657')
    d.text((50,958),'复核生成时间：'+data['generated_at'],font=font(18),fill='#5b6874')
    im.save(OUT/filename)

render('01_tables.png','01  初始化数据核对',[
    ('02_seed.sql：8张业务表', ['表名','记录数'], rows('02_seed.sql'),[1100,400])
], '表行数由实际查询返回，不是预填的预期值。')

r=rows('04_order_and_payment_report.sql')
assert len(r)==15
render('02_orders_payments.png','02  订单余额与付款核销',[
    ('订单汇总', ['订单','商品','原应付','冲减','已核销','未结清'],[[a[i] for i in [0,2,11,12,13,14]] for a in r[:5]],[150,350,250,250,250,250]),
    ('付款汇总', ['付款','供应商','付款日期','付款金额','已核销','未核销'], r[5:10],[150,150,450,250,250,250])
], '付款与核销分开：付款5的20元尚未分配到应付。金额单位：元。')

render('03_aging.png','03  应付账龄与逾期金额',[
    ('05_ap_aging.sql', ['供应商','未结清','0—30天','31—60天','61天以上','逾期','负余额'],
     [[a[i] for i in [0,2,3,4,5,6,7]] for a in rows('05_ap_aging.sql')],[180,220,220,220,220,220,220])
], '账龄从应付确认日算起，逾期依据到期日；二者不是同一个概念。金额单位：元。')

r=rows('06_delivery_timeliness.sql')
render('04_delivery.png','04  足量准时交货率',[
    ('供应商指标', ['供应商','到期订单数','足量准时订单数','及时率（%）'],[[a[i] for i in [0,2,3,4]] for a in r[:3]],[250,350,450,450]),
    ('逐笔入库', ['订单','商品','承诺交货日','入库单','实际入库日','数量','状态'],r[3:],[120,200,260,160,260,180,320])
], 'NULL表示无适用分母；未到期订单不进入及时率分母。')

r=rows('08_acceptance_tests.sql')
assert len(r)==21 and all(a[-1]=='PASS' for a in r)
render('05_acceptance.png','05  基准验收',[
    ('08_acceptance_tests.sql：第一组12项', ['测试项','结果'],r[:12],[1250,250])
], '此页展示12项基准检查；另9项边界检查在下一张图。')
render('06_boundaries.png','06  相等边界与账龄分界',[
    ('数量与金额比较', ['案例','实际值','上限','结果'],r[12:16],[750,250,250,250]),
    ('账龄分界', ['账龄天数','分组','结果'],r[16:],[500,500,500])
], '08合计21行PASS。边界CTE为只读逻辑测试，真实写表实验见下一张图。')

r=rows('09_transaction_experiments.sql')
assert len(r)==6
render('07_rollback.png','07  异常识别与事务回滚',[
    ('09_transaction_experiments.sql：事务中的异常记录', ['异常代码','记录编号','说明'],r[:5],[460,180,860]),
    ('全部回滚后', ['检查项','实际结果'],[['异常记录数',str(data['final_issue_count'])],['未结清应付余额（元）',data['final_outstanding']]], [1150,350])
], '四个事务分别回滚。异常查询负责发现问题，不会自动阻止异常提交。')
print('Rendered 7 result images, each 1600x1000, from recorded MySQL outputs.')
