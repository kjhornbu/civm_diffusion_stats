function [idx] = filterData_byInput(data,dataField,dataEntry)
%Filters a specific field (dataField) of a table (data) by a specifc entry
%type (dataEntry).
idx = ~cellfun(@isempty,regexpi(data.(dataField),dataEntry));
end