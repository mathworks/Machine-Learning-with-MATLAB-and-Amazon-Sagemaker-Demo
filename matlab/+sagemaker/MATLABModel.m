classdef MATLABModel
% MATLABModel

% Copyright 2023 The MathWorks, Inc.

    properties(Access=private)
        Session
        SageMakerModel 
    end
    properties(Dependent)
        Name string
        EndpointName string
    end
    methods
        function obj = MATLABModel(modelData, role, inferenceHandler, session)
            arguments
                modelData string
                role string
                inferenceHandler string = "sagemaker_inference.DefaultInferenceHandler"
                session = sagemaker.Session()
            end
            obj.Session = session;
            imageName = lower(inferenceHandler);

            % Create a archive for running predictions/inference for this model
            functionFiles = {which("sagemaker_inference.DefaultInferenceRouter"), which(inferenceHandler)};
            buildOptions = compiler.build.ProductionServerArchiveOptions(...
                functionFiles, ...
                ArchiveName=inferenceHandler, ...
                Verbose=false);

            disp("Building production server archive for " + inferenceHandler)
            buildResults = compiler.build.productionServerArchive(buildOptions);
    
            % Package that as a (modified) microservice docker image
            packageOptions = sagemaker.internal.build.InferenceDockerImageOptions(buildResults, ...
                ImageName=imageName, ...
                InferenceHandler=inferenceHandler);

            disp("Building docker image " + imageName)
            sagemaker.internal.build.inferenceDockerImage(buildResults, Options=packageOptions);

            % Push image to ECR
            disp("Tagging and pushing " + imageName);
            repoUri = sagemaker.internal.tagAndPushToECR(obj.Session, imageName);

            disp("Creating sagemaker model for " + repoUri)
            obj.SageMakerModel = py.sagemaker.model.Model(...
                repoUri, modelData, ...
                role=role, sagemaker_session=session.SageMakerSession);
        end

        function name = get.Name(obj)
            name = string(obj.SageMakerModel.name);
        end

        function name = get.EndpointName(obj)
            name = string(obj.SageMakerModel.endpoint_name);
        end

        function pred = deploy(obj, instanceCount, instanceType)
            arguments
                obj
                instanceCount {mustBeInteger}
                instanceType string            
            end           
            disp("Deploying sagemaker model");
            obj.SageMakerModel.deploy(uint64(instanceCount), instanceType);
            pred = sagemaker.MATLABPredictor(obj.SageMakerModel.endpoint_name, obj.Session);
        end
    end
end
