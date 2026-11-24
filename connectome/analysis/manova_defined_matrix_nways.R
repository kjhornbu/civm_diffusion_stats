#!/usr/bin/env Rscript
# Main Function For Doing  MANOVA on an ASE embedding generated in Matlab

# add wks r lib
wks_home <- Sys.getenv(x = "WORKSTATION_HOME", unset = "", names = NA)
wks_aux <- file.path(wks_home,"aux")
if (! file.exists(wks_aux) ) {
  wks_aux <- file.path(wks_home,"auxilliary")
}
wks_r_lib <- file.path(wks_aux,"R_library")
if (! dir.exists(wks_r_lib) ){
  dir.create(wks_r_lib)
}

.libPaths(wks_r_lib,FALSE)
#lib.names <- c("dplyr","conflicted","purrr")
lib.names <- c("effectsize","dplyr","conflicted","purrr","readr","car","tidyverse")
for (lib_name in lib.names) {
  if (! requireNamespace(lib_name) ){
    print(c("Installing missing package:",lib_name))
    install.packages(lib_name, repos = "http://cran.us.r-project.org")
  }
}

initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)

#All the Functions to complete manova nways are in this file
#source(file.path(here::here(), "manova_defined_matrix_nways_functions.R"))
#source(file.path(script.dir <- dirname(sys.frame(1)$ofile), "manova_defined_matrix_nways_functions.R"))
#source("manova_defined_matrix_nways_functions.R")
source(file.path(script.basename,"manova_defined_matrix_nways_functions.R"))

library(readr)

# Handle args input
args = commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  stop(
    "At least two arguments must be supplied for I/O (input file, output file), a numeric of total number of sources of variation, and one term giving the source of variation equation",
    call. = FALSE
  )
}

criteria<-read.csv(args[3])

## Get the data from the ASE File -- giant dataframe of data to look at First try comma separator and on error try the tab separated
tryCatch({
  df <- read.csv(args[2],check.names = FALSE)
}, error = function(err) {
  df <- read.csv(args[2], sep = '\t',check.names = FALSE)
})


for (i in seq_len(nrow(criteria))) {
  target_col <- trimws(criteria$grouping_variable[i]) # Removes any accidental leading/trailing spaces
  target_type <- trimws(criteria$type[i])
  
  # Search for the column name in df
  col_idx <- match(target_col, names(df))
  
  if (is.na(col_idx)) {
    warning(paste("Column not found in CSV:", target_col))
    next
  }
  
  # Convert the matched column to make sure it is the type indicated
  if (target_type == "discrete") {
    df[[col_idx]] <- as.factor(df[[col_idx]])
  } else if (target_type == "continuous") {
    df[[col_idx]] <- as.numeric(df[[col_idx]])
  }
}

#Grab number of sources of variation in the study
number_of_sources_of_variation <- as.numeric(args[4])
#Get the actual equation for the model
defined_formula <- args[5]

print("Data loaded by R")

print("Performing MANOVA")

idx_vertex <- which(grepl("vertex", names(df))) #The index of df equal to vertex

if (rlang::is_empty(idx_vertex)) {
  #Where there is not vertex we only have one "ROI" entry
  df.statistical_output <- format_manova(df, 1, number_of_sources_of_variation, defined_formula)
} else if (!rlang::is_empty(idx_vertex)) {
  number_of_vertices <- length(unique(df$vertex))
  df.statistical_output <- format_manova(df,
                                         number_of_vertices,
                                         number_of_sources_of_variation,
                                         defined_formula)
}

print("MANOVA Done")

## Write the output file
write_csv(df.statistical_output, args[1])

print("Data saved by R")
