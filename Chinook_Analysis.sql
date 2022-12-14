/* Chinook DataSet Analysis from: https://www.sqlitetutorial.net/wp-content/uploads/2018/03/chinook.zip 
 * Analysis:
 * - Country
 * - Customers
 * - Genre
 */

	/*=== Countries Analysis === */


--Countries Ranking by Customers and Purchase
SELECT 
	BillingCountry,
	count(c.CustomerId) AS TotalOrders,
	SUM(Total) AS Total,
	count(DISTINCT i.CustomerId) AS Customers,
	ROUND(AVG(Total),2) AS AvgPursage
FROM 
	invoices i
JOIN customers c ON 
	i.CustomerId = c.CustomerId 
GROUP BY 
	BillingCountry
ORDER BY 
	TOTAL DESC;
--

--Famous genre per Country per Year
SELECT
	Country,
	InvYear,
	TopGenre,
	MAX(QtSold) AS QtSold
FROM (
SELECT 
	i.BillingCountry AS Country,
	STRFTIME('%Y', i.InvoiceDate) AS InvYear,
	g.Name AS TopGenre,
	SUM(ii.Quantity) AS QtSold
FROM
	invoice_items ii
	JOIN invoices i ON ii.InvoiceId = i.InvoiceId
	JOIN tracks t ON ii.TrackId = t.TrackId
	JOIN genres g ON t.GenreId = g.GenreId 
GROUP BY Country, InvYear, t.GenreId
)
GROUP BY Country , InvYear;
--

--Famous genre per Country
SELECT
	*
FROM (
SELECT 
	i.BillingCountry AS Country,
	g.Name AS TopGenre,
	SUM(ii.Quantity) AS QtSold
FROM
	invoice_items ii
	JOIN invoices i ON ii.InvoiceId = i.InvoiceId
	JOIN tracks t ON ii.TrackId = t.TrackId
	JOIN genres g ON t.GenreId = g.GenreId 
GROUP BY Country, t.GenreId
)
GROUP BY Country ;
--

	/* ======================== */
	
	/*=== Customers analysis ===*/


--Numbers of customers by country
SELECT country, count(Country) AS Num
FROM customers c 
GROUP BY country
ORDER BY Num DESC;
--

--Customers ranking by purchase amount 
SELECT DISTINCT 
	c.FirstName ||' '|| c.LastName AS CustomerName,
	c.Country,
	count(i.InvoiceId) AS Purchases,
	ROUND(AVG(i.Total),2) AS AvgTot,
	SUM(Total) AS Total
FROM 
	invoices i 
JOIN customers c ON
	i.CustomerId = c.CustomerId 
GROUP BY
	i.CustomerId
ORDER BY
	AvgTot DESC;
--

--#1 customers for each country by amount spent
WITH bestCustomers AS(
SELECT  
	c.FirstName ||' '|| c.LastName AS CustomerName,
	c.Country,
	SUM(Total) AS Total,
	DENSE_RANK() OVER (PARTITION BY c.Country ORDER BY SUM(Total))  as Ranking
FROM 
	invoices i 
JOIN customers c ON
	i.CustomerId = c.CustomerId 
GROUP BY
	i.CustomerId
)
SELECT CustomerName, country, Total FROM bestCustomers WHERE Ranking = 1;
--

--Employees best clients
WITH Customersranking AS(
SELECT
	e.LastName AS Employee,
	c.LastName AS Customer,
	SUM(i.Total) AS AmountSpent,
	DENSE_RANK() OVER (PARTITION BY e.LastName  ORDER BY SUM(i.Total) DESC) AS Ranking 
FROM employees e 
JOIN customers c ON e.EmployeeId = c.SupportRepId 
JOIN invoices i ON c.CustomerId = i.CustomerId 
GROUP BY Employee, Customer
)SELECT Employee, Customer, AmountSpent FROM Customersranking WHERE Ranking = 1;
--


	/* ===================== */

	/* ===Tracks analysis=== */


--Number of purchase for each tracks
SELECT
	t.TrackId,
	t.Name,
	count(ii.TrackId) AS UnitsSold
