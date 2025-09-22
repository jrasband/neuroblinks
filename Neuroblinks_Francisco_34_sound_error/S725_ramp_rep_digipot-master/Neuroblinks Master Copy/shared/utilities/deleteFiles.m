function deleteFiles(folder)
% DELETEFILES - Safely delete MAT files after verifying compressed versions exist
%
% SYNOPSIS:
%   deleteFiles(folder)
%
% DESCRIPTION:
%   Traverse directories starting at FOLDER and recursively check for 
%   compressed video subdirectory. Delete relevant *.mat files in directory 
%   containing a compressed video subdirectory ONLY after verifying that
%   corresponding compressed files actually exist.
%
% INPUTS:
%   folder - Root directory path to start traversal (string or char array)
%
% SAFETY FEATURES:
%   - Verifies compressed files exist before deleting originals
%   - Checks file sizes to ensure compression completed successfully
%   - Preserves 'meta' and 'trialdata' files regardless of compression status
%   - Provides detailed logging of all operations
%
% EXAMPLE:
%   deleteFiles('/path/to/data/root')
%
% See also: DIR, DELETE, FULLFILE

% Initialize counters for reporting
totalDeleted = 0;
totalSkipped = 0;

% Get directory information
dirInfo = dir(folder);
isDir = [dirInfo.isdir];
dirNames = {dirInfo(isDir).name};

% Remove current and parent directory references
dirNames(strcmp(dirNames, '.') | strcmp(dirNames, '..')) = [];

% Base case: if no subdirectories, return
if isempty(dirNames)
    return
end

% Process each subdirectory
for i = 1:length(dirNames)
    if strcmp(dirNames{i}, 'compressed')
        % Found compressed subdirectory - perform safety checks before deletion
        fprintf('\n=== Processing directory: %s ===\n', folder);
        
        % Get all .mat files in current directory
        fileInfo = dir(fullfile(folder, '*.mat'));
        matFiles = {fileInfo.name};
        
        if isempty(matFiles)
            fprintf('No .mat files found in directory.\n');
            continue;
        end
        
        % Get all files in compressed subdirectory for verification
        compressedPath = fullfile(folder, 'compressed');
        compressedInfo = dir(fullfile(compressedPath, '*.*'));
        compressedFiles = {compressedInfo(~[compressedInfo.isdir]).name};
        
        % Safety check: Ensure compressed directory has files
        if isempty(compressedFiles)
            fprintf('WARNING: Compressed directory exists but is empty. Skipping deletion for safety.\n');
            totalSkipped = totalSkipped + length(matFiles);
            continue;
        end
        
        fprintf('Found %d .mat files and %d compressed files.\n', ...
                length(matFiles), length(compressedFiles));
        
        % Process each .mat file
        for j = 1:length(matFiles)
            currentFile = matFiles{j};
            
            % Skip protected files (meta and trialdata)
            if ~isempty(strfind(currentFile, 'meta')) || ...
               ~isempty(strfind(currentFile, 'trialdata'))
                fprintf('Skipping protected file: %s\n', currentFile);
                totalSkipped = totalSkipped + 1;
                continue;
            end
            
            % Safety check: Verify corresponding compressed file exists
            [~, baseName, ~] = fileparts(currentFile);
            compressedExists = false;
            compressedFile = '';
            
            % Look for compressed version with common video extensions
            videoExtensions = {'.mp4', '.avi', '.mov', '.mkv', '.wmv'};
            for k = 1:length(videoExtensions)
                potentialCompressed = [baseName videoExtensions{k}];
                if any(strcmp(compressedFiles, potentialCompressed))
                    compressedExists = true;
                    compressedFile = potentialCompressed;
                    break;
                end
            end
            
            if ~compressedExists
                fprintf('WARNING: No compressed version found for %s. Skipping deletion for safety.\n', currentFile);
                totalSkipped = totalSkipped + 1;
                continue;
            end
            
            % Additional safety check: Verify compressed file is not zero-sized
            compressedFullPath = fullfile(compressedPath, compressedFile);
            compressedFileInfo = dir(compressedFullPath);
            
            if isempty(compressedFileInfo) || compressedFileInfo.bytes == 0
                fprintf('WARNING: Compressed file %s is empty or corrupted. Skipping deletion for safety.\n', compressedFile);
                totalSkipped = totalSkipped + 1;
                continue;
            end
            
            % All safety checks passed - safe to delete
            originalFullPath = fullfile(folder, currentFile);
            
            try
                delete(originalFullPath);
                fprintf('✓ Successfully deleted: %s (compressed version: %s, %.2f MB)\n', ...
                        currentFile, compressedFile, compressedFileInfo.bytes / (1024*1024));
                totalDeleted = totalDeleted + 1;
            catch ME
                fprintf('ERROR: Failed to delete %s - %s\n', currentFile, ME.message);
                totalSkipped = totalSkipped + 1;
            end
        end
        
    else
        % Recursively process subdirectory
        [subDeleted, subSkipped] = deleteFiles(fullfile(folder, dirNames{i}));
        totalDeleted = totalDeleted + subDeleted;
        totalSkipped = totalSkipped + subSkipped;
    end
end

% Summary reporting
if totalDeleted > 0 || totalSkipped > 0
    fprintf('\n=== Summary for %s ===\n', folder);
    fprintf('Files deleted: %d\n', totalDeleted);
    fprintf('Files skipped: %d\n', totalSkipped);
end

% Return counts for recursive tallying
if nargout >= 1
    varargout{1} = totalDeleted;
end
if nargout >= 2
    varargout{2} = totalSkipped;
end

end