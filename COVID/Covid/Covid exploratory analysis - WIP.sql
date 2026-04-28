Select *
from coviddeaths
where continent is not null
order by 3,4

-- Looking at total cases Vs. total deaths
Select Location, date, total_cases, new_cases, total_deaths, population
from coviddeaths
order by 1, 2


-- Probability of death by Covid in a selected location
Select Location, date, total_cases, total_deaths, (Total_deaths/Total_cases) * 100 as Death_Rate
from coviddeaths
Where location = 'Africa'
and
continent is not null
order by 4 Desc


-- Total Cases Vs. Population
Select Location, date, total_cases, Population, (Total_cases/Population) * 100 as Population_infection_rate
from coviddeaths
Where location = 'Africa'
order by 2, 4


-- Countries with highest infection rate Vs. population
Select Location, max(total_cases) as highest_infection_count, Population, Max((Total_cases/Population)) * 100 as Population_infection_rate
from coviddeaths
where continent is not null
Group by population, Location
order by Population_infection_rate desc


-- Countries with highest death count Vs. population
select Location, max(cast(total_deaths AS unsigned)) as total_death_count
from coviddeaths
where TRIM(continent) != '' AND continent IS NOT NULL
group by Location
order by total_death_count desc

-- Continent with highest death count Vs. population
Select continent,  sum(new_deaths)
from coviddeaths
where continent!=''
group by continent;

-- Global numbers
Select date, Sum(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths, SUM(new_deaths)/SUM(new_cases) * 100 as Death_Percentage
from coviddeaths
where continent is not null
Group by date
order by 1,2


-- Total Population Vs. Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as Rollingpeoplevacc
From Coviddeaths dea
join covidvacc vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE

With PopVsVac (continent, location, date, population, new_vaccinations, Rollingpeoplevacc)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as Rollingpeoplevacc
From Coviddeaths dea
join covidvacc vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
Select *, (Rollingpeoplevacc/population) * 100
From PopVsVaC

-- Temp view for Visualization for Tableau 

Create View PercentpopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as Rollingpeoplevacc
From Coviddeaths dea
join covidvacc vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
-- order by 2,3

Select *
From PercentpopulationVaccinated