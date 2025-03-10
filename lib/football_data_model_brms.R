# Modelling script

# Load libraries
library(arrow)
library(tidyverse)
library(rstan)
library(ggplot2)
library(brms)
library(tidybayes)

# Load data
df_football_long <- read_parquet("data/cleaned_data/all_matches_long.parquet") %>%
	filter(!season %in% c("2025", "2024-2025")) # Current season causes issues

# Loop over every grouping identifier
grouping_ids <- unique(df_football_long$grouping_identifier)
for(i in grouping_ids)
{

	# Filter data
	df_football <- df_football_long %>%
		filter(grouping_identifier == i)

	# Get country, season, league
	group_data <- df_football_wide %>% filter(grouping_identifier == i) %>% select(country, league, season) %>% slice(1)
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
	fit %>%
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
		as.data.frame()	%>%
		write_parquet(paste0("data/output_tables/", i, ".parquet"))

}

