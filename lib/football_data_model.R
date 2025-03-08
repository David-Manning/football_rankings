# Modelling script

# Load libraries
library(arrow)
library(tidyverse)
library(rstan)

# Load data
df_football_long <- read_parquet("data/cleaned_data/all_matches_long.parquet") %>%
	filter(season %in% c("2023-2024", "2022-2023"), country %in% c("Germany", "England"))

# Create unique identifiers for teams and opponents within groups
team_groups <- df_football_long %>%
	select(grouping_identifier, team_name) %>%
	distinct() %>%
	mutate(team_group_id = row_number())
opponent_groups <- df_football_long %>%
	select(grouping_identifier, opponent_name) %>%
	distinct() %>%
	mutate(opponent_group_id = row_number())

# Join the IDs back to the dataset
df_model <- df_football_long %>%
	left_join(team_groups, by = c("grouping_identifier", "team_name")) %>%
	left_join(opponent_groups, by = c("grouping_identifier", "opponent_name"))

# Prepare the Stan data object
stan_data <- list(N = nrow(df_model),
				  team_goals = df_model$team_goals,
				  N_team_groups = max(df_model$team_group_id),
				  N_opponent_groups = max(df_model$opponent_group_id),
				  team_group_id = df_model$team_group_id,
				  opponent_group_id = df_model$opponent_group_id,
				  at_home = df_model$at_home)

# Generate Stan data

# Load Stan model
stan_model <- rstan::stan_model("lib/dixon_coles.stan",
								model_name = "football_model",
								verbose = FALSE)

fit <- rstan::sampling(object = stan_model,
					   data = stan_data,
					   cores = 4,
					   chains = 4,
					   warmup = 1000,
					   iter = 2000)

fit