FROM tracks t
LEFT JOIN invoice_items ii ON t.TrackId = ii.TrackId 
GROUP BY t.TrackId
ORDER BY UnitsSold DESC;
--

--Number of track by genre
SELECT g.Name AS Genre, COUNT(g.Name) AS GenreCount
from tracks t 
JOIN genres g ON t.GenreId = g.GenreId 
GROUP BY Genre;
--

--Tracks lengths w/ #unitssold and genre
SELECT
	t.TrackId,
	t.Name,
	count(ii.TrackId) AS UnitsSold,
	t.Milliseconds / 1000 AS Lenght_Seconds,
	g.Name AS Genre
FROM tracks t
LEFT JOIN invoice_items ii ON t.TrackId = ii.TrackId 
JOIN genres g ON t.GenreId = g.GenreId
GROUP BY t.TrackId
ORDER BY UnitsSold DESC;
--

--Protected vs. non-protected media types popularity
SELECT mt.Name, count(DISTINCT t.TrackId) AS Uniquetrack, count(t.TrackId) AS totalTrack
FROM invoice_items ii 
JOIN tracks t ON ii.TrackId = t.TrackId 
JOIN media_types mt ON t.MediaTypeId = mt.MediaTypeId
GROUP BY mt.Name;
--

-- Numbers of track in each playlists
SELECT 
	p.Name,
	COUNT(DISTINCT pt.TrackId) AS Qt
FROM playlist_track pt 
JOIN playlists p ON pt.PlaylistId = p.PlaylistId
GROUP BY p.Name
ORDER BY Qt DESC;
--

-- #1 artist in each playlist w/ numbers of tracks
WITH tempo AS (
SELECT 
	pt.PlaylistId AS Playlist,
	a2.Name AS Name,
	count(a2.Name) AS Countt,
	RANK () OVER (PARTITION BY pt.PlaylistId ORDER BY count(a2.Name) DESC) AS Ranking
FROM 
	tracks t 
JOIN albums a ON t.AlbumId = a.AlbumId 
JOIN artists a2 ON a.ArtistId = a2.ArtistId
JOIN playlist_track pt ON t.TrackId = pt.TrackId
GROUP BY pt.PlaylistId , a2.Name 
HAVING 
	pt.PlaylistId <> 8
)SELECT 
	Playlist,
	CASE WHEN Countt = 1 THEN 'Multiple Artists' ELSE Name END AS Name,
	Countt
FROM tempo
GROUP BY Playlist
HAVING Ranking = 1;
--



	/* ========================= */
	/* === Business Analysis === */

--Yearly Income
SELECT DISTINCT	
	STRFTIME('%Y', i.InvoiceDate) AS InvYear,
	count(ii.TrackId) AS TracksSold, 
	SUM(ii.UnitPrice) AS Income 
FROM 
	invoices i
JOIN invoice_items ii ON 
	i.InvoiceId = ii.InvoiceId
JOIN tracks t ON
	ii.TrackId = t.TrackId 
GROUP BY InvYear;
--

--Best Selling Genre
SELECT
	g.Name,
	count(ii.Quantity) AS UnitSold,
	SUM(ii.UnitPrice) AS Income,
	ROUND(CAST(count(ii.Quantity) as float) / (SELECT SUM(ii2.Quantity) FROM invoice_items ii2) *100,2) AS Pct
FROM 
	invoice_items ii
	JOIN invoices i ON 	ii.InvoiceId = i.InvoiceId 
	JOIN tracks t ON ii.TrackId = t.TrackId
	JOIN genres g ON t.GenreId = g.GenreId 
GROUP BY
	t.GenreId
ORDER BY
	Income DESC;
--

--Best Selling Artists
SELECT
	a2.Name,
	count(ii.Quantity) AS UnitSold,
	SUM(ii.UnitPrice) AS Income
FROM 
	invoice_items ii
	JOIN invoices i ON 	ii.InvoiceId = i.InvoiceId 
	JOIN tracks t ON ii.TrackId = t.TrackId
	JOIN albums a ON t.AlbumId = a.AlbumId 
	JOIN artists a2 ON a.ArtistId = a2.ArtistId 
