classdef Session
% Session

% Copyright 2023 The MathWorks, Inc.

    properties(SetAccess=private)
        SageMakerSession
    end

    properties(Dependent)
        DefaultBucket
        BotoRegionName
    end
    
    methods
        function obj = Session(args)
            arguments
                args.botoSession = py.boto3.session.Session;
            end
            obj.SageMakerSession = py.sagemaker.session.Session(boto_session=args.botoSession);
        end
        
        function defaultBucket = get.DefaultBucket(obj)
            defaultBucket = string(obj.SageMakerSession.default_bucket());
        end
        function botoRegionName = get.BotoRegionName(obj)
            botoRegionName = string(obj.SageMakerSession.boto_region_name);
        end
    end
end

