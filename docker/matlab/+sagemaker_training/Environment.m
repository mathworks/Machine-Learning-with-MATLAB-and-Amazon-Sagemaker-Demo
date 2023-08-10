classdef Environment < matlab.mixin.CustomDisplay
% Environment

% Copyright 2023 The MathWorks, Inc.
    properties(Constant, Access=private)
        BASE_PATH_ENV string = "SAGEMAKER_BASE_DIR";
        SAGEMAKER_BASE_PATH string = fullfile("/", "opt", "ml")
        HYPERPARAMETERS_FILE string = "hyperparameters.json"
        RESOURCE_CONFIG_FILE string = "resourceconfig.json"
        INPUT_DATA_CONFIG_FILE string = "inputdataconfig.json" 

        SAGEMAKER_PREFIX string = "sagemaker_"

        USER_PROGRAM_PARAM string = "sagemaker_program"
        USER_PROGRAM_ENV string = upper(sagemaker_training.Environment.USER_PROGRAM_PARAM)

        SUBMIT_DIR_PARAM string = "sagemaker_submit_directory"
        SUBMIT_DIR_ENV string = upper(sagemaker_training.Environment.SUBMIT_DIR_PARAM) 

        % TODO - there are more
        SAGEMAKER_HYPERPARAMETERS string = [sagemaker_training.Environment.USER_PROGRAM_PARAM, sagemaker_training.Environment.SUBMIT_DIR_PARAM] 
    end
    properties(SetAccess=private)
        BaseFolder string
        CodeFolder string
        ModelFolder string
        InputFolder string
        InputDataFolder string
        InputConfigFolder string
        OutputFolder string
        OutputDataFolder string
        OutputIntermediateFolder string

        HyperParametersFile string
        ResourceConfigFile string
        InputDataConfigFile string

        ModuleFolder string
        ModuleName string
        UserEntryPoint string
    end
    properties(SetAccess=private)
        InputDataConfig struct = struct()
        ResourceConfig struct = struct()
        HyperParameters struct = struct()
        AdditionalFrameworkParameters struct = struct()
        ChannelInputFolders struct = struct()
    end
    methods
        function env = Environment(args)
            arguments
                args.ResourceConfig  struct = struct.empty();
                args.InputDataConfig struct = struct.empty();
                args.HyperParameters struct = struct.empty();
            end
            env.BaseFolder = getenv_or(sagemaker_training.Environment.BASE_PATH_ENV, sagemaker_training.Environment.SAGEMAKER_BASE_PATH);
            env.CodeFolder = fullfile(env.BaseFolder, "code");
            env.ModelFolder = fullfile(env.BaseFolder, "model");
            env.InputFolder = fullfile(env.BaseFolder, "input");
            env.InputDataFolder = fullfile(env.InputFolder, "data");
            env.InputConfigFolder = fullfile(env.InputFolder, "config");
            env.OutputFolder = fullfile(env.BaseFolder, "output");
            env.OutputDataFolder = fullfile(env.OutputFolder, "data");
            env.OutputIntermediateFolder = fullfile(env.OutputFolder, "intermediate");

            env.HyperParametersFile = fullfile(env.InputConfigFolder, sagemaker_training.Environment.HYPERPARAMETERS_FILE);
            env.ResourceConfigFile = fullfile(env.InputConfigFolder, sagemaker_training.Environment.RESOURCE_CONFIG_FILE);
            env.InputDataConfigFile = fullfile(env.InputConfigFolder, sagemaker_training.Environment.INPUT_DATA_CONFIG_FILE);

            if ~isTrainingFolderConfigured(env)
                createTrainingFolders(env);
            end
            createCodeFolder(env);

            env.ModuleName = getenv_or(sagemaker_training.Environment.USER_PROGRAM_ENV, string.empty);
            env.UserEntryPoint = env.ModuleName;
            env.ModuleFolder = getenv_or(sagemaker_training.Environment.SUBMIT_DIR_PARAM, env.CodeFolder);

            env.ResourceConfig = or(args.ResourceConfig, @()readResourceConfig(env));
            env.InputDataConfig = or(args.InputDataConfig, @()readInputDataConfig(env));
            allHyperParameters = or(args.HyperParameters, @()readHyperParameters(env));

            % Split hyperparameters
            [sagemakerHyperParameters,  env.HyperParameters] = split(allHyperParameters, ...
                    sagemaker_training.Environment.SAGEMAKER_HYPERPARAMETERS, sagemaker_training.Environment.SAGEMAKER_PREFIX);
            
            % TODO: AdditionalFrameworkParameters are the sagemakerHyperParameters that aren't in SAGEMAKER_HYPERPARAMETERS

            env.ModuleName = or(env.ModuleName, sagemakerHyperParameters.(sagemaker_training.Environment.USER_PROGRAM_PARAM));
            env.UserEntryPoint = or(env.UserEntryPoint, sagemakerHyperParameters.(sagemaker_training.Environment.USER_PROGRAM_PARAM));
            env.ModuleFolder = getfield_or(sagemakerHyperParameters, sagemaker_training.Environment.SUBMIT_DIR_PARAM, env.CodeFolder);
            
            for channel = string(fieldnames(env.InputDataConfig)).'
                env.ChannelInputFolders.(channel) = fullfile(env.InputDataFolder, channel);
            end

        end

    end
    methods
        function args = toArgs(env)
            args = namedargs2cell(env.HyperParameters);
        end
    end
    methods(Access=private)
        function tf = isTrainingFolderConfigured(env)
            tf = exist(env.SAGEMAKER_BASE_PATH, 'dir')==7 || ~isempty(getenv_or(env.BASE_PATH_ENV));
        end
        function createTrainingFolders(env)
            makeFolderOrError(env.ModelFolder);
            makeFolderOrError(env.InputConfigFolder);
            makeFolderOrError(env.OutputDataFolder);
        end
        function createCodeFolder(env)
            makeFolderOrError(env.CodeFolder);
        end

        function hyperparameters = readHyperParameters(env)
            hyperparameters = readjson(env.HyperParametersFile);
        end
        function resourceConfig = readResourceConfig(env)
            resourceConfig = readjson(env.ResourceConfigFile);
        end
        function inputDataConfig = readInputDataConfig(env)
            inputDataConfig = readjson(env.InputDataConfigFile);
        end
    end
    methods(Access = protected)
        function groups = getPropertyGroups(env)
            if isscalar(env)
                props = struct(...
                    "ModuleName", env.ModuleName, ...
                    "ModuleFolder", env.ModuleFolder, ...
                    "UserEntryPoint", env.UserEntryPoint);
                groups(1) = matlab.mixin.util.PropertyGroup(props);

                folders = struct(...
                    "BaseFolder", env.BaseFolder, ...
                    "CodeFolder", env.CodeFolder, ...
                    "ModelFolder", env.ModelFolder, ...
                    "OutputFolder", env.OutputFolder);
                groups(end+1) = matlab.mixin.util.PropertyGroup(folders);


                groups(end+1) = matlab.mixin.util.PropertyGroup(env.ChannelInputFolders, "ChannelInputFolders");
                groups(end+1) = matlab.mixin.util.PropertyGroup(env.HyperParameters, "HyperParameters");
                groups(end+1) = matlab.mixin.util.PropertyGroup(env.ResourceConfig, "ResourceConfig");
                groups(end+1) = matlab.mixin.util.PropertyGroup(env.InputDataConfig, "InputDataConfig");

             else
                % Nonscalar case: call superclass method
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(env);
             end
        end
     end    
end

function val = getenv_or(name, default)
    arguments
        name string
        default string = string.empty()
    end
    val = string(getenv(name));
    val = strip(val, '"');
    val = strip(val, "'");
    if strlength(val)==0
        val = default;
    end
end

function val = getfield_or(s, name, default)
    if isfield(s, name)
        val = s.(name);
    else
        val = default;
    end
end

function val = or(val, default)
    if isempty(val)
        if isa(default, 'function_handle')
            val = default();
        else
            val = default;
        end
    end
end

function s = readjson(path)
    s = struct();
    if exist(path, "file") == 2
        s = jsondecode(fileread(path));
    end
end

function [included, excluded] = split(s, keys, prefix)
    arguments
        s struct
        keys string
        prefix string 
    end
    included = struct();
    excluded = struct();
    for key = string(fieldnames(s)).'
        if ismember(key, keys) || key.startsWith(prefix)
            included.(key) = s.(key);
        else
            excluded.(key) = s.(key);
        end
    end
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