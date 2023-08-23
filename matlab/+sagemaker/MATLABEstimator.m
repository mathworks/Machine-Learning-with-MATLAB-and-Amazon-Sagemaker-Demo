classdef MATLABEstimator
% MATLABEstimator

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=private)
        Session
        SageMakerEstimator
    end
    properties(Dependent)
        ModelData string
        LatestTrainingJob sagemaker.TrainingJob
    end
    methods(Static)
        function est = attach(jobName, session)
            arguments
                jobName string
                session sagemaker.Session = sagemaker.Session(botoSession=py.boto3.session.Session)
            end
            pyest = py.sagemaker.estimator.Estimator.attach(jobName, sagemaker_session=session.SageMakerSession);
            est = sagemaker.MATLABEstimator(SageMakerEstimator=pyest, Session=session);
        end
    end
    methods
        function loc = get.ModelData(obj)
            loc = string(obj.SageMakerEstimator.model_data);
        end
        function trainngJob = get.LatestTrainingJob(obj)
            trainngJob = sagemaker.TrainingJob(obj.SageMakerEstimator.latest_training_job);
        end
        function obj = MATLABEstimator(role, args)
            arguments
                role string = string.empty()
                args.Session sagemaker.Session = sagemaker.Session(botoSession=py.boto3.session.Session)
                args.Image string
                args.SageMakerEstimator py.sagemaker.estimator.Estimator
                args.InstanceType string = string.empty()
                args.BaseJobName string = string.empty()
                args.TrainingFunction function_handle
                args.MATLABRelease string = "r"+version('-release')
                args.HyperParameters struct = struct()
                args.Environment dictionary = dictionary(string.empty, string.empty)
                args.MaxRunTime duration = days(1)
                args.UseSpotInstances logical = false
                args.MaxWaitTime duration = duration.empty()
                args.Subnets string = string.empty()
                args.SecurityGroupsIds string = string.empty()
                args.Tags cell = {}
            end
            obj.Session = args.Session;

            if isfield(args, 'SageMakerEstimator')
                obj.SageMakerEstimator = args.SageMakerEstimator;
            else
                if isempty(args.BaseJobName)
                    args.BaseJobName = extractBetween(args.Image, "/", ":");
                end
                jobName = addTimestampToBaseName(args.BaseJobName);
                
                % Make a mltbx that has all the code needed for this training job
                % userEntryPointName is name of MAT file in the toolbox
                % containing the training function
                [toolboxFile, userEntryPointName, requiredProducts] = sagemaker.internal.packageTrainingFunction(args.TrainingFunction, jobName);

                % Move the mltbx to s3
                sourceLocation = "s3://" + obj.Session.DefaultBucket + "/" + jobName + "/source/" + jobName + ".mltbx";
                makeFolderOrError(fileparts(sourceLocation))                
                movefile(toolboxFile, sourceLocation);
                disp("Moved mltbx to default bucket");

                args.HyperParameters.sagemaker_submit_directory = sourceLocation;

                args.HyperParameters.sagemaker_program = userEntryPointName; 

                instanceCount = uint64(1);

                if isempty(args.MaxWaitTime)
                    maxWaitTime = py.None;
                else
                    maxWaitTime = uint64(seconds(args.MaxWaitTime));
                end
                maxRunTime = uint64(seconds(args.MaxRunTime));

                tags = args.Tags;
                if isempty(args.Subnets)
                    args.Subnets = py.None;
                end
                if isempty(args.SecurityGroupsIds)
                    args.SecurityGroupsIds = py.None;
                end

                environment=dictionary2struct(args.Environment);

                if ~isempty(requiredProducts)
                    requiredProducts = replace(requiredProducts, ' ', '_'); % for mpm
                    environment.MATLAB_REQUIRED_PRODUCTS = join(requiredProducts);
                end

                obj.SageMakerEstimator = py.sagemaker.estimator.Estimator(...
                    args.Image, ...
                    role, ...
                    sagemaker_session=obj.Session.SageMakerSession, ...
                    instance_count=instanceCount, ...
                    instance_type=args.InstanceType, ...
                    base_job_name=args.BaseJobName, ...
                    hyperparameters=args.HyperParameters, ...
                    environment=environment, ...
                    tags=tags, ...
                    subnets=args.Subnets, ...
                    security_group_ids=args.SecurityGroupsIds, ...
                    max_run=maxRunTime, ...
                    use_spot_instances=args.UseSpotInstances, ...
                    max_wait=maxWaitTime);
            end
        end

        function fit(obj, channelConfigs, args)
            arguments
                obj
            end
            arguments(Repeating)
                channelConfigs
            end
            arguments
                args.Wait logical = true
                args.JobName = [];
            end

            configs = struct();
            for idx=1:2:length(channelConfigs)
                channelName = channelConfigs{idx};
                channelConfig = channelConfigs{idx+1};
                configs.(channelName) = py.sagemaker.inputs.TrainingInput(channelConfig.Location, content_type=channelConfig.ContentType);
            end
            obj.SageMakerEstimator.fit(inputs=configs, wait=args.Wait, job_name=args.JobName, logs='None'); % Can't have logs due to G2711718
        end

        function predictor = deploy(obj, role, inferenceHandler, instanceCount, instanceType)
            arguments
                obj
                role
                inferenceHandler string
                instanceCount {mustBeInteger}
                instanceType string
            end

            mdl = sagemaker.MATLABModel(obj.ModelData, role, inferenceHandler, obj.Session);
            predictor = mdl.deploy(uint64(instanceCount), instanceType);
        end
    end
end

function jobName = addTimestampToBaseName(base, maxLength)
arguments
    base string
    maxLength = 63
end
timestamp = string(datetime('now', 'Format','yyyy-MM-dd-HH-mm-ss-SSS'));
jobName = base.extractBefore(min(strlength(base), maxLength)) + "-" + timestamp;
end

function s = dictionary2struct(dict)
s = struct();
for key = keys(dict).'
    s.(key) = dict(key);
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