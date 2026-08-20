#!/usr/bin/env Rscript
# Functions to Do N-way Manova on an ASE embedding generated in Matlab

library(tidyverse)
library(effectsize)
library(dplyr)
library(purrr)
library(car)
library(conflicted)

conflicts_prefer(stats::filter)
conflicts_prefer(stats::lag)

# Create a tibble saving Structure
write_to_tibble <- function(statistical_output,
                            vertex,
                            source_of_variation,
                            DF,
                            approxF,
                            pvalue,
                            cohens_f,
                            cohens_f2,
                            eta2,
                            omega2) {
  if (nrow(statistical_output) > 0) {
    statistical_output <- add_row(
      statistical_output,
      vertex = rep(vertex, length(source_of_variation)),
      source_of_variation = source_of_variation,
      DF = DF[1:length(source_of_variation)],
      approxF = approxF[1:length(source_of_variation)],
      pval = pvalue[1:length(source_of_variation)],
      cohenF = cohens_f,
      cohenFSquared = cohens_f2,
      eta2 = eta2,
      omega2 = omega2
    )
  } else{
    statistical_output <- tibble(
      vertex = rep(vertex, length(source_of_variation)),
      source_of_variation = source_of_variation,
      DF = DF[1:length(source_of_variation)],
      approxF = approxF[1:length(source_of_variation)],
      pval = pvalue[1:length(source_of_variation)],
      cohenF = cohens_f,
      cohenFSquared = cohens_f2,
      eta2 = eta2,
      omega2 = omega2
    )
  }
  return(statistical_output)
}

# MANOVA Setup Function
format_manova <- function(df, number_of_vertices, independent_variable) {
  
  # Find Columns with Dependent Variables and their actual heading name
  col_dependant_variable <- which(grepl("^X", names(df))) # column indices for the embedding
  dependant_variable <- colnames(df)[col_dependant_variable]
  
  df.statistical_output <- manova_significance_testing(df, number_of_vertices, dependant_variable, independent_variable)
  #Actually determining manova pvalues, the test criteria are our indep variables
  # like 90% sure this is across all the data (roi/sources of variation etc)... so if you have multiple sources of variation it might be over correcting the model? You should put pushing each source of variation by itself or doing it in the matlab function that does it properly
  #df.statistical_output <- data.frame(df.statistical_output, pval_BH=p.adjust(df.statistical_output$pval, "BH"))
  #Just do the BH correction on our own.
  #adjusts the pvalues based on BH correction
  
  return(df.statistical_output)
}

## Do Actual Significance
manova_significance_testing <- function(df, number_of_vertices, dependant_variable, independent_variable){
  
  #Setting up form of test in text -> (x1..xN)~genotype1*genotype2*...genotypeN -- we do full interaction model currently would like to change to some written out formula desired.
  form <- paste0("cbind(", paste(dependant_variable, collapse=", "), ") ~ ", paste0(independent_variable,collapse="*"))
  
  #This figures out the number of full interactions at any level
  source_of_variation_number<-length(independent_variable)
  if( source_of_variation_number>1){
    for (k in 2:length(independent_variable)){
      source_of_variation_number=choose(length(independent_variable),k)+source_of_variation_number
    }
  }
  vertex_list=1:number_of_vertices
  df.statistical_output=tibble()
  
  for (i in vertex_list) {
    vseq <- seq(i, nrow(df), by = number_of_vertices)
    
    if (number_of_vertices > 1) {
      df.subset <- df[df$vertex %in% vseq, ]
    } else{
      df.subset <- df
    }
    
    saving_vector_index <- number_of_sources_of_variation * (i - 1) + (1:number_of_sources_of_variation)
    
    if (sum(is.nan(df.subset[, col_dependant_variable[1]])) > 0) {
      #If there is a NaN in the subset we should just escape and not the math.
      DF <- rep(NaN, number_of_sources_of_variation)
      approxF <- rep(NaN, number_of_sources_of_variation)
      pval <- rep(NaN, number_of_sources_of_variation)
      effect <- rep(NaN, number_of_sources_of_variation)
      effect_squared <- rep(NaN, number_of_sources_of_variation)
      eta2 <- rep(NaN, number_of_sources_of_variation)
      omega2 <- rep(NaN, number_of_sources_of_variation)
      source_of_variation_vec <- rep(NA, number_of_sources_of_variation)
      
    } else{
      
      mixed = 0
      model <- tryCatch({
        lm(form, data = df.subset)
      }, error = function(e) {
        mixed <<- 1
        lmer(form, data = df.subset)
      })
      
      
      #statistical_result <- manova(as.formula(form), data = df.subset)
      #statistical_result_summary_table <- summary(statistical_result)
      
      if (sd(model$residuals[, ]) == 0) {
        DF <- rep(NaN, number_of_sources_of_variation)
        approxF <- rep(NaN, number_of_sources_of_variation)
        pval <- rep(NaN, number_of_sources_of_variation)
        effect <- rep(NaN, number_of_sources_of_variation)
        effect_squared <- rep(NaN, number_of_sources_of_variation)
        eta2 <- rep(NaN, number_of_sources_of_variation)
        omega2 <- rep(NaN, number_of_sources_of_variation)
        source_of_variation_vec <- rep(NA, number_of_sources_of_variation)
        
        
      } else{
        
        statistical_result <- Anova(model, type = "III")
        
        # create output extraction
        
        outtests <- car:::print.Anova.mlm
        body(outtests)[[16]] <- quote(invisible(tests))
        body(outtests)[[15]] <- NULL
        
        statistical_result_summary_table <- outtests(statistical_result)
        
        DF <- statistical_result_summary_table$Df[1 + (1:number_of_sources_of_variation)]
        approxF <- statistical_result_summary_table$`approx F`[1 + (1:number_of_sources_of_variation)]
        pval<-statistical_result_summary_table$`Pr(>F)`[1 + (1:number_of_sources_of_variation)]
        effect <- cohens_f(statistical_result)$Cohens_f_partial
        effect_squared <- cohens_f_squared(statistical_result)$Cohens_f2_partial
        eta2 <- eta_squared(statistical_result)$Eta2_partial
        omega2 <- omega_squared(statistical_result)$Omega2_partial
        source_of_variation_vec <-statistical_result$terms[1 + (1:number_of_sources_of_variation)]
        
        
        #DF <- (statistical_result_summary_table$stats[, "Df"])
        #approxF <- (statistical_result_summary_table$stats[, "approx F"])
        #pval <- (statistical_result_summary_table$stats[, "Pr(>F)"])
        #effect <- cohens_f(statistical_result)$Cohens_f_partial
        #effect_squared <- cohens_f_squared(statistical_result)$Cohens_f2_partial
        #eta2 <- eta_squared(statistical_result)$Eta2_partial
        #omega2 <- omega_squared(statistical_result)$Omega2_partial
        #source_of_variation_vec <- (statistical_result_summary_table$row.names[1:number_of_sources_of_variation])
      }
    }
    
    if (number_of_vertices > 1) {
      if (vertex_list[i] > number_of_vertices / 2) {
        vertex_list[i] <- vertex_list[i] - number_of_vertices / 2 + 1000
      }
    }
    
    df.statistical_output<-write_to_tibble(df.statistical_output,vertex_list[i],source_of_variation_vec,DF,approxF,pval,effect,effect_squared,eta2,omega2)
  }
  
  df.statistical_output <- df.statistical_output %>% mutate(order_pval =
                                                              rank(pval))
  df.statistical_output <- df.statistical_output %>% arrange(pval)
  
  return(df.statistical_output)
}
