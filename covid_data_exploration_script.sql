/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Check the full covid_deaths table, ordered by location and date
-- Noticed continent column has several null values and location column also refers to continent, using not nulls to avoid duplicates
SELECT *
FROM covid_deaths
WHERE continent is not null 
ORDER BY 3,4


-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent is not null 
ORDER BY 1,2 -- in this case location and date become the 1 and 2 columns


-- Total Cases vs Total Deaths
-- Ordered by country and date
-- Using NULLIF function to avoid divide by zero errors

SELECT location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases, 0))*100 AS death_percentage
FROM covid_deaths
-- WHERE location = 'Portugal'
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, population, total_cases, (NULLIF(total_cases, 0)/NULLIF(population, 0))*100 AS percent_population_infected
FROM covid_deaths
--WHERE location = 'Portugal'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as highest_infection_count,  MAX(NULLIF(total_cases, 0)/NULLIF(population, 0))*100 as percent_population_infected
FROM covid_deaths
--WHERE location = 'Portugal'
GROUP BY location, population
ORDER BY percent_population_infected DESC


-- Countries with Highest Death Count

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent is not null -- null data was grouping entire continents and we want the country information is this query
  -- AND location = 'Portugal'
GROUP BY location
ORDER BY total_death_count DESC



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
-- Query shows inacurate results for continent total death count, several countries missing

SELECT continent, MAX(total_deaths) AS total_death_count
FROM covid_deaths
--WHERE location = 'Portugal'
WHERE continent is not null 
GROUP BY continent
ORDER BY total_death_count DESC


-- Showing contintents with the highest death count
-- Correct values now showing, location column selected instead of continent, location refers to continent in cases where continent is null

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent is not null 
GROUP BY location
ORDER BY total_death_count DESC


-- Worldwide Numbers

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM covid_deaths
--WHERE location = 'Portugal'
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2



-- Total Population vs Vaccinations 
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
  --, (rolling_people_vaccinated/population)*100 AS percent_vaccinated doesn't work because we can't select a column we just created. We need a TEMP table or CTE for this.
FROM covid_deaths dea
JOIN covid_vaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- Using CTE to perform Calculation on Partition By in previous query

WITH vac_pop_percent
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3
)
SELECT *, 
  (rolling_people_vaccinated/NULLIF(population, 0))*100 AS people_vacc_percent
FROM vac_pop_percent




-- Using Temp Table to perform Calculation on Partition By in previous query

-- Using a Temp Table to perform calculations on Partition By from a previous query

DROP TABLE IF EXISTS percent_population_vaccinated -- Important to avoid wasting server resources
CREATE TABLE percent_population_vaccinated
(
    continent varchar(255),
    location varchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    rolling_people_vaccinated numeric
)

INSERT INTO percent_population_vaccinated
SELECT 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
  covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3

SELECT 
  *, 
  (rolling_people_vaccinated/NULLIF(population, 0))*100 AS percent_people_vacc
FROM 
  percent_population_vaccinated




-- Creating View to store data for later visualizations

CREATE VIEW percent_population_vaccinated as
SELECT 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
  covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
