-- The raw data used in this project has come from Our World in Data and is open access under the Creative Commons BY license.
-- The purpose of this project is to perform Exploratory Data Analysis of Coronavirus deaths and vaccinations in Microsof SQL Server Management Studio using SQL.
-- The data will then be visualized in Tableau.


--Select Data that we are going to be using

SELECT *
FROM [Portfolio Project]..Covid_Deaths
ORDER BY 3,4

SELECT *
FROM [Portfolio Project]..Covid_Vaccinations
ORDER BY 3,4

--Lets take a look at Covid_Deaths

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


-- Lets add vaccinations
-- Joining our two databases
-- Covid_Deaths is now dea
-- Covid_Vaccinations is now vac

-- Looking at total population vs vaccination and add a new column to see a rolling vaccinated count

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as Rolling_Vaccinated_Count
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- We can also add in a rolling percent column, however, we cannot use a newly created column

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location, dea.date) as Rolling_Vaccinated_Count
	--, (Rolling_Vaccinated_Count/population)*100
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Using a Common Table Expression, we can calculate our rolling percent column

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

-- We can also utilize a Temporary Table to show the same as above
-- DROP Table if has been added to allow us to execute the query multiple times or add changes

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

-- Creating view to store data for later
-- Queries will be exported to Tableau for visualization
-- Because Tableau public is being used, only an example table is made
-- Tableau public does not connect directly to MSSMS
-- Tables will be saved as .csv and imported into Tableau public

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