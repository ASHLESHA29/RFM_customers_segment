-- 1. Create and Use Database
CREATE DATABASE PROJECT;
USE PROJECT;


-- 2. Check Data Types (Replaced DESCRIBE with sp_help)
EXEC sp_help 'TRANSACTIONS';
EXEC sp_help 'RESPONSE';



-- 3. Number of data
SELECT COUNT(*) FROM TRANSACTIONS;
SELECT COUNT(*) FROM RESPONSE;



-- 4. finding missing values
SELECT COUNT(*) FROM Transactions WHERE customer_id IS NULL;
SELECT COUNT(*) FROM Transactions WHERE trans_date IS NULL;
SELECT COUNT(*) FROM Transactions WHERE tran_amount IS NULL;
SELECT COUNT(*) FROM Response WHERE customer_id IS NULL;
SELECT COUNT(*) FROM Response WHERE response IS NULL;


-- 5. Duplicate values
SELECT COUNT(DISTINCT CUSTOMER_ID) AS total_unique_customers FROM Transactions;
SELECT COUNT(DISTINCT CUSTOMER_ID) AS total_unique_customers_RESPONSE FROM Response;
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM transactions;





-- 6. ADDING COLUMN OF TIME_ARRIVE, TOTAL AMOUNT AND RESPONSE -IN NEW TABLE--
SELECT 
DISTINCT T.CUSTOMER_ID, COUNT(T.CUSTOMER_ID) AS TIMES_ARRIVE, SUM(T.TRAN_AMOUNT) AS TOTAL_SPEND, R.response
INTO TIMES_DATA 
FROM Transactions T LEFT JOIN Response R ON T.customer_id = R.customer_id
GROUP BY T.customer_id,R.response

SELECT * FROM TIMES_DATA
ORDER BY customer_id ASC;

DROP TABLE TIMES_DATA




-- First, replace any remaining NULLs with 0 (required before adding NOT NULL)
SELECT CUSTOMER_ID, RESPONSE FROM TIMES_DATA
WHERE RESPONSE IS NULL

UPDATE TIMES_DATA 
SET RESPONSE = 0 
WHERE RESPONSE IS NULL

-- 2. Permanently change the data type to INT and block future NULLs
ALTER TABLE TIMES_DATA
ALTER COLUMN RESPONSE INT NOT NULL;



-- latest date of sale
SELECT MAX(TRANS_DATE) AS LATEST_DATE FROM Transactions
-- last purchase date of customers
SELECT CUSTOMER_ID, MAX(TRANS_DATE) AS MAX_DATE FROM Transactions
GROUP BY customer_id
ORDER BY customer_id ASC;





-- 7. ADDING LAST PURCHASE DATE COLUMNS IN TABLE
ALTER TABLE TIMES_DATA ADD LAST_PURCHASE_DATE DATE;

UPDATE TIMES_DATA SET LAST_PURCHASE_DATE = X.MAX_DATE
FROM TIMES_DATA T 
JOIN (SELECT CUSTOMER_ID, MAX(TRANS_DATE) AS MAX_DATE FROM Transactions GROUP BY customer_id) X
ON T.CUSTOMER_ID = X.customer_id


-- adding latest purchase date --
ALTER TABLE TIMES_DATA ADD LATEST_DATE DATE;
UPDATE TIMES_DATA SET LATEST_DATE = ( SELECT MAX(TRANS_DATE) AS LATEST_DATE FROM Transactions );


-- adding Recency column 
ALTER TABLE TIMES_DATA ADD RECENCY INT;
UPDATE TIMES_DATA SET RECENCY = DATEDIFF(DAY,LAST_PURCHASE_DATE,LATEST_DATE)





-- 8. adding score columns
ALTER TABLE TIMES_DATA ADD R_score INT;
ALTER TABLE TIMES_DATA ADD F_score INT;
ALTER TABLE TIMES_DATA ADD M_score INT;


-- Calculate R_score (Recency: Lower days elapsed = Higher score)
-- We subtract the rank from 6 so that the most recent customers get a 5
WITH R_CTE AS (
     SELECT CUSTOMER_ID, 
     NTILE(5) OVER (ORDER BY RECENCY ASC) AS R_RANK
     FROM TIMES_DATA
)
UPDATE T SET T.R_SCORE = 6 - R_RANK
FROM TIMES_DATA T JOIN R_CTE R ON T.CUSTOMER_ID = R.CUSTOMER_ID


-- Calculate F_score (Frequency: More arrivals = Higher score)
WITH F_CTE AS ( 
     SELECT CUSTOMER_ID,
     NTILE(5) OVER (ORDER BY TIMES_ARRIVE ASC) AS F_RANK
     FROM TIMES_DATA
)
UPDATE T SET T.F_SCORE = F.F_RANK
FROM TIMES_DATA T JOIN F_CTE F ON T.CUSTOMER_ID = F.CUSTOMER_ID


-- Calculate M_score (Monetary: Higher spend = Higher score)
WITH M_CTE AS (
     SELECT CUSTOMER_ID,
     NTILE(5) OVER (ORDER BY TOTAL_SPEND ASC) AS M_RANK
     FROM TIMES_DATA
)
UPDATE T SET T.M_SCORE = M.M_RANK
FROM TIMES_DATA T JOIN M_CTE M ON T.CUSTOMER_ID = M.CUSTOMER_ID





-- 9. Add the RFM SCORE new column
ALTER TABLE TIMES_DATA
ADD RFM_SCORE VARCHAR(3);

UPDATE TIMES_DATA 
SET RFM_SCORE = CONCAT(CAST(R_SCORE AS varchar),CAST(F_SCORE AS varchar),CAST(M_SCORE AS varchar))




-- 10. add Segment column
ALTER TABLE TIMES_DATA 
ADD SEGMENT VARCHAR(20)

UPDATE TIMES_DATA
SET SEGMENT = CASE
                  WHEN R_SCORE >= 4 AND F_SCORE >= 4 AND M_SCORE >= 4 THEN 'VIP'
                  WHEN R_SCORE >= 4 AND F_SCORE <= 2                  THEN 'NEW'
                  WHEN R_SCORE = 1                                    THEN 'LOST'
                  WHEN ( F_SCORE >= 3 OR M_SCORE >= 4 ) AND R_SCORE >= 2 THEN 'LOYAL'
                  ELSE 'REGULAR'
              END;




-- 11. calculation matrics
SELECT 
    segment,
    COUNT(CUSTOMER_ID) AS Total_Customers,
    SUM(TOTAL_SPEND) AS Total_Revenue,
    AVG(TOTAL_SPEND) AS Avg_Customer_Spend,
    SUM(CAST(RESPONSE AS INT)) AS Total_Campaign_Responses,
    AVG(CAST(RESPONSE AS FLOAT)) * 100 AS Campaign_Conversion_Rate
FROM TIMES_DATA
GROUP BY segment
ORDER BY Total_Revenue DESC;



-- insights
--The Power Engines (VIP + LOYAL): drive over 65% of your total revenue



SELECT * FROM TIMES_DATA
ORDER BY customer_id ASC;


EXEC SP_HELP 'TIMES_DATA'

