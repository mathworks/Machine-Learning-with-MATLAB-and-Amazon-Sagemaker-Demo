function [toolboxFile, userEntryPointName, requiredProducts] = packageTrainingFunction(trainingFunction, jobName)
% packageTrainingFunction

% Copyright 2023 The MathWorks, Inc.    

% This will be the root of the "toolbox" we are creating
    toolboxFolder = tempname;
    makeFolderOrError(toolboxFolder);
    removeFolder = onCleanup(@()rmdir(toolboxFolder, 's'));
    
    % Get the files required by TrainingFunction
    disp("Analysing files required by training function")
    functionInfo = functions(trainingFunction);
    functionFullPath = functionInfo.file;
    requiredFiles = string.empty();
    requiredProducts = string.empty();
    if ~isempty(functionFullPath)
        [requiredFiles, requiredProducts] = matlab.codetools.requiredFilesAndProducts(functionFullPath);
        requiredFiles = string(requiredFiles);
        requiredProducts = string({requiredProducts.Name});
        % Remove these - already on the image
        requiredProducts(requiredProducts=="MATLAB") = [];
        requiredProducts(requiredProducts=="Parallel Computing Toolbox") = [];
        requiredProducts(requiredProducts=="Statistics and Machine Learning Toolbox") = [];
        % Remove these - only needed to build infereence container
        requiredProducts(requiredProducts=="MATLAB Compiler") = [];
        requiredProducts(requiredProducts=="MATLAB Compiler SDK") = [];
    end
    
    % The files that will be added to the toolbox
    toolboxFiles = strings(1, length(requiredFiles)+1);
    
    % Need to make file paths relative to the folder on MATLAB path
    % Don't care about parts of the path under MATLAB root
    thePath = string(split(path,pathsep));
    thePath = thePath(~thePath.startsWith(matlabroot));
    thePath = [thePath; pwd];
    
    % Copy all the required files to toolboxFolder
    for idx = 1:length(requiredFiles)
        src = requiredFiles(idx);
        for pathFolder = thePath'
            if src.startsWith(pathFolder)
                relPath = src.extractAfter(pathFolder+filesep);
                dst = fullfile(toolboxFolder, relPath);
                makeFolderOrError(fileparts(dst));
                copyfile(src, dst);
                toolboxFiles(idx) = dst;
                break
            end
        end
    end
    
    % Save the TrainingFunction to a MAT file that will be included with the toolbox
    userEntryPointName = jobName+".mat";
    userEntryPointFile = fullfile(toolboxFolder, userEntryPointName);
    UserEntryPoint = trainingFunction;
    save(userEntryPointFile, 'UserEntryPoint');
    toolboxFiles(end) = userEntryPointFile;
    
    % Now make a toolbox
    toolboxFile = fullfile(tempname, jobName + ".mltbx");
    makeFolderOrError(fileparts(toolboxFile));
    opts = matlab.addons.toolbox.ToolboxOptions(...
        toolboxFolder, ...
        jobName, ...
        ToolboxName=jobName, ...
        ToolboxFiles=toolboxFiles, ...
        ToolboxMatlabPath=toolboxFolder, ...
        OutputFile=toolboxFile);
    disp("Packaging required files as a mltbx")
    matlab.addons.toolbox.packageToolbox(opts);
end

function makeFolderOrError(folder)
arguments
    folder(1,1) string
end
[success, msg, msgid] = mkdir(folder);
if ~success
    error(msg, msgid);
end
end