GROUP BY
	a2.Name
ORDER BY
	Income DESC;
--

--Country Income Ranking
SELECT DISTINCT 
	i.BillingCountry AS Country,
	SUM(ii.Quantity) AS TracksSold,
	SUM(ii.UnitPrice) AS Income,
	ROUND(CAST(count(ii.Quantity) as float) / (SELECT SUM(ii2.Quantity) FROM invoice_items ii2) *100,2) AS Pct
FROM 
	invoices i
	JOIN invoice_items ii ON i.InvoiceId = ii.InvoiceId
	JOIN tracks t ON ii.TrackId = t.TrackId
GROUP BY Country
ORDER BY Income DESC;
--

--Revenue per Country per Year per Genre
SELECT 
	i.BillingCountry AS Country,
	STRFTIME('%Y', i.InvoiceDate) AS InvYear,
	g.Name AS Genre,
	SUM(ii.Quantity) AS QtSold,
	SUM(ii.UnitPrice) AS Income
FROM
	invoice_items ii
JOIN invoices i ON ii.InvoiceId = i.InvoiceId
JOIN tracks t ON ii.TrackId = t.TrackId
JOIN genres g ON t.GenreId = g.GenreId 
GROUP BY 
	Country, InvYear, t.GenreId;
--

--How many tracks have been purchased vs not purchased? / Why so many unsold track and what to do ?
SELECT
	COUNT(DISTINCT TrackId) AS UniqueTracks_Total,
	(
		SELECT COUNT(DISTINCT t.TrackId)
		FROM tracks t 
		LEFT JOIN invoice_items ii ON t.TrackId = ii.TrackId
		WHERE ii.InvoiceId is null
		ORDER BY ii.InvoiceId
	) AS UniqueTracks_NotPurchased ,
	(
		SELECT COUNT(DISTINCT t.TrackId)
		FROM tracks t 
		LEFT JOIN invoice_items ii ON t.TrackId = ii.TrackId
		WHERE ii.InvoiceId is not null
		ORDER BY ii.InvoiceId
	) AS UniqueTracks_Purchased 
FROM (
	SELECT t.TrackId, ii.InvoiceId 
	FROM tracks t 
	LEFT JOIN invoice_items ii ON t.TrackId = ii.TrackId
);
--

--Numbers of customers and revenues by Employees
SELECT
	e.LastName ||' '||e.FirstName AS SupportName,
	count(DISTINCT c.CustomerId) AS Customers,
	date() - STRFTIME('%Y', e.HireDate) AS YearsActive,
	SUM(i.Total) AS Revenue
FROM 
	customers c 
JOIN employees e ON c.SupportRepId = e.EmployeeId 
JOIN invoices i ON c.CustomerId = i.CustomerId 
GROUP by 
	SupportName
ORDER BY 
	Revenue DESC;
--

--Employees benefit per year (No invoices between the hiring date and 2009)
SELECT
	e.LastName AS Employee,
	STRFTIME('%Y', i.InvoiceDate) AS InvYear,
	SUM(i.Total) AS SalesAmount
FROM employees e 
JOIN customers c ON e.EmployeeId = c.SupportRepId 
JOIN invoices i ON c.CustomerId = i.CustomerId 
GROUP BY Employee, InvYear;
--

	/* ============ */
	/* === MISC=== */

--HR Hierarchy
WITH tempo AS (
	SELECT EmployeeId , LastName , 1 AS niv,
	null AS Rank_1,
	null AS Rank_2
	FROM employees 
	WHERE ReportsTo is null
UNION ALL
	SELECT e.EmployeeId , e.LastName , niv +1,
	CASE WHEN niv = 1 THEN t.LastName ELSE t.Rank_1 END AS Rank_1,
	CASE WHEN niv = 2 THEN t.LastName ELSE t.Rank_2  END AS Rank_2
	FROM tempo t
	JOIN employees e ON t.EmployeeId = e.ReportsTo 
)SELECT * from tempo;
--


	/* ============================ */

	/* === Correlation Analysis === */

-- WIP


/* ======--#END#--======== */

