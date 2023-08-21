function inferenceDockerImage(buildResults, args)
% inferenceDockerImage

% Copyright 2023 The MathWorks, Inc.    
    arguments
        buildResults compiler.build.Results  
        args.Options sagemaker.internal.build.InferenceDockerImageOptions
    end

    % Write the routes file
    routesFile = fullfile(tempname, "routes.json");    
    microserviceDockerImageOptions = args.Options.MicroserviceDockerImageOptions;
    microserviceDockerImageOptions.RoutesFile = writeRoutesFile(buildResults.Options.ArchiveName, args.Options.InferenceRouter, routesFile);
    deleteRoutes = onCleanup(@()delete(microserviceDockerImageOptions.RoutesFile));

    compiler.package.microserviceDockerImage(buildResults, Options=microserviceDockerImageOptions);  

    DockerfileLines = splitlines(string(fileread(fullfile(args.Options.DockerContext, "Dockerfile"))));
  
    d = fopen(fullfile(args.Options.DockerContext, "Dockerfile.sagemaker"), "w+");
    dc = onCleanup(@()fclose(d));
    e = fopen(fullfile(args.Options.DockerContext, "entrypoint.sh"), "wt+");
    ec = onCleanup(@()fclose(e));
  
    for DockerFileLine=DockerfileLines.' 
        if DockerFileLine.startsWith("ENTRYPOINT")
            % Write entrypoint.sh that will call the original ENTRYPOINT
            entrypoint = string(jsondecode(DockerFileLine.extractAfter("ENTRYPOINT")));
            fprintf(e, "#!/bin/bash\n");
            fprintf(e, "set -euo pipefail\n");
            fprintf(e, "%s %s\n", join(entrypoint), "--http 8080 --log-severity trace"); % TODO: Use SAGEMAKER_BIND_TO_PORT if set
        
            DockerFileLine = 'ENTRYPOINT /etc/matlabruntime/helpers/entrypoint.sh'; %#ok<FXSET>
  
            fprintf(d, "%s\n", DockerFileLine);
        elseif DockerFileLine.startsWith("USER")
            % do nothing - we want to stay as ROOT in this case
        else
            fprintf(d, "%s\n", DockerFileLine);
        end
    end  

    origDir = cd(args.Options.DockerContext);
    restoreDir = onCleanup(@()cd(origDir));

    dockerBuildCmd = sprintf("docker build -f Dockerfile.sagemaker -t %s .", args.Options.ImageName);
    s = system(dockerBuildCmd);
    assert(s==0)

    delete([])
    
end

function routesFile = writeRoutesFile(componentName, routerName, routesFile)
    arguments
        componentName string
        routerName string
        routesFile string
    end
    routes.version = '1.0.0';
    routes.pathmap(1).match = '^/ping$';
    routes.pathmap(1).webhandler.component = componentName;
    routes.pathmap(1).webhandler.function = routerName;
    
    routes.pathmap(2).match = '^/invocations$';
    routes.pathmap(2).webhandler.component = componentName;
    routes.pathmap(2).webhandler.function = routerName;
    
    [success, msg] = mkdir(fileparts(routesFile));
    assert(success, msg);

    fid = fopen(routesFile, "wt");
    closer = onCleanup(@()fclose(fid));
    
    fprintf(fid, "%s", jsonencode(routes));
end