use Portfolio1
select * from CovidDeaths$
WHERE continent IS NOT NULL

-- Select data to be used

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1,2

-- Total Cases vs Total deaths (% of total death per total case)
--Shows likelihood of death if you contract covid
SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS 'Deaths%'
FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2

--Total cases vs population
-- Shows what % of population has covid
SELECT Location, Date, total_cases, population, (total_cases/population) * 100 AS 'Population Infected %'
FROM CovidDeaths$
--WHERE location = 'United States' AND continent IS NOT NULL
ORDER BY 1,2

-- Countires with highest infection rates compared to population
SELECT Location, population, MAX(total_cases) as "Highest Number of Infection", MAX((total_cases/population)) * 100 AS 'Highest Population Infected %'
FROM CovidDeaths$
--WHERE location = 'United States'
GROUP BY location, population
ORDER BY 4 DESC

--Countries with the highest death count per population
-- Casting is done here due to the data type of the total_death column when done with an aggregation.
-- Some conitinents are NULL and have the continent data in the location date instead

SELECT Location, population, MAX(CAST(total_deaths as int)) as "Highest Death Count", MAX((total_deaths/population)) * 100 AS 'Highest Death Count %'
FROM CovidDeaths$
--WHERE location = 'United States'
WHERE continent IS NOT NULL -- Some conitinents are NULL and have the continent data in the location date instead
GROUP BY location, population
ORDER BY 3 DESC

-- Grouping by Continent to see the highest death Count
--Some continents are null

SELECT continent, --population, 
MAX(CAST(total_deaths as int)) as "Highest Death Count by Continent"
FROM CovidDeaths$
--WHERE location = 'United States'
WHERE continent IS NULL -- Some conitinents are NULL and have the continent data in the location date instead
GROUP BY continent--, population
ORDER BY 2 DESC

/* Continent with the highest death count
SELECT location, MAX(CAST(total_deaths as int)) as "Highest Death Count by Continent"
FROM CovidDeaths$
WHERE continent IS NULL --AND location <> 'world' -- Some conitinents are NULL and have the continent data in the location date instead
GROUP BY location
ORDER BY 2 DESC
*/

-- Grouping by Continent to see the highest death Count

SELECT continent, MAX(CAST(total_deaths as int)) as "Highest Death Count by Continent"
FROM CovidDeaths$
WHERE continent IS NOT NULL --AND location <> 'world' -- Some conitinents are NULL and have the continent data in the location date instead
GROUP BY continent
ORDER BY 2 DESC

-- Global Numbers, total cases each day across the world
SELECT Date, SUM(new_cases) as "Total Cases Each day", SUM(CAST (new_deaths as int)) as "Total Deaths Each day", 
		(SUM(CAST (new_deaths as int))/SUM(new_cases)) * 100 AS "Global Death %"
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

---- Overall numbers
SELECT SUM(new_cases) as "Total Cases Each day", SUM(CAST (new_deaths as int)) as "Total Deaths Each day", 
		(SUM(CAST (new_deaths as int))/SUM(new_cases)) * 100 AS "Global Death %"
FROM CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


--Finding the %of people vaccinated
-----Using the covid vaccinations table, JOINS

SELECT * FROM CovidVaccinations$
order by location, date

SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location) as "Total Vaccinations by Location", -- Sums up all new vaccine by just the location and returns the sum to all rows
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as "Rolling Total People Vaccinated", --sums up to the number and retain that value
v.total_vaccinations -- is same as the calculated one using partition
FROM CovidDeaths$ as d
JOIN CovidVaccinations$ as v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date

--Using CTE
-- Get the % of people vaccinated
WITH pvs (continent, location, date, population, new_vaccinations,"Total Vaccinations by Location", "Rolling Total People Vaccinated", total_vaccinations)
AS
(
SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location) as "Total Vaccinations by Location", -- Sums up all new vaccine by just the location and returns the sum to all rows
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as "Rolling Total People Vaccinated", --sums up to the number and retain that value
v.total_vaccinations -- is same as the calculated one using partition
FROM CovidDeaths$ as d
JOIN CovidVaccinations$ as v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location, d.date
)

----- OR using derived tableas/ subquery

SELECT *, ("Rolling Total People Vaccinated" / population) * 100 as "% of People Vaccinated"
FROM (
SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location) as "Total Vaccinations by Location", -- Sums up all new vaccine by just the location and returns the sum to all rows
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as "Rolling Total People Vaccinated", --sums up to the number and retain that value
v.total_vaccinations -- is same as the calculated one using partition
FROM CovidDeaths$ as d
JOIN CovidVaccinations$ as v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location, d.date
) pvs

-- OR
------------------------------------------------------------------------
--Using TEMP table
-- Check why mine did not work

/* DROP TABLE IF EXISTS #percentagevaccinated
CREATE TABLE #percentagevaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
TotalVaccinationsbyLocation numeric,
RollingTotalPeopleVaccinated numeric,
total_vaccinations numeric
)

INSERT INTO #percentagevaccinated
SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location) as TotalVaccinationsbyLocation, -- Sums up all new vaccine by just the location and returns the sum to all rows
SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingTotalPeopleVaccinated, --sums up to the number and retain that value
v.total_vaccinations -- is same as the calculated one using partition
FROM CovidDeaths$ as d
JOIN CovidVaccinations$ as v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location, d.date
*/

-- Using Temp Table
-----------------------------------------------
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

SELECT *, (RollingPeopleVaccinated / Population) * 100 as "% of People Vaccinated"
FROM #PercentPopulationVaccinated

-------------------------------------------------------------
-- Creating a view to store data for later visualisations

CREATE VIEW PercentPopulationVaccinated

AS 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

SELECT * FROM PercentPopulationVaccinated