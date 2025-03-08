data {
  int<lower=0> N;                               // observations
  int<lower=0> team_goals[N];                   // goals scored

  int<lower=0> N_team_groups;                   // unique team-group combinations
  int<lower=0> N_opponent_groups;               // unique opponent-group combinations

  int<lower=1, upper=N_team_groups> team_group_id[N];       // team-group ID
  int<lower=1, upper=N_opponent_groups> opponent_group_id[N]; // opponent-group ID

  vector[N] at_home;                            // home indicator (0/1)
}

parameters {
  real alpha;                                  // intercept
  real home_advantage;                         // home effect

  // Random effects
  vector[N_team_groups] team_group_effect_raw;
  vector[N_opponent_groups] opponent_group_effect_raw;

  real<lower=0> sigma_team;                    // SD for team effects
  real<lower=0> sigma_opponent;                // SD for opponent effects
}

transformed parameters {
  // Non-centered parameterization
  vector[N_team_groups] team_group_effect = sigma_team * team_group_effect_raw;
  vector[N_opponent_groups] opponent_group_effect = sigma_opponent * opponent_group_effect_raw;

  vector[N] log_lambda;  // log expected goals

  for (i in 1:N) {
    log_lambda[i] = alpha + team_group_effect[team_group_id[i]] +
                   opponent_group_effect[opponent_group_id[i]] +
                   home_advantage * at_home[i];
  }
}

model {
  // Priors
  alpha ~ normal(0, 0.25);
  home_advantage ~ normal(0.15, 0.1);

  sigma_team ~ normal(0, 0.5);
  sigma_opponent ~ normal(0, 0.5);

  team_group_effect_raw ~ normal(0, 1);
  opponent_group_effect_raw ~ normal(0, 1);

  // Likelihood
  team_goals ~ poisson_log(log_lambda);
}

generated quantities {
  vector[N] log_lik;
  vector[N] lambda = exp(log_lambda);

  for (i in 1:N) {
    log_lik[i] = poisson_lpmf(team_goals[i] | lambda[i]);
  }
}
