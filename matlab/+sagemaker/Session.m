classdef Session
% Session

% Copyright 2023 The MathWorks, Inc.

    properties(SetAccess=private)
        SageMakerSession
    end

    properties(Dependent)
        AccountID
        BotoRegionName
        DefaultBucket
    end
    
    methods
        function obj = Session(args)
            arguments
                args.botoSession = py.boto3.session.Session;
            end
            obj.SageMakerSession = py.sagemaker.session.Session(boto_session=args.botoSession);
        end
        
        function botoRegionName = get.BotoRegionName(obj)
            botoRegionName = string(obj.SageMakerSession.boto_region_name);
        end

        function defaultBucket = get.DefaultBucket(obj)
            defaultBucket = string(obj.SageMakerSession.default_bucket());
        end
        
        function accountid = get.AccountID(obj)
            accountid = string(obj.SageMakerSession.account_id());
        end
    end
end

