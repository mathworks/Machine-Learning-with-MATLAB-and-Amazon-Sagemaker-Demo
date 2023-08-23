classdef TrainingJob
    
    properties(SetAccess=private, Hidden)
        SageMakerTrainingJob
    end
    
    properties(Dependent)
        Name
        Status
        SecondaryStatus
        FailureReason
    end
    
    methods
        function obj = TrainingJob(trainingJob)
            obj.SageMakerTrainingJob = trainingJob;
        end        
        function name = get.Name(j)
            name = string(j.SageMakerTrainingJob.name);
        end
        function status = get.Status(j)
            desc = describe(j.SageMakerTrainingJob);
            status = string(desc{'TrainingJobStatus'});
        end
        function status = get.SecondaryStatus(j)
            desc = describe(j.SageMakerTrainingJob);
            status = string(desc{'SecondaryStatus'});
        end
        function status = get.FailureReason(j)
            desc = describe(j.SageMakerTrainingJob);
            status = string(desc{'FailureReason'});
        end
    end
end

