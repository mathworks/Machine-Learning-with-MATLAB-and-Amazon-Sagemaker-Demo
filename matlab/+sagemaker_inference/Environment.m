classdef Environment
% Environment 
% Copyright 2023 The MathWorks, Inc.
    properties(Constant, Access=private)
        BASE_PATH_ENV string = "SAGEMAKER_BASE_DIR";
        SAGEMAKER_BASE_PATH string = fullfile("/", "opt", "ml")        
    end 
    properties(SetAccess=private)
        BaseFolder string
        ModelFolder string
        CodeFolder string
    end
    methods
        function env = Environment()
            env.BaseFolder = getenv_or(sagemaker_inference.Environment.BASE_PATH_ENV, sagemaker_inference.Environment.SAGEMAKER_BASE_PATH);
            env.ModelFolder = fullfile(env.BaseFolder, "model");
            env.CodeFolder = fullfile(env.BaseFolder, "code");
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