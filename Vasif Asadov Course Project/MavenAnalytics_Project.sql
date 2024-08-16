-- UDEMY MYSQL ADVANCED COURSE PROJECT -- 


-- SCHEMA NAME: mavenanalytics
CREATE SCHEMA mavenanalytics_project;
USE mavenanalytics_project;


-- ****************************************************
-- CREATE ALL THE TABLES -- 

-- 1. 'order_items' TABLE
CREATE TABLE order_items (
	order_item_id BIGINT PRIMARY KEY NOT NULL,
    created_at DATETIME,
    order_id BIGINT,
    price_usd DECIMAL(6,2),
    cogs_usd DECIMAL(6,2),
    website_session_id BIGINT
);
drop table order_items;

-- 2. 'order_items_refunds' TABLE
CREATE TABLE order_items_refunds (
	order_item_refund_id BIGINT PRIMARY KEY NOT NULL,
    created_at DATETIME,
    order_item_id BIGINT,
    order_id BIGINT,
    refund_amount_usd DECIMAL(6,2)    
);

-- 3. 'products' TABLE
CREATE TABLE products(
	product_id BIGINT PRIMARY KEY NOT NULL,
    created_at DATETIME,
    product_name VARCHAR(100)
);

-- 4. 'website_sessions' TABLE
CREATE TABLE website_sessions(
	website_session_id BIGINT PRIMARY KEY NOT NULL,
    created_at DATETIME,
    user_id BIGINT,
    is_repeat_session VARCHAR(10),
    utm_source VARCHAR(200),
    utm_campaign VARCHAR(200),
    utm_content VARCHAR(200),
    device_type VARCHAR(200),
    http_referer VARCHAR(200)
);

-- 5. 'website_pageviews' TABLE
CREATE TABLE website_pageviews(
		website_pageview_id BIGINT PRIMARY KEY NOT NULL,
        created_at DATETIME,
        website_session_id BIGINT,
        pageview_url VARCHAR(50)
);


-- **************************************************** --
-- LOAD ALL THE DATA TO THE TABLES -- 

-- LOAD 'order_items_xxxx.csv' file into the 'order_items' table
LOAD DATA INFILE 'C:/Users/Resources/18.order_items_2014_Apr.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES; 

-- While Adding the data new files 'product_id' and 'is_primary_item'
-- columns must be added.
/* ALTER TABLE order_items
ADD COLUMN product_id VARCHAR(10);

UPDATE order_items SET product_id = 1
WHERE product_id IS NULL;

ALTER TABLE order_items
ADD COLUMN is_primary_item VARCHAR(10);

UPDATE order_items SET is_primary_item = 1
WHERE is_primary_item IS NULL;
*/

-- LOAD ALL 'order_items_refunds_xxxx.csv' files into the 'order_items_refunds' table
LOAD DATA INFILE 'C:/Users/Resources/20.order_item_refunds_2014_Apr.csv'
INTO TABLE order_items_refunds
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES; 


-- After loading the firs file '01.order_items_2012_March.csv' 
-- We should remove the last 5 rows in order to insert the new file
-- Because the primary key constraint. There must not be duplicate primary key value
DELETE FROM order_items_refunds 
WHERE order_item_refund_id = 6;



-- LOAD ALL 'website_sessions_xxxx.csv' files into the 'website_sessions' table
LOAD DATA INFILE 'C:/Users/Resources/22.website_sessions_2014_Apr.csv'
INTO TABLE website_sessions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES; 



-- LOAD ALL 'website_pageviews_xxxx.csv' files into the 'website_pageviews' table
LOAD DATA INFILE 'C:/Users/Resources/24.website_pageviews_2014_Apr.csv'
INTO TABLE website_pageviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES; 


-- INSERT NEW VALUES INTO THE 'products' TABLE
INSERT INTO products VALUES 
(1, '2012-03-19 09:00:00', 'The Original Mr. Fuzzy'),
(2, '2013-01-06 13:00:00', 'The Forever Love Bear'),
(3, '2013-12-12 09:00:00', 'The Birthday Sugar Panda'),
(4, '2014-02-05 10:00:00', 'The Hudson River Mini Bear');



-- **************************************************** --
-- BUILD THE RELATIONSHIPS BETWEEN ALL THE TABLES --

-- Add foreign keys to 'order_items'
ALTER TABLE order_items
ADD CONSTRAINT orderitems_websitesession_fk
FOREIGN KEY (website_session_id)
REFERENCES website_sessions(website_session_id);

ALTER TABLE order_items
ADD CONSTRAINT orderitems_productid_fk
FOREIGN KEY (product_id)
REFERENCES products(product_id);


-- Add foreign keys to 'order_items_refunds'
ALTER TABLE order_items_refunds
ADD CONSTRAINT orderitemsrefunds_orderitem_fk
FOREIGN KEY (order_item_id)
REFERENCES order_items(order_item_id);


ALTER TABLE website_pageviews
ADD CONSTRAINT webpageviews_websessions_fk
FOREIGN KEY (website_session_id)
REFERENCES website_sessions(website_session_id);



-- **************************************************** --
-- TRIGGERS -- 

-- ORDER SUMMARY TABLE

CREATE TABLE orders
(	order_id BIGINT PRIMARY KEY, 
	created_at DATETIME, 
    website_session_id BIGINT,
    primary_product_id BIGINT,
    items_purchased BIGINT,
    price_usd DECIMAL(6,2),
    cogs_usd DECIMAL(6,2)
);

CREATE TRIGGER insert_new_orders
AFTER INSERT ON order_items
FOR EACH ROW

	REPLACE INTO orders 
	SELECT 
		order_id, 
		MIN(created_at) as created_ad,
		MIN(website_session_id) as website_session_id,
		SUM(CASE
			WHEN is_primary_item = 1 THEN product_id
			ELSE NULL
			END) AS primary_product_id,
		COUNT(order_item_id) AS items_purchased,
		SUM(price_usd) AS price_usd,
		SUM(cogs_usd) AS cogs_usd
		FROM order_items
        WHERE order_id = NEW.order_id
		GROUP BY 1
		ORDER BY 1;
   

-- **************************************************** --
-- MySQL VIEWS --

-- Creating 'monthly_session' VIEW  to summarize the data -- 

CREATE VIEW monthly_sessions AS 
	SELECT YEAR(created_at) years, 
    MONTH(created_at) months,
	utm_source, 
    utm_campaign,
	COUNT(website_session_id) as number_of_sessions 
FROM website_sessions
GROUP BY 1,2,3,4;

SELECT * FROM monthly_sessions;



-- **************************************************** --
-- STORED PROCEDURES -- 

DELIMITER // 

CREATE PROCEDURE revenue_reports
(IN startdate DATE, IN enddate DATE)
BEGIN
	SELECT 
    COUNT(order_id) AS total_orders, 
    SUM(price_usd) AS total_revenue 
    FROM order_items
	WHERE DATE(created_at) BETWEEN startdate AND enddate;
    
END //

DELIMITER ; 
CALL revenue_reports('2013-11-01', '2013-12-31');










