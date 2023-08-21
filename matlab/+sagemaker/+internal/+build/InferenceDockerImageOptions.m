classdef InferenceDockerImageOptions
% InferenceDockerImageOptions

% Copyright 2023 The MathWorks, Inc.    

    properties(SetAccess=private)
        MicroserviceDockerImageOptions compiler.package.MicroserviceDockerImageOptions
        InferenceRouter string
        InferenceHandler string
    end
    properties(Dependent)
        ImageName
        DockerContext
    end
    methods
        function opts = InferenceDockerImageOptions(buildResults, args)
            arguments
                buildResults compiler.build.Results
                args.ImageName string
                args.InferenceRouter string = "sagemaker_inference.DefaultInferenceRouter"
                args.InferenceHandler string = "sagemaker_inference.DefaultInferenceHandler"
            end
            if ~isfield(args, "ImageName")
                args.ImageName = buildResults.buildOptions.ArchiveName + "Image";
            end
            opts.MicroserviceDockerImageOptions = compiler.package.MicroserviceDockerImageOptions(ImageName=args.ImageName);

            dockerContext = fullfile(buildResults.Options.OutputDir, "sagemaker");

            dockerfileSagemaker = fullfile(dockerContext, 'Dockerfile.sagemaker');
            extrypoint = fullfile(dockerContext, 'entrypoint.sh');
            
            if exist(dockerfileSagemaker, 'file')==2
                delete(dockerfileSagemaker);
            end
            if exist(extrypoint, 'file')==2
                delete(extrypoint)
            end

            opts.MicroserviceDockerImageOptions.DockerContext = dockerContext;
            
            opts.MicroserviceDockerImageOptions.ExecuteDockerBuild = "off";
            opts.InferenceRouter = args.InferenceRouter;
            opts.InferenceHandler = args.InferenceHandler;
         
            commands(1) = "RUN mkdir /etc/matlabruntime/helpers";
            commands(2) = "COPY ./entrypoint.sh /etc/matlabruntime/helpers/.";
            commands(3) = "RUN chmod -R +x /etc/matlabruntime/helpers/*";
            commands(4) = "ENV SAGEMAKER_INFERENCE_HANDLER="+ opts.InferenceHandler;
            opts.MicroserviceDockerImageOptions.AdditionalInstructions = commands;

        end
        function imageName = get.ImageName(opts)
            imageName = opts.MicroserviceDockerImageOptions.ImageName;
        end
        function dockerContext = get.DockerContext(opts)
            dockerContext = opts.MicroserviceDockerImageOptions.DockerContext;
        end   
    end
end
