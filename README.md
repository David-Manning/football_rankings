# Better Football Rankings

This project fixes a key issue with traditional football league rankings: 

Points are used as a proxy for ability but are not conditioned on whether the team was playing at home or away or who the team played, and goals scored/conceded are proxies for attacking and defensive ability but are similarly not conditioned on home or away status or opponent.

## Basic Principles

These rankings follow the same basic principles:

1) At the start of each season, each team's slate is wiped clean and every team in the division is at the same starting point. Team ability does **not** depend on previous season ability, rankings, or other sources of data. Rankings are **only** determined by the results in matches that season.

2) Rankings should be based on how strong the opponent was - scoring 7 goals against the best team in the division should count for more than scoring 7 goals against the best team in the division.

3) Matches at the start of the season should have the same weight as matches at the end of the season to avoid recency bias.

4) Strength should be updated according to the advantage of playing at home or the disadvantage of playing away.

5) Ranking should be separated to attack and defence to give relative strengths for each team. Combined rankings will combine these two.

6) Injuries, transfers, and managerial changes should still count towards adjusting the team's overall strength - avoiding injuries is an important part of the game.

## Data Sources

All data are taken from www.football-data.co.uk and processed lib/football_data_download.R.

Matches which do not have scored are removed, and only league matches are reported (i.e. they do not have data on cup matches). All league matches that are completed and on football-data.co.uk are included in the models.

## Usage
There are three R scripts: `football_data_download.R`, `football_data_model_brms.R`, `football_data_process_output.R`. These should be run in order. Data from football-data.co.uk are pushed to Github, so the download file can be skipped (running it will bring in the latest data).

## Motivation
I am using this to test a workflow in Github and sharing model outputs on Shiny.
