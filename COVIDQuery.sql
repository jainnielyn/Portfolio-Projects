/*

Exploration of COVID Data with SQL

Data from: https://ourworldindata.org/covid-deaths
Used: CAST, CONVERT, PARTITION BY, CTE, TEMP TABLE
Tableau visualization: https://public.tableau.com/app/profile/jainnie/viz/COVIDexploration/Dashboard1

Part 1. Exploration of COVID infections and deaths
Part 2. Exploration of COVID vaccinations
Part 3. Queries used for Tableau (manually exported)
*/

Select *
From PortfolioProject..CovidDeaths

Select *
From PortfolioProject..CovidVaccinations

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


-- Part 1. Exploring COVID cases and deaths

-- Looking at cases and deaths
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
--and location like '%states%'
Order by 1, 2


--------------------------------------------------------------------------------------------------------------------------


-- Looking at each country's death percent compared with cases
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2


--------------------------------------------------------------------------------------------------------------------------


-- Looking at each country's maximum death percent per month
Select location, year(cast(date as date)) as Yr, month(cast(date as date)) as Mo, MAX((total_deaths/total_cases)*100) as DeathRate, population
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, year(cast(date as date)), month(cast(date as date)), population
Order by 1, 2, 3


--------------------------------------------------------------------------------------------------------------------------


-- Looking at the percentage of the population who got COVID
Select location, date, population, total_cases, (total_cases/population)*100 as InfectedPercent
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
Order by 1, 2


--------------------------------------------------------------------------------------------------------------------------


-- Looking at each country's highest infected percentage
Select location, population, MAX(total_cases) as HighestCases, MAX((total_cases/population))*100 as InfectedPercent
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Order by 4 DESC


--------------------------------------------------------------------------------------------------------------------------


-- Looking at each country's highest deaths
Select location, MAX(CAST(total_deaths as int)) as HighestDeaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by HighestDeaths DESC


--------------------------------------------------------------------------------------------------------------------------


-- Looking at each country's highest deaths compared with population
Select location, population, MAX(CAST(total_deaths as int)) as HighestDeaths, MAX((CAST(total_deaths as int)/population))*100 as DeathPercentPopulation
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Order by population DESC          -- change to DeathPercentPopulation to view by death percent 


--------------------------------------------------------------------------------------------------------------------------


-- Looking at the highest death count by continent
Select continent, MAX(CAST(total_deaths as int)) as HighestDeaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order by HighestDeaths DESC


--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

-- GLOBAL NUMBERS


-- Global cases, deaths and death percent by date
Select date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, (SUM(CAST(new_deaths as int))/SUM(new_cases))*100 as DeathPercent
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1 ASC

-- Total cases, deaths and death percent
Select SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, (SUM(CAST(new_deaths as int))/SUM(new_cases))*100 as DeathPercent
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1 ASC


--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


-- Part 2. Exploring COVID vaccinations

-- Looking at each country's vaccinations with a rolling count
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location 
	and cd.date = cv.date
Where cd.continent is not null
Order by 2, 3


--------------------------------------------------------------------------------------------------------------------------


-- Adding percent of population vaccinated to above
-- Method 1. Using CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as
(
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location 
	and cd.date = cv.date
Where cd.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100 as PercentPopVaccinated
From PopvsVac


--------------------------------------------------------------------------------------------------------------------------


-- Method 2. Using temp table
Drop table if exists #RollingPeopleVaccinated
Create Table #RollingPeopleVaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date date,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #RollingPeopleVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location 
	and cd.date = cv.date
Where cd.continent is not null

Select *, (RollingPeopleVaccinated/population)*100 as PercentPopVaccinated
From #RollingPeopleVaccinated
Order by 2, 3


--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


/*
Queries used for Tableau Project
*/


-- Global numbers of cases, deaths and percentage

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2


-- Death count by continent

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
and location not like '%income%'
Group by location
order by TotalDeathCount desc


-- Each country's highest infection count and percentage of population infected

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Each country's cases and infected percentage

Select Location, Population,date, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, date, total_cases
order by PercentPopulationInfected desc
