classdef ClassificationDiscriminantInferenceHandler < sagemaker_inference.DefaultInferenceHandler
% ClassificationDiscriminantInferenceHandler

% Copyright 2023 The MathWorks, Inc.
    methods
        function prediction = predict(~, inputData, model)
            %#function ClassificationDiscriminant
            prediction = predict(model, inputData);
            prediction = table(prediction, 'VariableNames', string(model.ResponseName));
        end
    end
end