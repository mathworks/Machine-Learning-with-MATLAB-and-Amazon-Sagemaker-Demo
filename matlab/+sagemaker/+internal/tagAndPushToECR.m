function repositoryUri = tagAndPushToECR(session, imageName)
% tagAndOPushtoECR
% Copyright 2023 The MathWorks, Inc.
    arguments
        session sagemaker.Session
        imageName string
    end

    ecr = session.SageMakerSession.boto_session.client('ecr');
    try 
        result = ecr.describe_repositories(repositoryNames={imageName});
        repository = result{'repositories'}{1};
        disp("Using existing repo " + imageName)
    catch 
        disp("Creating repo " + imageName)
        result = ecr.create_repository(repositoryName=imageName);
        repository = result{'repository'};
    end            
    repositoryUri = string(repository{'repositoryUri'});

    dockerClient = py.docker.from_env();
    disp("Tagging " + imageName + " as " + repositoryUri)
    ok = dockerClient.images.get(imageName+":latest").tag(repositoryUri+":latest");
    assert(ok, "Tagging failed")

    disp("Pushing image to " + repositoryUri)
    [username, password] = get_authorization_token(ecr);
    resp = dockerClient.api.push(repositoryUri, "latest", auth_config=struct(username=username, password=password));
    disp(resp)    
end

function [username, password] = get_authorization_token(ecr)
    authToken = ecr.get_authorization_token();
    decoded = py.base64.b64decode(authToken{'authorizationData'}{1}{'authorizationToken'});
    token = string(char(uint8(decoded)));
    username = extractBefore(token, ":");
    password = extractAfter(token, ":");
end