classdef ClassificationTreeInferenceHandler < sagemaker_inference.DefaultInferenceHandler
% ClassificationTreeInferenceHandler

% Copyright 2023 The MathWorks, Inc.

methods
        function prediction = predict(~, inputData, model)
            %#function ClassificationTree
            prediction = predict(model, inputData);
            prediction = table(prediction, 'VariableNames', string(model.ResponseName));
        end
    end
end