CREATE DATABASE PROJECT;
USE PROJECT;

# data types of data 
DESCRIBE RESPONSE;
DESCRIBE TRANSACTIONS;

# number of data
SELECT COUNT(*) FROM TRANSACTIONS;
SELECT COUNT(*) FROM RESPONSE;

# handling missing values
SELECT * FROM TRANSACTIONS WHERE CUSTOMER_ID IS NULL;
SELECT * FROM TRANSACTIONS WHERE TRANS_DATE IS NULL;
SELECT * FROM TRANSACTIONS WHERE TRAN_AMOUNT IS NULL;
SELECT * FROM RESPONSE WHERE CUSTOMER_ID IS NULL;
SELECT * FROM RESPONSE WHERE RESPONSE IS NULL;


# DUPLICATE values
SELECT COUNT(DISTINCT customer_id) AS total_unique_customers
FROM transactions;
SELECT COUNT(DISTINCT customer_id) AS total_unique
FROM RESPONSE;
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM transactions;



-- data for times arrive
CREATE TABLE TIMES_DATA AS
SELECT CUSTOMER_ID, COUNT(*) AS TOTAL  FROM TRANSACTIONS
GROUP BY CUSTOMER_ID;
SELECT COUNT(*) FROM TIMES_DATA;


-- finding missing customer
SELECT A.customer_id AS missing_customers
FROM times_data A
LEFT JOIN response B
ON A.customer_id = B.customer_id
WHERE B.customer_id IS NULL;
-- add into csv file


-- finding total amount
SELECT CUSTOMER_ID, SUM(TRAN_AMOUNT) AS TOTAL_SPEND FROM TRANSACTIONS
GROUP BY CUSTOMER_ID; 


-- min arrival & max arrival
SELECT MIN(TIMES_ARRIVE) FROM TIMES_DATAA;
SELECT CUSTOMER_ID FROM TIMES_DATAA
WHERE TIMES_ARRIVE='4';

SELECT max(TIMES_ARRIVE) FROM TIMES_DATAA;
SELECT CUSTOMER_ID FROM TIMES_DATAA
WHERE TIMES_ARRIVE='39';

-- finding latest date in data-- 
SELECT 
    MAX(STR_TO_DATE(trans_date, '%d-%m-%Y')) AS real_latest_date
FROM transactions_2;

-- finding last date purchase of every customer--
SELECT CUSTOMER_ID, MAX(STR_TO_DATE(trans_date, '%d-%m-%Y')) AS LAST_DATE FROM TRANSACTIONS_2
GROUP BY CUSTOMER_ID;

ALTER TABLE TIMES_DATAA
ADD COLUMN LAST_PURCHASE DATE;

UPDATE times_dataa t
JOIN (
    SELECT 
        customer_id,
        MAX(STR_TO_DATE(trans_date,'%d-%m-%Y')) AS last_date
    FROM transactions_2
    GROUP BY customer_id
) x
ON t.customer_id = x.customer_id
SET t.last_purchase = x.last_date;

SELECT * FROM TIMES_DATAA;


-- ADDING COLUMN LATEST --
ALTER TABLE TIMES_DATAA ADD COLUMN LATEST_DATE DATE;

UPDATE TIMES_DATAA
JOIN ( SELECT MAX(LAST_PURCHASE) AS MAX_D FROM TIMES_DATAA ) A 
SET TIMES_DATAA.LATEST_DATE = A.MAX_D;


-- finding recency ( latest - last date) --
ALTER TABLE TIMES_DATAA
ADD COLUMN RECENCY INT;

SELECT DATEDIFF(LATEST_DATE, LAST_PURCHASE) AS RECENCY FROM TIMES_DATAA;

UPDATE times_dataa
SET recency = DATEDIFF(latest_date, last_purchase);


-- generating R_scrore --
ALTER TABLE times_dataa 
ADD COLUMN R_score INT;

UPDATE times_dataa t
JOIN (
    SELECT 
        CUSTOMER_ID,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_rank
    FROM times_dataa
) x
ON t.CUSTOMER_ID = x.CUSTOMER_ID
SET t.R_score = 6 - x.r_rank;


-- generating F_scrore --
ALTER TABLE times_dataa 
ADD COLUMN F_score INT;

UPDATE TIMES_DATAA
JOIN ( 
       SELECT CUSTOMER_ID, 
       NTILE(5) OVER (ORDER BY TIMES_ARRIVE ASC) AS F_RANK
       FROM TIMES_DATAA
) A
ON TIMES_DATAA.CUSTOMER_ID = A.CUSTOMER_ID
SET TIMES_DATAA.F_SCORE = A.F_RANK;


-- generating M_scrore --
ALTER TABLE times_dataa 
ADD COLUMN M_score INT;

UPDATE TIMES_DATAA T
JOIN (
       SELECT CUSTOMER_ID,
       NTILE(5) OVER (ORDER BY TOTAL_SPEND ASC) AS M_RANK
       FROM TIMES_DATAA
	) B
ON T.CUSTOMER_ID = B.CUSTOMER_ID
SET T.M_SCORE = B.M_RANK;


-- generating RFM_scrore --
ALTER TABLE times_dataa 
ADD COLUMN RFM_score VARCHAR(5);

UPDATE times_dataa
SET RFM_score = CONCAT(R_score, F_score, M_score);


-- BEHAVIOR OF CUSTOMER --
ALTER TABLE times_dataa ADD COLUMN segment VARCHAR(20);

UPDATE TIMES_DATAA
SET SEGMENT = 
           CASE
               WHEN R_SCORE >= 4 AND F_SCORE >= 4 AND M_SCORE >= 4 THEN 'VIP'
               WHEN F_score >= 3 AND M_score >= 3 THEN 'LOYAL'
			   WHEN F_score >= 2 AND M_score >= 2 AND R_SCORE >= 3 THEN 'REGULAR'
               WHEN R_score >= 4 AND F_score <= 2 THEN 'NEW'
               ELSE 'LOST'
			END;


SELECT * FROM TIMES_DATAA
ORDER BY CUSTOMER_ID ASC;




