--Show the data we will use for this table
select location, date, total_cases, cast(new_cases as integer), total_deaths, population
from dbo.covid_death
where continent is not NULL
order by location,date

-- total_cases vs total_deaths
-- show the percentage of dying if you got covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
from dbo.covid_death
where continent is not NULL
order by location, date

-- total_case vs population
-- show the percentage of population infected with covid
select location, date, population, (total_cases/population)*100 as infected_rate
from dbo.covid_death
order by location, date 

-- show countries with highest Infection Rate compared to Population
select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From dbo.covid_death
Group by Location, Population
order by PercentPopulationInfected desc

-- shows continent with highest Death Counts
select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.covid_death
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- show the number of death and cases each day
select date, sum(cast(new_cases as int)) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
(sum(cast(new_deaths as int)) / sum(cast(new_cases as int)))*100 as death_percentage
from dbo.covid_death
group by date 
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated_people,
from dbo.covid_death dea
join dbo.covid_vaccination vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated_people,
from dbo.covid_death dea
    join dbo.covid_vaccination vac on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3
)

--Tempt table
Drop table if exists #percent_population_vaccinated
Create table #percent_population_vaccinated(
    continent NVARCHAR(250),
    location NVARCHAR(250),
    date DATETIME,
    population numeric,
    new_vaccination numeric,
    rolling_people_vaccinated numeric, 

)

INSERT INTO #percent_population_vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated_people,
from dbo.covid_death dea
    join dbo.covid_vaccination vac on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.covid_death dea
Join dbo.covid_vaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
