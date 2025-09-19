function params=load_params(filepath)
    %Read the parameters
    parameters=readcell(filepath);

    %Check the number of rows.
    [m,n]=size(parameters);
    if mod(m,2)~=0
       error('ERROR: the configuration file must have an even number of rows, the odd ones containing the parameter names and the even ones the values.') 
    end

    %Detect the cells that are not empty
    mask = cellfun(@ismissing, parameters,'UniformOutput',false);
    for i=1:m
        for j=1:n
            if length(cell2mat(mask(i,j)))==1 && cell2mat(mask(i,j))
                mask2(i,j) = false;
            else
                mask2(i,j) = true;
            end
        end
    end

    %check that all the parameter names have an associtated value.
    for i=1:2:m
        for j=1:n
            if mask2(i,j)~=mask2(i+1,j)
                error('ERROR: each parameter name (%d, %s) must have an associated parameter value (%d, %s)',i, number2letters(j), i+1, number2letters(j));
            end
        end
    end
    
    
    %Create the defaut params table
    params=get_default_params(m/2);
    
    %Get the dictionary indexes
    dictionary_indexes = getappdata(0,'dictionary_indexes');

    %Store the parameters from the file
    for i=1:2:m
        names=parameters(i,mask2(i,:));
        values=cell2mat(parameters(i+1,mask2(i+1,:)));
        [m1,n1]=size(names);

        for j =1:n1
            %check if the parameters in the odd rows are names
            if ~strcmp(class(names{j}),'char')
                error('ERROR: parameter (%d, %s) must be a name',i, number2letters(j));
            end
            
            %check if the parameter name exist in the dictionary of
            %deffined parameters
            if isKey(dictionary_indexes, names(j))
                params((i+1)/2, dictionary_indexes(char(names(j))))=values(j);
            else
                msg = strcat('ERROR: parameter "',char(names(j)),'" it is not in the list of allowed parameters: ');
                %Print the list of allowed parameters.
                allowed_keys = keys(dictionary_indexes);
                msg=strcat(msg, ' ', allowed_keys(1));
                for z=2:dictionary_indexes.Count
                    msg=strcat(msg, ', ', allowed_keys(z));
                end

                error(string(msg));
            end    
        end
    end
end 

    
function defaultparams=get_default_params(N_rows)
    dictionary_indexes=getappdata(0,'dictionary_indexes');
    N_parameters=dictionary_indexes.Count;    
    defaultparams=zeros(N_rows,N_parameters);    
    for i=1:N_rows
        defaultparams(i,dictionary_indexes('repeats'))=1;
        defaultparams(i,dictionary_indexes('CS_delay_ms'))=0;
        defaultparams(i,dictionary_indexes('CS_dur_ms'))=0;
        defaultparams(i,dictionary_indexes('CS_ch'))=7;
        defaultparams(i,dictionary_indexes('CS2_delay_ms'))=0;
        defaultparams(i,dictionary_indexes('CS2_dur_ms'))=0;
        defaultparams(i,dictionary_indexes('CS2_ch'))=5;
        defaultparams(i,dictionary_indexes('ISI_ms'))=0;
        defaultparams(i,dictionary_indexes('US_dur_ms'))=0;
        defaultparams(i,dictionary_indexes('US_ch'))=3;
        defaultparams(i,dictionary_indexes('ISI2_ms'))=0;
        defaultparams(i,dictionary_indexes('US2_dur_ms'))=0;
        defaultparams(i,dictionary_indexes('US2_ch'))=2;
        defaultparams(i,dictionary_indexes('laser_delay_ms'))=0;
        defaultparams(i,dictionary_indexes('laser_dur_ms'))=0;
        defaultparams(i,dictionary_indexes('laser_power'))=0;
        defaultparams(i,dictionary_indexes('CS_period_ms'))=0;
        defaultparams(i,dictionary_indexes('CS_repeats'))=0;
        defaultparams(i,dictionary_indexes('CS_add_reps'))=0;
        defaultparams(i,dictionary_indexes('pre_time_ms'))=200;
        defaultparams(i,dictionary_indexes('post_time_ms'))=800;
        defaultparams(i,dictionary_indexes('ITI_s'))=15;
        defaultparams(i,dictionary_indexes('random_ITI_s'))=0;
        defaultparams(i,dictionary_indexes('ramp_off_time_ms'))=0;
        defaultparams(i,dictionary_indexes('CS_intensity'))=255;
        defaultparams(i,dictionary_indexes('tone_intensity'))=50;
        defaultparams(1,dictionary_indexes('omit_US'))=0;
        defaultparams(1,dictionary_indexes('omit_CR_threshold'))=0.2;
        defaultparams(1,dictionary_indexes('omit_US2'))=0;
        defaultparams(1,dictionary_indexes('omit_CR2_threshold'))=0.2;
        defaultparams(1,dictionary_indexes('omit_US_or_US2'))=0;
        defaultparams(1,dictionary_indexes('post_ITI_thr_inc_start_s'))=30.0;
        defaultparams(1,dictionary_indexes('post_ITI_thr_inc_dur_s'))=120.0;
        defaultparams(1,dictionary_indexes('post_ITI_thr_inc'))=0.6;
        defaultparams(1,dictionary_indexes('motor_current_mA'))=0;
        defaultparams(1,dictionary_indexes('motor_delay_ms'))=0;
        defaultparams(1,dictionary_indexes('motor_dur_ms'))=0;
        defaultparams(1,dictionary_indexes('motor_energized_trial'))=0;
        defaultparams(1,dictionary_indexes('motor_speed_trial'))=0;
        defaultparams(1,dictionary_indexes('motor_acceleration_trial'))=0;
        defaultparams(1,dictionary_indexes('motor_energized_intertrial'))=0;
        defaultparams(1,dictionary_indexes('motor_speed_intertrial'))=0;
        defaultparams(1,dictionary_indexes('motor_acceleration_intertrial'))=0; 
        defaultparams(i,dictionary_indexes('block'))=1;
        defaultparams(i,dictionary_indexes('block_rep'))=100;
    end
end
    
    
function letters = number2letters(number)
    N_letters=26;
    first_letter_number = 0;
    if number > N_letters
       first_letter_number = floor((number-1)/N_letters); 
    end
    second_letter_number=mod(number, N_letters);
    if second_letter_number == 0
        second_letter_number = N_letters;
    end

    letters=[number2letter(first_letter_number) number2letter(second_letter_number)];
end

function letter = number2letter(number)
    switch number
        case 0
            letter = '';
        case 1
            letter = 'A';
        case 2
            letter = 'B';
        case 3
            letter = 'C';
        case 4
            letter = 'D';
        case 5
            letter = 'E';
        case 6
            letter = 'F';
        case 7
            letter = 'G';
        case 8
            letter = 'H';
        case 9
            letter = 'I';
        case 10
            letter = 'J';
        case 11
            letter = 'K';
        case 12
            letter = 'L';
        case 13
            letter = 'M';
        case 14
            letter = 'N';
        case 15
            letter = 'O';
        case 16
            letter = 'P';
        case 17
            letter = 'Q';
        case 18
            letter = 'R';
        case 19
            letter = 'S';
        case 20
            letter = 'T';
        case 21
            letter = 'U';
        case 22
            letter = 'V';
        case 23
            letter = 'W';
        case 24
            letter = 'X';
        case 25
            letter = 'Y';
        case 26
            letter = 'Z';
        otherwise
            error('The number must be an integer value between 1 and 26');
    end
end

