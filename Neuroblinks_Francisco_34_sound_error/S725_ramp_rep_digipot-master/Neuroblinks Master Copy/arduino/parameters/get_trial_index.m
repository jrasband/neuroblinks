function index=get_trial_index(param_name)
    %Get dictionary indexes
    dictionary_indexes = getappdata(0,'dictionary_indexes');
    
    if ~isKey(dictionary_indexes, param_name)
        error(['ERROR: parameter "' param_name '" does not exist']);
    end
    
    %the trial index is equal the param table index minus one, because in the
    %trial table we remove the first parameter from the param table
    %(repeats)
    index=dictionary_indexes(param_name)-1;
end
