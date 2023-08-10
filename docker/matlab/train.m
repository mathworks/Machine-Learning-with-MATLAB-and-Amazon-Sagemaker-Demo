function train(varargin)
% train

% Copyright 2023 The MathWorks, Inc.
try 
    env = sagemaker_training.Environment();
    disp(env)
    entryPoint = sagemaker_training.EntryPoint(env);
    run(entryPoint);

    disp("Logging Success")
    success = true;
    save(fullfile(env.OutputFolder, "success"), "success");    
catch err
    disp("Logging Failure")
    report = getReport(err, "extended", "hyperlinks", "off");
    disp(report);
    
    f = fopen(fullfile(env.OutputFolder, "failure"), "wt");
    fileCloser = onCleanup(@()fclose(f));
    
    fprintf(f, "%s", report);    
end