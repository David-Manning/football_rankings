# Data download

# Load libraries
library(tidyverse)
library(readbulk)
library(data.table)

# Load data
country_list <- c("ARG", "AUT", "BRA", "CHN", "DNK", "FIN", "IRL", "JPN", "JPN", "MEX", "NOR", "POL", "ROM", "RUS", "SWE", "SWZ", "USA")
raw_data_folder <- "raw_data/"

df_football_country <- data.frame()
for(i in country_list)
{
	df_football_country <- read.csv(paste0("https://www.football-data.co.uk/new/", i,".csv"), stringsAsFactors = FALSE) %>%
		mutate_all(as.character) %>%
		bind_rows(df_football_country)
}

df_football_country %>%
	select(Country, League, Season, Date, Time, Home, Away, HG, AG, Res) %>%
	rename(country = Country,
		   league = League,
		   season = Season,
		   date = Date,
		   time = Time,
		   home_team = Home,
		   away_team = Away,
		   home_goals = HG,
		   away_goals = AG,
		   result = Res) %>%
	filter(!is.na(home_goals), !is.na(away_goals)) %>%
	mutate(date = as.Date(date, "%d/%m/%Y"),
		   year = as.numeric(format(date, "%Y")),
		   month = as.numeric(format(date, "%m")),
		   day = as.numeric(format(date, "%d")),
		   hour = as.numeric(substr(str_trim(time), 1, 2)),
		   minute = as.numeric(substr(str_trim(time), 4, 5)),
		   country = str_trim(country),
		   home_team = str_trim(home_team),
		   away_team = str_trim(away_team),
		   league = str_trim(league)) %>%
	fwrite("cleaned_data/new_leagues.csv")




