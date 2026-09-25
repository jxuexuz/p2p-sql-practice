-- 只在全新的本地练习库执行一次；同名库已存在则停止，不要忽略报错。
CREATE DATABASE p2p_portfolio_demo CHARACTER SET utf8mb4;
USE p2p_portfolio_demo;

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 简化：一张订单只包含一种商品；没有单独的订单行表。
CREATE TABLE purchase_orders (
    order_id INT PRIMARY KEY,
    supplier_id INT NOT NULL,
    item_name VARCHAR(80) NOT NULL,
    unit VARCHAR(10) NOT NULL,
    ordered_qty INT NOT NULL CHECK (ordered_qty > 0),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
    order_date DATE NOT NULL,
    promised_date DATE NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    CHECK (promised_date >= order_date)
) ENGINE=InnoDB;

CREATE TABLE goods_receipts (
    receipt_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    received_qty INT NOT NULL CHECK (received_qty > 0),
    received_date DATE NOT NULL,
    FOREIGN KEY (order_id) REFERENCES purchase_orders(order_id)
) ENGINE=InnoDB;

CREATE TABLE payables (
    payable_id INT PRIMARY KEY,
    receipt_id INT NOT NULL UNIQUE,
    recognized_date DATE NOT NULL,
    due_date DATE NOT NULL,
    original_amount DECIMAL(12,2) NOT NULL CHECK (original_amount > 0),
    FOREIGN KEY (receipt_id) REFERENCES goods_receipts(receipt_id),
    CHECK (due_date >= recognized_date)
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    supplier_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
) ENGINE=InnoDB;

-- 三张辅助表：实际退货、应付冲减、付款核销。
CREATE TABLE purchase_returns (
    return_id INT PRIMARY KEY,
    receipt_id INT NOT NULL,
    returned_qty INT NOT NULL CHECK (returned_qty > 0),
    returned_date DATE NOT NULL,
    reason VARCHAR(200) NOT NULL,
    FOREIGN KEY (receipt_id) REFERENCES goods_receipts(receipt_id)
) ENGINE=InnoDB;

CREATE TABLE payable_credits (
    credit_id INT PRIMARY KEY,
    return_id INT NOT NULL UNIQUE,
    payable_id INT NOT NULL,
    credit_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    FOREIGN KEY (return_id) REFERENCES purchase_returns(return_id),
    FOREIGN KEY (payable_id) REFERENCES payables(payable_id)
) ENGINE=InnoDB;

CREATE TABLE payment_allocations (
    allocation_id INT PRIMARY KEY,
    payment_id INT NOT NULL,
    payable_id INT NOT NULL,
    allocated_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id),
    FOREIGN KEY (payable_id) REFERENCES payables(payable_id)
) ENGINE=InnoDB;

SHOW TABLES;
