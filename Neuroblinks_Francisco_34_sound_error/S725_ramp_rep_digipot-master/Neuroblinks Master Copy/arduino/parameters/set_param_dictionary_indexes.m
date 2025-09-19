%%%%%%%%%%%%%%FRANCISCO%%%%%%%%%%%%%%%%
function set_param_dictionary_indexes(handles)
    %read the param names defined in the GUI and create the param
    %dictionary indexes
    param_names=get(handles.uitable_params,'ColumnName');
    N_names=size(param_names,1);    
    dictionary_indexes=containers.Map;
    
    for i=1:N_names
        dictionary_indexes(char(param_names(i)))=i; 
    end
    
    setappdata(0,'dictionary_indexes',dictionary_indexes);
end
