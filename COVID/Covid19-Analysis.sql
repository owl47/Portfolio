-- Exploring the data
Select *
from coviddeaths
where continent is not null
order by 3,4

-- Data used
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not NULL
order by 1, 2


-- Looking at total cases Vs. total deaths
SELECT Location, date, total_cases, new_cases, total_deaths, population
from coviddeaths
where Location like '%Egypt%'
and continent like '%Africa'
order by 1, 2


SELECT * FROM coviddeaths WHERE Location LIKE '%States%' LIMIT 10;


-- Probability of death by Covid in a selected location
-- How likely are you to die if you contract covid in your country
Select Location, date, total_cases, total_deaths, (Total_deaths/Total_cases) * 100 as Death_Rate
from coviddeaths
Where location = 'Africa'
and
continent is not null
order by 4 Desc


-- Total Cases Vs. Population
-- Population % infected with Covid
Select Location, date, total_cases, Population, (Total_cases/Population) * 100 as Population_infection_rate
from coviddeaths
Where location = 'Africa'
order by 2, 4


-- COUNTRIES with highest infection rate Vs. population
Select Location, max(total_cases) as highest_infection_count, Population, Max((Total_cases/Population)) * 100 as Population_infection_rate
from coviddeaths
where continent is not null
Group by population, Location
order by Population_infection_rate desc


-- COUNTRIES with highest death count Vs. population
select Location, max(cast(total_deaths AS unsigned)) as total_death_count
from coviddeaths
where TRIM(continent) != '' AND continent IS NOT NULL
group by Location
order by total_death_count desc

-- CONTINENT with highest death count Vs. population
Select continent,  sum(new_deaths)
from coviddeaths
where continent!=''
group by continent;

-- Global numbers
Select date, Sum(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0) * 100 as Death_Percentage
-- nullif for the days with no covid data, to avoid division by 0 error
from coviddeaths
where continent is not null
Group by date
order by 1,2


-- Total Population Vs. Vaccinations
-- Population % with 1 covid vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
-- Check for empty strings/nulls before CAST
SUM(
    CASE 
        WHEN vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL THEN 0 
        ELSE CAST(vac.new_vaccinations AS SIGNED) 
    END
) OVER (Partition by dea.location order by dea.location, dea.date) as Rollingpeoplevacc
From CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE to perform calculation on previous window function 

With PopVsVac (continent, location, date, population, new_vaccinations, Rollingpeoplevacc)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
-- Fixed to prevent the empty string / truncation error
SUM(
    CASE 
        WHEN vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL THEN 0 
        ELSE CAST(vac.new_vaccinations AS SIGNED) 
    END
) OVER (Partition by dea.location order by dea.location, dea.date) as Rollingpeoplevacc
From CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
)

Select *, (Rollingpeoplevacc / population) * 100 as PercentPeopleVaccinated
From PopVsVac;

-- Temp view for Visualization for Tableau 

Create View PercentpopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(
    CASE 
        WHEN vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL THEN 0 
        ELSE CAST(vac.new_vaccinations AS SIGNED) 
    END
) OVER (Partition by dea.location order by dea.location, dea.date) as Rollingpeoplevacc
From CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null; 

-- Explore the new view
Select *
From PercentpopulationVaccinated;




