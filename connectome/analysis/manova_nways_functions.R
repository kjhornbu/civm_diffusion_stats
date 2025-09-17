#!/usr/bin/env Rscript
# Functions to Do N-way Manova on an ASE embedding generated in Matlab

require(tidyverse)
require(effectsize)
require(dplyr)

library(conflicted)

conflicts_prefer(stats::filter)
conflicts_prefer(stats::lag)

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

  # Pre allocating all the vectors of output (pvalue, effect size, eta2, source of variation, vertex)
  repeat_term = number_of_vertices * source_of_variation_number
  
  pvec <- rep(0, repeat_term)
  effectvec <- rep(0, repeat_term)
  effectsquaredvec <- rep(0, repeat_term)
  eta2vec <- rep(0, repeat_term)
  omega2vec <- rep(0, repeat_term)
  source_of_variation_vec <- rep(0, repeat_term)
  vertex_vec <- rep(0, repeat_term)
  
  vertex_adjust<-rep(0,number_of_vertices)

  for (i in vertex_list) {
    vseq <- seq(i, nrow(df), by = number_of_vertices)
    
    if (number_of_vertices > 1) {
      df.subset <- df[df$vertex %in% vseq, ]
      vertex_adjust[i] <- unique(df.subset$vertex)
    } else{
      df.subset <- df
      vertex_adjust[i] <- vertex_list[i]
      
    }
    
    saving_vector_index <- number_of_sources_of_variation * (i - 1) + (1:number_of_sources_of_variation)
    
    if (sum(is.nan(df.subset[, col_dependant_variable[1]])) > 0) {
      #If there is a NaN in the subset we should just escape and not the math.
      pval <- rep(NaN, number_of_sources_of_variation)
      effect <- NaN
      effect_squared <- NaN
      eta2 <- NaN
      omega2 <- NaN
      
      # Now shift all into long term saving.
      an.error.occured <- FALSE
      tryCatch({
        pvec[saving_vector_index] <- pval[1:number_of_sources_of_variation]
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        effectvec[saving_vector_index] <- effect
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        effectsquaredvec[saving_vector_index] <- effect_squared
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        eta2vec[saving_vector_index] <- eta2
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        omega2vec[saving_vector_index] <- omega2
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      source_of_variation_vec[saving_vector_index] <- rep(NaN, number_of_sources_of_variation)
      
      
      if (number_of_vertices > 1) {
        if (vertex_list[i] > number_of_vertices / 2) {
          vertex_list[i] <- vertex_list[i] - number_of_vertices / 2 + 1000
        }
      }
      vertex_vec[saving_vector_index] <- vertex_list[i]
      
      
    } else{
      statistical_result <- manova(as.formula(form), data = df.subset)
      
      
      if (sd(statistical_result$residuals[, ]) == 0) {
        pval <- rep(NaN, number_of_sources_of_variation)
        effect <- NaN
        effect_squared <- NaN
        eta2 <- NaN
        omega2 <- NaN
        source_of_variation_vec[saving_vector_index] <- rep(NaN, number_of_sources_of_variation)
        
        
      } else{
        statistical_result_summary_table <- summary(statistical_result)
        
        an.error.occured <- FALSE
        tryCatch({
          pval <- (statistical_result_summary_table$stats[, "Pr(>F)"])
        }
        , error = function(e) {
          an.error.occured <<- TRUE
        })
        
        source_of_variation_vec[saving_vector_index] <- (statistical_result_summary_table$row.names[1:number_of_sources_of_variation])
        
        
      }
      
      an.error.occured <- FALSE
      tryCatch({
        effect <- cohens_f(statistical_result)$Cohens_f_partial
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        effect_squared <- cohens_f_squared(statistical_result)$Cohens_f2_partial
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        eta2 <- eta_squared(statistical_result)$Eta2_partial
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        omega2 <- omega_squared(statistical_result)$Omega2_partial
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      # Now shift all into long term saving.
      an.error.occured <- FALSE
      tryCatch({
        pvec[saving_vector_index] <- pval[1:number_of_sources_of_variation]
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        effectvec[saving_vector_index] <- effect
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        effectsquaredvec[saving_vector_index] <- effect_squared
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        eta2vec[saving_vector_index] <- eta2
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      an.error.occured <- FALSE
      tryCatch({
        omega2vec[saving_vector_index] <- omega2
        
      }
      , error = function(e) {
        an.error.occured <<- TRUE
      })
      
      if (number_of_vertices > 1) {
        if (vertex_list[i] > number_of_vertices / 2) {
          vertex_list[i] <- vertex_list[i] - number_of_vertices / 2 + 1000
        }
      }
      vertex_vec[saving_vector_index] <- vertex_list[i]
      
    }
  }
  
  df.statistical_output <- data.frame(
    vertex = vertex_vec,
    source_of_variation = source_of_variation_vec,
    pval = pvec,
    cohenF = effectvec,
    cohenFSquared = effectsquaredvec,
    eta2 = eta2vec,
    omega2=omega2vec
  )
  df.statistical_output <- df.statistical_output %>% mutate(order_pval =
                                                              rank(pval))
  df.statistical_output <- df.statistical_output %>% arrange(pval)
  
  return(df.statistical_output)
}
