CREATE TABLE dbo.sales
(
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);
INSERT INTO [dbo].[sales] ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
CREATE TABLE dbo.menu
(
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);
INSERT INTO [dbo].[menu] ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
CREATE TABLE dbo.members
(
  "customer_id" VARCHAR(1),
  "join_date" DATE
);
INSERT INTO [dbo].[members] ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.[customer_id],
	SUM(p.[price]) AS total_amount
FROM [dbo].[sales] AS s INNER JOIN [dbo].[menu] AS p
ON s.[product_id] = p.[product_id]
GROUP BY s.[customer_id];
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. How many days has each customer visited the restaurant?
SELECT
	s.[customer_id],
	COUNT(DISTINCT s.[order_date]) AS 'No. Of Days'
FROM [dbo].[sales] AS s
GROUP BY s.[customer_id];
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. What was the first item from the menu purchased by each customer?
WITH CTE AS
(
	SELECT
		s.[customer_id],
		s.[product_id],
		RANK() OVER(PARTITION BY s.[customer_id] ORDER BY s.[order_date] ASC) AS RNK
	FROM [dbo].[sales] AS s
)
SELECT
	CTE.[customer_id],
	p.[product_name]
FROM [dbo].[menu] AS p INNER JOIN [CTE]
ON p.[product_id] = CTE.[product_id]
WHERE [RNK] = 1
GROUP BY CTE.[customer_id], p.[product_name];
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	TOP 1
	s.[product_id],
	p.[product_name],
	SUM(p.[price]) AS 'total_paid',
	COUNT(*) AS 'num_orders'
FROM [dbo].[sales] AS s INNER JOIN [dbo].[menu] AS p
ON s.[product_id] = p.[product_id]
GROUP BY s.[product_id], p.[product_name]
ORDER BY [num_orders] DESC;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Which item was the most popular for each customer?
WITH ranking AS
(
	SELECT
		s.[customer_id],
		s.[product_id],
		p.[product_name],
		COUNT(*) num_orders,
		ROW_NUMBER() OVER(PARTITION BY s.[customer_id] ORDER BY COUNT(*) DESC) AS RNK
	FROM [dbo].[sales] AS s INNER JOIN [dbo].[menu] AS p
	ON s.[product_id] = p.[product_id]
	GROUP BY s.[customer_id], s.[product_id], p.[product_name]
)
SELECT
	[customer_id],
	[product_name],
	[num_orders]
FROM [ranking]
WHERE [RNK] = 1;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS
(
	SELECT
		s.[customer_id],
		p.[product_name],
		DENSE_RANK() OVER(PARTITION BY s.[customer_id] ORDER BY s.[order_date] ASC) AS RNK
	FROM [dbo].[sales] AS s INNER JOIN [dbo].[members] AS m
	ON s.[customer_id] = m.[customer_id]
	INNER JOIN [dbo].[menu] AS p
	ON s.[product_id] = p.[product_id]
	WHERE s.[order_date] >= m.[join_date]
)
SELECT
	[customer_id],
	[product_name]
FROM [CTE]
WHERE [RNK] = 1;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7. Which item was purchased just before the customer became a member?
SELECT
	s.[customer_id],
	p.[product_name]
FROM [dbo].[sales] AS s INNER JOIN [dbo].[members] AS m
ON s.[customer_id] = m.[customer_id]
INNER JOIN [dbo].[menu] AS p
ON s.[product_id] = p.[product_id]
WHERE s.[order_date] < m.[join_date]
GROUP BY s.[customer_id], p.[product_name];
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	s.[customer_id],
	COUNT(s.[product_id]) AS 'total_items',
	SUM(p.[price]) AS 'amount_spent'
FROM [dbo].[sales] AS s INNER JOIN [dbo].[menu] AS p
ON s.[product_id] = p.[product_id]
INNER JOIN [dbo].[members] AS m
ON s.[customer_id] = m.[customer_id]
WHERE s.[order_date] < m.[join_date]
GROUP BY s.[customer_id];
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CTE AS
(
	SELECT
		s.[customer_id],
		CASE
			WHEN p.[product_name] = 'sushi' THEN 20 * p.[price]
			ELSE p.[price] * 10
		END AS 'points'
	FROM [dbo].[sales] AS s INNER JOIN [dbo].[menu] AS p
	ON s.[product_id] = p.[product_id]
)
SELECT
	[customer_id],
	SUM([points]) AS 'total_points'
FROM [CTE]
GROUP BY [customer_id];
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH CTE AS
(
	SELECT
		s.[customer_id],
		CASE
			WHEN s.[order_date] BETWEEN m.[join_date] AND DATEADD(DAY, 6, m.[join_date]) THEN 20 * p.[price]
			WHEN p.[product_name] = 'sushi' THEN 20 * p.[price]
			ELSE p.[price] * 10
		END AS 'points'
	FROM [dbo].[sales] AS s INNER JOIN [dbo].[members] AS m
	ON s.[customer_id] = m.[customer_id]
	INNER JOIN [dbo].[menu] AS p
	ON s.[product_id] = p.[product_id]
	WHERE MONTH(s.[order_date]) = 1
)
SELECT
	customer_id,
	SUM([points]) AS 'total_points'
FROM [CTE]
GROUP BY [customer_id];
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------