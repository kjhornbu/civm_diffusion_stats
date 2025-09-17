function [df] = finding_scale_values(df,filename)
%scale=input('Find Scale Values? [1=Yes, 0=No] ');
try
    [df,col_2_modify,VariableDescriptions]=scaleconnectome_by_volume(df,0); %The 0 is remove the ventricles
catch
    df=scaleconnectome_by_volume_old_WHS_version(df,0); %The 0 is remove the ventricles
end

%Put the variable descriptions back on
df.Properties.VariableDescriptions=VariableDescriptions;

%make user Readable dataframe for resaving with the scale values
df_user_readable=df;
VariableNames=df_user_readable.Properties.VariableNames;
%find where neeed to switch to make user readable
idx_switch=find(col_2_modify);
for n=1:numel(idx_switch)
    df_user_readable.Properties.VariableNames{idx_switch(n)}=VariableDescriptions{idx_switch(n)};
    df_user_readable.Properties.VariableDescriptions{idx_switch(n)}=VariableNames{idx_switch(n)};
end

civm_write_table(df_user_readable,filename);

%but to keep internal meaning keep the df the same as it is at this point.
%(send  back the df without the switched names)
end

