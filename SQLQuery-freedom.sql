/*
Tidy Tuesday
Feb. 22, 2022
Freedom

Data exploration with SQL and Tableau
Used: CTE, Subqueries, CASE
Tableau visualization: https://public.tableau.com/app/profile/jainnie/viz/TidyTuesday-Freedom022222/Dashboard1

*/

--------------------------------------------------------------------------------------------------------------------------

-- Freedom status by continent, as at 2020

WITH CTE_ContinentStatus AS
(
Select Country, Status, Region_Name, COUNT(Country) OVER (Partition by Status, Region_name) as NumCountryCategory, 
COUNT(Country) OVER (Partition by Region_name) as NumCountriesContinent
From PortfolioProject.dbo.Freedom
Where year='2020'
)
Select *, (CAST(NumCountryCategory as numeric)/NumCountriesContinent)*100 as PercentFreeCategory
From CTE_ContinentStatus

--------------------------------------------------------------------------------------------------------------------------

-- the longest each country has been... free, partially and not
WITH CTECountryFreedomGroup (rownum, year, country, status, grp) as
(
SELECT ROW_NUMBER() OVER (order by country, year) as rownum, year, country, status, 
(ROW_NUMBER() OVER (order by country, year) - DENSE_RANK() OVER (PARTITION BY country, status order by year)) as grp
FROM PortfolioProject.dbo.Freedom
)
SELECT country, status, MAX(tbl.ct) as max_yrs
FROM (
SELECT country, status, count(grp) as ct
FROM CTECountryFreedomGroup 
GROUP BY country, status, grp ) as tbl
GROUP BY country, status
ORDER BY country

--------------------------------------------------------------------------------------------------------------------------

-- by category of freedom, what's the average civil liberty and political rights?
SELECT status, AVG(cl) as AvgCL, AVG(pr) as AvgPR
FROM PortfolioProject.dbo.Freedom
GROUP BY status

--------------------------------------------------------------------------------------------------------------------------

-- what is the trend, more or less freedom (for least developed countries)?
SELECT year, status, COUNT(CASE WHEN is_ldc = 1 THEN 1 END) as is_ldc
FROM PortfolioProject.dbo.Freedom
group by year, status
order by year asc, is_ldc desc

-- what is the trend overall?
SELECT year, status, COUNT(*) AS count, COUNT(CASE WHEN is_ldc = 1 THEN 1 END) as is_ldc
FROM PortfolioProject.dbo.Freedom
group by year, status
order by year asc
--------------------------------------------------------------------------------------------------------------------------