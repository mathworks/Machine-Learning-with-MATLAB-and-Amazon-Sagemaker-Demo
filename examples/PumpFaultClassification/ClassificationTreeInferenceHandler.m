classdef ClassificationTreeInferenceHandler < sagemaker_inference.DefaultInferenceHandler
    methods
        function prediction = predict(~, inputData, model)
            %#function ClassificationTree
            prediction = predict(model, inputData);
            prediction = table(prediction, 'VariableNames', string(model.ResponseName));
        end
    end
end