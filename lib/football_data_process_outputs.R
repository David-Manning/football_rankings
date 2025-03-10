# Processing script

# Load libraries
library(arrow)
library(tidyverse)
library(ggplot2)
library(readbulk)

# Load data
df_output <- read_bulk(directory = "data/output_tables/",
					   extension = "parquet",
					   verbose = FALSE,
					   fun = arrow::read_parquet)
str(df_output)
