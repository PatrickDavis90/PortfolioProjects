--SELECT *
--FROM [Portfolio Project]..Covid_Deaths
--WHERE continent is not null
--ORDER BY 3,4


--Select Data that we are going to be using
--SELECT *
--FROM [Portfolio Project]..Covid_Deaths
--ORDER BY 3,4

SELECT continent, location, CONVERT(varchar, date, 102) AS [date], total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not null
ORDER BY 1,2

-- United States
-- This shows the likelihood of dying if you contract covid as well as the percentage of population that contracted covid

SELECT continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage, (total_cases/population)*100 AS Covid_Infection_Percentage
FROM [Portfolio Project]..Covid_Deaths
WHERE location = 'united states'
ORDER BY 1,2


-- Lets look at the numbers by continent and location
-- Looking at total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at total cases vs population
-- shows what percentage of population got covid

SELECT continent, location, date, population, total_cases, (total_cases/population)*100 AS Covid_Infection_Percentage
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at countries with highest infection rate compared to population

SELECT continent, location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Covid_Infection_Percentage
FROM [Portfolio Project]..Covid_Deaths
GROUP BY Location, Population, continent
ORDER BY Covid_Infection_Percentage DESC


-- Showing countries with the highest death count per population

SELECT continent, location, MAX(CAST(Total_Deaths as int)) AS Total_Death_Count
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not null
GROUP BY Location, Population, continent
ORDER BY Total_Death_Count DESC

-- Breaking things down by continent
-- Showing the continents with highest death count

SELECT continent, MAX(CAST(Total_Deaths as int)) AS Total_Death_Count
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not null
GROUP BY continent
ORDER BY Total_Death_Count DESC

--Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Joining our two databases.
-- Covid_Deaths is now dea
-- Covid_Vaccinations is now vac

-- Looking at total population vs vaccination


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as Rolling_Vaccinated_Count
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as Rolling_Vaccinated_Count
	--, (Rolling_Vaccinated_Count/population)*100
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Use CTE

With PopvsVac (continent, location, date, population, new_vaccinations, Rolling_Vaccinated_Count)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as Rolling_Vaccinated_Count
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (Rolling_Vaccinated_Count/population)*100
FROM PopvsVac

--Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinatedCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingVaccinatedCount
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

SELECT *, (RollingVaccinatedCount/population)*100
FROM #PercentPopulationVaccinated

--Creating view to store data for later

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as Rolling_Vaccinated_Count
	--, (Rolling_Vaccinated_Count/population)*100
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3