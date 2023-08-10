function response = DefaultInferenceRouter(request, handler)
% DefaultInferenceRouter

% Copyright 2023 The MathWorks, Inc.

    arguments
        request struct
        handler = []
    end

if isempty(handler)
    sagemaker_inference_handler = getenv("SAGEMAKER_INFERENCE_HANDLER");
    if ~isempty(sagemaker_inference_handler)
        handler = feval(sagemaker_inference_handler);
    else
        handler = sagemaker_inference.DefaultInferenceHandler();
    end
end

p = string(request.Path);

if p.endsWith("ping")
    response = handler.ping(request);
elseif p.endsWith("invocations")
    response = handler.invocations(request);
end

end

