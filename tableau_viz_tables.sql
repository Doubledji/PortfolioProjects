/*
Queries used for Tableau Visualizations
*/

-- All of the tables used:
-- 1. Correct numbers for cases and deaths worldwide - includes "International"  Location


SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
--WHERE location = 'Portugal'
WHERE location = 'World'
--GROUP BY date
ORDER BY 1,2


 

-- 2. Total deaths by continent 
-- Some of these would provide duplicates that increase total cases and deaths, so lets remove them

SELECT continent, SUM(new_deaths) AS total_death_count
FROM covid_deaths
--WHERE location = 'Portugal'
WHERE continent is not null 
and location not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY continent
ORDER BY total_death_count DESC


-- 3. Percentage of infected population by location

SELECT location, population, MAX(total_cases) as highest_infection_count,  Max((total_cases/NULLIF(population, 0)))*100 AS percent_population_infected
FROM covid_deaths
--WHERE location = 'Portugal'
GROUP BY location, population
ORDER BY percent_population_infected DESC


-- 4. Percentage of infected population by country, removed wider geographic zones to avoid duplicates

SELECT location, population, date, MAX(total_cases) as highest_infection_count,  ROUND(MAX((total_cases/NULLIF(population, 0)))*100, 2) AS percent_population_infected
FROM covid_deaths
--WHERE location = 'Portugal'
WHERE location not in ('World', 'Europe','European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income', 'Africa', 'South America', 'North America', 'Oceania')
GROUP BY location, population, date
ORDER BY percent_population_infected DESC


-- 5. Number of people Vaccinated per country pop

SELECT dea.continent, dea.location, dea.date, dea.population, MAX(vac.total_vaccinations) as rolling_people_vaccinated
FROM covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
  AND dea.location not in ('World', 'Europe','European Union', 'International', 'Upper middle income', 'High income', 
  'Lower middle income', 'Low income', 'Asia', 'Africa', 'South America', 'North America', 'Oceania')
GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY 1,2,3




-- 5.1 From the View created in the previous script, lets grab the rolling_people_vaccinated for the vaccination percentage
-- For a Viz regarding total vaccinated people and vaccination percentage per country

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





-- 6. Total deaths per country by day
SELECT location, date, population, total_cases, total_deaths
FROM covid_deaths
--WHERE location = 'Portugal'
WHERE continent is not null
AND location not in ('World', 'Europe','European Union', 'International', 'Upper middle income', 'High income', 
  'Lower middle income', 'Low income', 'Asia', 'Africa', 'South America', 'North America', 'Oceania')
ORDER BY 1,2


-- 7. Total deaths by income
SELECT location, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(NULLIF(new_cases, 0))*100 AS death_percentage
FROM covid_deaths
--WHERE location = 'Portugal'
WHERE continent is not null
AND location in ('Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY 1,2

