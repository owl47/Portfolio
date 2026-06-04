SELECT SUM(cast(new_cases AS signed)) as Total_Cases, SUM(cast(new_deaths AS signed)) as Total_Deaths, SUM(cast(new_deaths AS SIGNED))/NULLIF(SUM(CAST(new_cases AS signed)),0) * 100
as Death_Percentage
FROM coviddeaths
WHERE continent IS NOT NULL AND TRIM(continent) != '';


SELECT location,  SUM(CAST(new_deaths AS SIGNED)) AS total_death_count
FROM coviddeaths
WHERE (continent IS NULL OR continent = '')
  AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC;


Select Location, Population, max(total_cases) as highest_infection_count, Max((Total_cases/Population)) * 100 as Population_infection_rate
from coviddeaths
-- where continent is not null
Group by population, Location
order by Population_infection_rate desc

Select Location, Population, date,  max(total_cases) as highest_infection_count, Population, Max((Total_cases/Population)) * 100 as Population_infection_rate
from coviddeaths
Group by Location, Population, date
order by Population_infection_rate desc