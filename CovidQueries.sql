SELECT * FROM CovidDeath$

SELECT * FROM CovidVaccination$



SELECT location, date, total_cases,new_cases, total_deaths, population_density
FROM CovidDeath$
WHERE continent is not null
order by 1,2


-- Location at Total Cases vs Total Deaths at specific Nation

SELECT location, date, total_cases, total_deaths,
ROUND((cast(total_deaths as float)  /cast(total_cases as float) )*100 , 2) as DeathPercentage
FROM CovidDeath$
WHERE location like '%Indonesia%' and continent is not null
order by 1,2

-- Percentage Ratio of Diagnosed with COVID-19
SELECT location, date, total_cases, population_density,
ROUND((cast(total_cases as float)  /cast(population_density as float) )*100 , 2) as Covided
FROM CovidDeath$
WHERE continent is not null
order by 1,2

--Highest Infection


SELECT continent, population_density, MAX(total_cases) as HighestInfection, 
MAX(ROUND((cast(total_cases as float)  /cast(population_density as float) )*100 , 2)) as Covided
FROM CovidDeath$
WHERE continent is not null
GROUP BY continent, population_density
order by Covided DESC

-- global infection

SELECT SUM(new_cases) as total_case, SUM(new_deaths) as total_death,
       CASE WHEN SUM(new_cases) = 0 THEN 0 ELSE SUM(new_deaths)/SUM(new_cases)*100 END as DeathPercentage
FROM CovidDeath$
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- joining between coviddeath table with covidvaccinated table

select death.continent, death.location, death.population_density, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by death.location, death.continent, death.date) 
as RollingPeopleVaccinated
from CovidDeath$ death
join CovidVaccination$ vac
on death.location = vac.location
and death.date = vac.date
WHERE death.continent is not null and vac.new_vaccinations is not null and death.population_density is not null
ORDER BY 1,2,3

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated, RowNum)
as
(
select death.continent, death.location, death.date, death.population_density, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by death.location, death.continent, death.date) 
as RollingPeopleVaccinated,
ROW_NUMBER() over (order by death.location, death.date) as RowNum
from CovidDeath$ death
join CovidVaccination$ vac
on death.location = vac.location
and death.date = vac.date
WHERE death.continent is not null
)

SELECT *, ROUND((RollingPeopleVaccinated/Population)*100, 2)
FROM PopvsVac
ORDER BY RowNum


-- temp table
drop table if exists #PercentPopulationVaccinated

create table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population_density numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated

select death.continent, death.location, death.date, death.population_density, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by death.location, death.continent, death.date) 
as RollingPeopleVaccinated
from CovidDeath$ death
join CovidVaccination$ vac
on death.location = vac.location
and death.date = vac.date
WHERE death.continent is not null and vac.new_vaccinations is not null and death.population_density is not null
ORDER BY 1,2,3

SELECT *, ROUND((RollingPeopleVaccinated/NULLIF(population_density, 0))*100, 2)
FROM #PercentPopulationVaccinated

