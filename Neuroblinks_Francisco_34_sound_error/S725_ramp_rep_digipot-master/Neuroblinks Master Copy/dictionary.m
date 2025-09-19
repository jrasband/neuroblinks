clear all;

parameters=readcell('condparams_TEST.csv');

[m,n]=size(parameters);
if mod(m,2)~=0
   disp('ERROR') 
end


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

for i=1:2:m
    for j=1:n
        if mask2(i,j)~=mask2(i+1,j)
            error('missmatch detected between dictionary name (%d, %s) and parameter value (%d, %s)',i, number2letters(j), i+1, number2letters(j));
        end
    end
end


for i=1:2:m
    names=parameters(i,mask2(i,:));
    values=cell2mat(parameters(i+1,mask2(i+1,:)));
    [m1,n1]=size(names);
    [m2,n2]=size(values);
    if n1~=n2
        disp('ERROR')
    end
    
    for j =1:n1
        switch char(names(j))
            case 'repeats'
                disp(values(j));
            case 'CS (ms)'
                disp(values(j));
            case 'CS Ch'
                disp(values(j));
                
            otherwise
                disp('HOLA')
        end        
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



