classdef DefaultInferenceHandler
% DefaultInferenceHandler

% Copyright 2023 The MathWorks, Inc.
    methods
        function inputDataTable = decode_input(obj, inputData, contentType)
            arguments
                obj sagemaker_inference.DefaultInferenceHandler %#ok<INUSA>
                inputData string
                contentType string = "text/csv"
            end
            if contentType=="text/csv"
                inputDataTable = sagemaker_inference.readTableFromString(inputData, 'FileType', 'delimitedtext', 'Delimiter', ',', 'TextType', 'string');
            else
                error("Unsupported ContentType: " + contentType);
            end
           
        end
        function model = load_model(obj, modelFolder)
            arguments
                obj sagemaker_inference.DefaultInferenceHandler %#ok<INUSA>
                modelFolder string
            end
            loaded = load(fullfile(modelFolder, "model"), "model");
            model = loaded.model;
        end
        function prediction = predict(obj, inputData, model)
            arguments
                obj sagemaker_inference.DefaultInferenceHandler %#ok<INUSA>
                inputData table
                model
            end
            prediction = model(inputData);
        end
        function outputData = encode_output(obj, prediction, accept)
            arguments
                obj sagemaker_inference.DefaultInferenceHandler %#ok<INUSA>
                prediction table
                accept string
            end
            
            if accept=="*/*" || accept=="text/csv"
                outputData = sagemaker_inference.writeTableToString(prediction, 'FileType', 'text', 'Delimiter', ',');
            else
                error("Unsupported Accept: " + accept);
            end                
        end
    end
    methods
        function response = ping(obj, request)
            arguments
                obj sagemaker_inference.DefaultInferenceHandler %#ok<INUSA>
                request struct %#ok<INUSA>
            end
            response = struct('ApiVersion', [1 0 0], ...
                'HttpCode', 200, ...
                'HttpMessage', 'OK', ...
                'Body', uint8.empty(1,0));
        end
        
        function response = invocations(obj, request)
            arguments
                obj sagemaker_inference.DefaultInferenceHandler
                request struct
            end
            
            headers = request.Headers.';
            headers = dictionary(headers{:});
            
            env = sagemaker_inference.Environment();
            
            inputData = decode_input(obj, char(request.Body), headers("Content-Type"));
            model = load_model(obj, env.ModelFolder);
            prediction = predict(obj, inputData, model);
            outputData = encode_output(obj, prediction, headers("Accept"));
            
            response = struct('ApiVersion', [1 0 0], ...
                'HttpCode', 200, ...
                'HttpMessage', 'OK', ...
                'Body', uint8(char(outputData)));
        end
    end

end