  SELECT *
  FROM PortfolioProject..covid_deaths

  SELECT *
  FROM PortfolioProject..covid_vaccinate
  ORDER BY 3

  ---Select Data that we are going to be using

  SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM portfolioProject..covid_deaths
  ORDER BY 1, 2

  -- Looking at Total Cases vs Total Deaths
  -- (in simple terms: This is the percentage of all those diagnosed to have it vs those who had it and actually died from it, rounded to 2 decimal places using the ROUND function)

 SELECT location, date, total_cases, total_deaths, ROUND(100*total_deaths/total_cases, 2) as DeathPercentage
  FROM portfolioProject..covid_deaths
  WHERE location = 'Canada' -- I'm interested in my country 'Canada'
  ORDER BY 1, 2

  --Total Cases vs Population
  -- This is another interesting factor to look at and it shows percentage of the population that were recorded to have gotten the virus. This allows government, policy makers, health workers/institutions, researcher and even individuals to make quality strategic and business dicisions regarding the safety of people, local economics etc.

SELECT location, date, total_cases, population, ROUND(100*total_cases/population, 2) as DeathPercentage
  FROM portfolioProject..covid_deaths
  WHERE continent is not null AND location = 'Canada' -- Again, I'm mostly interested in my country 'Canada'
  ORDER BY 1, 2

-- Countries with the highest infection Rate compared to their Population

SELECT location, population, MAX(total_cases) as MostCaseCount, MAX(ROUND(100*total_cases/population, 2)) as DeathPercentage
  FROM portfolioProject..covid_deaths
  WHERE continent is not null
  GROUP BY location, population
  ORDER BY 4 DESC

  -- Countries with the highest death count per Population
  -- Observe that the datatype for total_deaths column is nvarchar(255). If it is not converted or casted, it will return an order error. Cast to int. Also observe that some continent are presented as location and the number of countries in the dataset (233) are more than the global amount of countries (195). You may also have observed that when continents data is null, the location has the name of the continent. For this report, we may have to exclude such data using a where clause. haveI am also curious to see how the data ranks in the percentage of death by polulation so, I have included it as a calculated field.

  SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX(ROUND(100*total_deaths/population, 2)) as DeathPercentage
  FROM portfolioProject..covid_deaths
  WHERE continent is not null
  GROUP BY location
  ORDER BY 2 DESC


  -- STATISTICS BY CONTINENTS


  SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
  FROM portfolioProject..covid_deaths
  WHERE continent is null
  GROUP BY location
  ORDER BY HighestDeathCount DESC

  -- continents wtih the highest death count per population
  SELECT continent, MAX(cast(total_deaths as int)) as HighestDeathCount
  FROM portfolioProject..covid_deaths
  WHERE continent is not null
  GROUP BY continent
  ORDER BY HighestDeathCount DESC


  --GLOBAL NUMBERS

  --Death percentages globally.
  --We can also see the days with the highest number of deaths if we order by death
  SELECT date, SUM((new_cases)) as cases, SUM(cast(new_deaths as Int)) as death, (SUM(Cast(new_deaths as int))/SUM((new_cases)))*100 as DeathPercentage
  FROM portfolioProject..covid_deaths
  WHERE continent is not null
  GROUP BY date
  ORDER BY 3 DESC

  --Total global cases and death percentage
    SELECT SUM((new_cases)) as cases, SUM(cast(new_deaths as Int)) as death, (SUM(Cast(new_deaths as int))/SUM((new_cases)))*100 as DeathPercentage
  FROM portfolioProject..covid_deaths
  WHERE continent is not null
  --GROUP BY date
  ORDER BY 3 DESC


  ---<<VACCINATIONS>>

  --Perform join on both tables
    Select *
  FROM PortfolioProject..covid_deaths dea
  Join PortfolioProject..covid_vaccinate vac
	ON dea.location = vac.location
	and dea.date = vac.date


--Total Population vs Vaccinatiion
--I've added a rolling sum on the vaccination count and also rolling percentage of vaccination count per population.
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinated --, (RollingCountVaccinated/population)*100
FROM PortfolioProject..covid_deaths dea
Join PortfolioProject..covid_vaccinate vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE Common Table Expression, CTE, to make new calculated field with an calculation column

With PopvsVac (continent, location, date, population, new_vaccinations, RollingCountVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinated --, (RollingCountVaccinated/population)*100
FROM PortfolioProject..covid_deaths dea
Join PortfolioProject..covid_vaccinate vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)
SELECT *, (RollingCountVaccinated/population)*100
FROM PopvsVac
order by 2, 3


--TEMP TABLE to make new calculated field with an calculation column
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCountVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinated --, (RollingCountVaccinated/population)*100
FROM PortfolioProject..covid_deaths dea
Join PortfolioProject..covid_vaccinate vac
	ON dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2, 3


SELECT *, (RollingCountVaccinated/population)*100
FROM #PercentPopulationVaccinated



--CREATING VIEWS to store data for future visualizations

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingCountVaccinated --, (RollingCountVaccinated/population)*100
FROM PortfolioProject..covid_deaths dea
Join PortfolioProject..covid_vaccinate vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

SELECT *
From #PercentPopulationVaccinated