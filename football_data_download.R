# Data download

# Load libraries
library(tidyverse)
library(readbulk)
library(data.table)
library(httr)
library(jsonlite)
library(arrow)

# Load data
country_list <- c("ARG", "AUT", "BRA", "CHN", "DNK", "FIN", "IRL", "JPN", "JPN", "MEX", "NOR", "POL", "ROM", "RUS", "SWE", "SWZ", "USA")


# Download data for leagues listed by country
df_football_country <- data.frame()
for(i in country_list)
{
	df_football_country <- read.csv(paste0("https://www.football-data.co.uk/new/", i,".csv"), stringsAsFactors = FALSE) %>%
		mutate_all(as.character) %>%
		bind_rows(df_football_country)
}

df_football_country <- df_football_country %>%
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
		   league = str_trim(league))



# Download data for leagues listed by season

# Create season codes from 1993-94 to 2024-25
start_years <- 1993:2024
end_years <- start_years + 1
df_season_codes <- tibble(start_year = start_years,
						  end_year = end_years,
						  code = paste0(substr(as.character(start_year), 3, 4), substr(as.character(end_year), 3, 4)),
						  description = paste0(start_year, "-", end_year))

# Download all seasons
df_football_season <- data.frame()

# Process each season
for (i in 1:nrow(df_season_codes))
{
	# Setup loop
	code <- df_season_codes$code[i]
	description <- df_season_codes$description[i]
	url <- paste0("https://www.football-data.co.uk/mmz4281/", code, "/data.zip")

	# Create temporary files for downloading and extracting
	temp_zip <- tempfile(fileext = ".zip")
	temp_dir <- tempfile()
	dir.create(temp_dir)

	# Download the file
	download.file(url, temp_zip, mode = "wb", quiet = TRUE)

	# Extract all files from the zip
	unzip(temp_zip, exdir = temp_dir)

	# List all CSV files in the extracted directory
	csv_files <- list.files(temp_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)

	# Process each CSV file
	for (csv_file in csv_files)
	{
		temp_data <- read.csv(csv_file, fileEncoding = "latin1", stringsAsFactors = FALSE) %>%
			mutate(season = description,
				   across(everything(), as.character))
		df_football_season <- bind_rows(df_football_season, temp_data)
	}

	# Clean up temporary files
	file.remove(temp_zip)
	unlink(temp_dir, recursive = TRUE)
}

df_football_season <- df_football_season %>%
	select(Div, Date, Time,  HomeTeam, AwayTeam, FTHG, FTAG, FTR, season) %>%
	filter(!is.na(FTHG), !is.na(FTAG), !is.na(Div)) %>%
	rename(division = Div,
		   date = Date,
		   time = Time,
		   home_team = HomeTeam,
		   away_team = AwayTeam,
		   home_goals = FTHG,
		   away_goals = FTAG,
		   result = FTR) %>%
	left_join(y = jsonlite::fromJSON("data/lookups/division_to_country_main_leagues.json"), by = join_by(division)) %>%
	mutate(date = str_trim(date),
		   day = as.numeric(str_sub(date, 1, 2)),
		   month = as.numeric(str_sub(date, 4, 5)),
		   year = case_when(nchar(date) == 8 & str_sub(date, 7, 7) == 9 ~ 1900 + as.numeric(str_sub(date, 7, 8)),
		   				 nchar(date) == 8 & str_sub(date, 7, 7) %in% c(0, 1, 2) ~ 2000 + as.numeric(str_sub(date, 7, 8)),
		   				 nchar(date) == 10 ~ as.numeric(str_sub(date, 7, 10))),
		   hour = as.numeric(str_sub(str_trim(time), 1, 2)),
		   minute = as.numeric(str_sub(str_sub(str_trim(time), 4, 5))),
		   date = as.Date(paste(year, month, day, sep = "-"))) %>%
	mutate(season_end_year = as.numeric(str_sub(season, 6, 9))) %>%
	left_join(jsonlite::fromJSON("data/lookups/division_to_league_name_main_leagues.json"), by = "division", relationship = "many-to-many") %>%
	filter(season_end_year >= start_year & (is.null(end_year) | season_end_year <= end_year)) %>%
	select(-c(start_year, end_year, season_end_year, division)) %>%
	rename(league = league_name)


bind_rows(df_football_country, df_football_season) %>%
	write_parquet("data/cleaned_data/all_matches.parquet")
