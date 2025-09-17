function [q] = getElbows(V,m)
    %Based on Zhu and Ghosdi 2006 -> Automatic dimensionality selection
    %from the scree plot via the used of profile likelihood
    %REwritten form of Youngster code for get elbows:
    %github.com/youngser/gmmase/blob/master/R/getElbows.R
   
%     %using just the command in matlab to run it unsure why the prior
%     %version was not working for the algorithm.  --- because the resulting
%     %q is always found at 11 -> this is just the middle of the sampling
%     %which a normal distribution function will give you no matter what when
%     %you have a large number of points it isn't actually picking what you
%     %really need!!! (sum(1:21)/numel(1:21) == 11) 
%     pd=fitdist(V,'normal');
%     q=find([max(proflik(pd,1))==proflik(pd,1)]==1); %Use the mean as the param for the profile loglikihood
%     

% Basically you sample the data into two groups and find if the data from
% the two different distributions maxes out that would then be the number
% of points to maximally keep.
    p=size(V,1); %what is the total size of the data array 
    
    for n=1:p
        M(1)=mean(V(1:n)); %mean_of_distribution_1(from-> start to the given q)
        M(2)=mean(V(n+1:p)); %mean_2_of_distribution_2 (from -> q+1 to end)
        
        VAR=(sum((V(1:n)-M(1)).^2)+sum((V(n+1:p)-M(2)).^2))/(p-1-(n<p)); %variance between the two means -> pull it from between the two distributions
        
        %The standard pooled variance FOR TWO SAMPLES is Spool^2 = (n-1)*Sx^2 + (m-1)*Sy^2
        %/ ((n-1)+(m-1)) where n is size of x sample, m is size of y sample
        %and the S's are just the variance associated which each sample set
        %as E[X-mu]... the actual equation here is a simplified form of that function. 
        
        STD=sqrt(VAR); %The standard deviation is what you actually use inside the calculation function of the two groups.
        
        I(n)=sum(((-((V(1:n)-M(1))/STD).^2/2)-log(STD*sqrt(2*pi)))) + sum(((-((V(n+1:p)-M(2))/STD).^2/2)-log(STD*sqrt(2*pi))));
        
        %this is a little complex because it is doing several things at one
        %time. in essence it is the
        %log(PDF_normal(V(1:q),mean_1,pooled_STD)+log(PDF_normal(V(q+1:p),mean_1,pooled_STD)
        %but just written out more....
    end
    
    [~,q] = max(I);
    
    %find several points for the q where they occur by finding the next q
    %term. (the jump in the graph because of smoothness of real data maybe
    %will not exactly occur right there find several then outside of this
    %function select the average second on the full set of points achieved from
    %script!
    
    if m>1 && q < (p-1) 
        
        % so while the counter of key terms to select (m) is greater than 1 you
        %will iterate to find the next new q in the space possible remaining in the V (the sorted eigenvalue) data. 
        
        q = [q, q + getElbows(V((q+1):p), m-1)];
    end
    
end
