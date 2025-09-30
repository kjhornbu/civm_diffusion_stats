function [combo_pval] = fisher_combined(pvalues)
% the values of multiple pvalues to combine are given as a list, pvalues.
% They are combined and returned as a single number, the combo_pval.
%
%Fisher's method of combining p-values described in:
% https://en.wikipedia.org/wiki/Fisher%27s_method
%explaination of why combined pvalues get smaller: 
% https://stats.stackexchange.com/questions/158225/why-is-my-combined-p-value-obtained-using-the-fishers-method-so-low

Chi=-2.*log(pvalues);
combo_pval=1-chi2cdf(sum(Chi),2*numel(pvalues));

end

