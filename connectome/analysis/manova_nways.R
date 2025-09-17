#!/usr/bin/env Rscript

# Main Function For Doing  MANOVA on an ASE embedding generated in Matlab
library(here); #This allows file path-ing

#All the Functions to complete manova nways are in this file
source(file.path(here::here(),"manova_nways_functions.R"))

# Handle args input
args = commandArgs(trailingOnly=TRUE)

if (length(args)<3) {
  stop("At least two arguments must be supplied for I/O (input file, output file) and at least 1 additional term for source(s) of variation", call.=FALSE)
}

## Get the data from the ASE File -- giant dataframe of data to look at First try comma separator and on error try the tab separated
tryCatch({df<-read.csv(args[2])},error = function(err){
  df<-read.csv(args[2],sep = '\t')})

## Select the test criteria from the inputs
length_arg_adjusted=length(args)-2

if (length_arg_adjusted>1){
  #if for some reason it gets split as different terms in the command then we just make a character array
  source_of_variation<-c(args[2+(1:length_arg_adjusted)])
}else{
  #Other wise split the string and make our own character array
  split_source_of_variation_input=strsplit(args[2+(1:length_arg_adjusted)],split = " ")
  source_of_variation<-unlist(split_source_of_variation_input)
}

print("Data loaded by R")

print("Performing MANOVA")

idx_vertex <- which(grepl("vertex", names(df))) #The index of df equal to vertex

if(is_empty(idx_vertex)){
  #Where there is not vertex we only have one "ROI" entry
  df.statistical_output <- format_manova(df,1,source_of_variation)
}else if (!is_empty(idx_vertex)){
  df.statistical_output <- format_manova(df,length(unique(df$vertex)),source_of_variation)
}

print("MANOVA Done")

## Write the output file
write_csv(df.statistical_output, args[1])

print("Data saved by R")
