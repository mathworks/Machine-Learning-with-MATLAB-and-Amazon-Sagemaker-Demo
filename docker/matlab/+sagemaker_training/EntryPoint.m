classdef EntryPoint
% EntryPoint

% Copyright 2023 The MathWorks, Inc.

    properties(SetAccess=private)
        Environment sagemaker_training.Environment
    end

    methods
        function ep = EntryPoint(env)
            ep.Environment = env;
        end
    
        function run(ep)
            env = ep.Environment;
            if env.ModuleFolder.endsWith(".mltbx")
                disp("Installing " + env.ModuleFolder)
                mltbxFile = [tempname, '.mltbx'];
                copyfile(env.ModuleFolder, mltbxFile);
                matlab.addons.toolbox.installToolbox(mltbxFile);
            elseif env.ModuleFolder.endsWith(".zip")
                disp("Unzipping files from " + env.ModuleFolder + " to " + env.CodeFolder)
                sourceZip = [tempname, '.zip'];
                copyfile(env.ModuleFolder, sourceZip);
                unzip(sourceZip, env.CodeFolder);
            else
                disp("Copying files from " + env.ModuleFolder + " to " + env.CodeFolder)
                copyfile(env.ModuleFolder, env.CodeFolder);
            end
            
            disp("Adding " + env.CodeFolder + " to MATLAB's path")
            foldersToAddToPath = genpath(env.CodeFolder);
            oldPath = addpath(foldersToAddToPath);
            resetPath = onCleanup(@()path(oldPath));

            if env.UserEntryPoint.endsWith(".mat")
                userEntryPointFile = env.UserEntryPoint;
                if env.UserEntryPoint.startsWith("s3://")
                    userEntryPointFile = [tempname, '.mat'];
                    copyfile(env.UserEntryPoint, userEntryPointFile);
                end
                loaded = load(userEntryPointFile, 'UserEntryPoint');
                userEntryPoint = loaded.UserEntryPoint;
            else
                userEntryPoint = str2func(env.UserEntryPoint);
            end

            disp("Calling userEntryPoint")            
            namedArgs = env.toArgs();
            % Call the user entrypoint with the environment and the hyperparameters
            userEntryPoint(env, namedArgs{:});
        end
    end
end