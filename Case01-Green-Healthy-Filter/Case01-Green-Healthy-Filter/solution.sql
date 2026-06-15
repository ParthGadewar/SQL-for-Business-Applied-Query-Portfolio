CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    low_fats ENUM('Y', 'N'),
    recyclable ENUM('Y', 'N')
);

INSERT INTO Products VALUES
(0, 'Whole Grain Crackers', 'Y', 'N'),
(1, 'Organic Almond Milk', 'Y', 'Y'),
(2, 'Greek Yogurt Cup', 'N', 'Y'),
(3, 'Oat Granola Bar', 'Y', 'Y'),
(4, 'Cheddar Cheese Block', 'N', 'N');

SELECT product_id, product_name
FROM Products
WHERE low_fats = 'Y'
  AND recyclable = 'Y';
