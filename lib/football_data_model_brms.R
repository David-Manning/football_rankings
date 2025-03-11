# Modelling script

# Load libraries
library(arrow)
library(tidyverse)
library(rstan)
library(ggplot2)
library(brms)
library(tidybayes)
library(extraDistr)

# Load data
df_football_long <- read_parquet("data/cleaned_data/all_matches_long.parquet") %>%
	mutate(season = str_replace_all(season, "/", "-"),
		   grouping_identifier = str_replace_all(grouping_identifier, "/", "-")) %>%
	filter(!season %in% c("2025", "2024-2025")) # Current season causes issues

# Create output folder if not present - probably deleted when pushing to Github
if (!dir.exists("data/output_tables")) dir.create("data/output_tables")


# Loop over every grouping identifier
grouping_ids <- unique(df_football_long$grouping_identifier)
for(i in grouping_ids[50])
{

	# Filter data
	df_football <- df_football_long %>%
		filter(grouping_identifier == i)

	# Get country, season, league
	group_data <- df_football_long %>% filter(grouping_identifier == i) %>% select(country, league, season) %>% slice(1)
	country <- group_data$country
	league <- group_data$league
	season <- group_data$season

	# Sample
	priors <- c(prior(normal(0, 0.3), class = "Intercept"),
				prior(normal(0.2, 0.2), class = "b", coef = "at_home"),
				prior(normal(0, 1), class = "sd", coef = "Intercept", group = "team_name"),
				prior(normal(0, 1), class = "sd", coef = "Intercept", group = "opponent_name"),
				prior(normal(0, 1), class = "sd"))
	fit <- brm(formula = team_goals ~ (1 | team_name) + (1 | opponent_name) + at_home,
			   data = df_football,
			   family = "poisson",
			   prior = priors,
			   cores = 4,
			   chains = 4,
			   backend = "cmdstanr")

	# Process and save
	df_posteriors <- fit %>%
		tidybayes::spread_draws(b_at_home, b_Intercept, r_team_name[team_name,], r_opponent_name[opponent_name,]) %>%
		mutate(grouping_identifier = i,
			   country = country,
			   league = league,
			   season = season) %>%
		pivot_longer(cols = c(b_at_home, b_Intercept, r_team_name, r_opponent_name),
					 names_to = "parameter",
					 values_to = "value") %>%
		mutate(club = case_when(parameter == "r_team_name" ~ team_name,
								parameter == "r_opponent_name" ~ opponent_name,
								TRUE ~ NA_character_),
			   parameter = case_when(parameter == "b_at_home" ~ "Home advantage",
			   					     parameter == "b_Intercept" ~ "Intercept",
			   					     parameter == "r_team_name" ~ "Attack mult",
			   					     parameter == "r_opponent_name" ~ "Defence mult"),
			   raw_value = ifelse(parameter == "Defence mult", value * -1, value),
			   percentage = exp(raw_value)) %>%
		as.data.frame() %>%
		select(.chain, .iteration, .draw, parameter, club, raw_value, percentage, grouping_identifier, country, league, season) %>%
		as.data.frame()

}

#TODO: Use extraDistr to estimate GEV for each distribution and save it
