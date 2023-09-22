
# <span style="color:rgb(213,80,0)">Deploying an existing model</span>
## Set up
```matlab
if isMATLABReleaseOlderThan('R2023a')
    error('This example requires MATLAB R2023a')
end
```

Add MATLAB code to path,

```matlab
thisFolder = fileparts(which('DeployExistingModelExample.mlx'));
assert(~isempty(thisFolder), "cd to example folder");
rootFolder = fullfile(thisFolder, '..', '..');
addpath(fullfile(rootFolder, "matlab"));
```

Set up Python venv that has sagemaker & docker SDKs

```matlab
sagemaker.pyenv(thisFolder);
```
# Create SageMaker session
```matlab
session = sagemaker.Session();
```

Define the IAM role that training jobs and deployed models will use.


<samp>Note: sagemaker.getExecutionRole</samp> works on a SageMaker notebook instance, but elsewhere the role on local machine might not have the required access. This role does.

```matlab
role = sprintf("arn:aws:iam::%s:role/service-role/AmazonSageMaker-ExecutionRole-20210727T152745", session.AccountID);
```
# Train a model locally 
```matlab
load fisheriris.mat
species = string(species);
sepal_length = meas(:,1);
sepal_width = meas(:,2);
petal_length = meas(:,3);
petal_width = meas(:,4);
trainingData = table(species, sepal_length, sepal_width, petal_length, petal_width)
```
| |species|sepal_length|sepal_width|petal_length|petal_width|
|:--:|:--:|:--:|:--:|:--:|:--:|
|1|"setosa"|5.1000|3.5000|1.4000|0.2000|
|2|"setosa"|4.9000|3|1.4000|0.2000|
|3|"setosa"|4.7000|3.2000|1.3000|0.2000|
|4|"setosa"|4.6000|3.1000|1.5000|0.2000|
|5|"setosa"|5|3.6000|1.4000|0.2000|
|6|"setosa"|5.4000|3.9000|1.7000|0.4000|
|7|"setosa"|4.6000|3.4000|1.4000|0.3000|
|8|"setosa"|5|3.4000|1.5000|0.2000|
|9|"setosa"|4.4000|2.9000|1.4000|0.2000|
|10|"setosa"|4.9000|3.1000|1.5000|0.1000|
|11|"setosa"|5.4000|3.7000|1.5000|0.2000|
|12|"setosa"|4.8000|3.4000|1.6000|0.2000|
|13|"setosa"|4.8000|3|1.4000|0.1000|
|14|"setosa"|4.3000|3|1.1000|0.1000|

```matlab

model = fitcdiscr(trainingData, "species");
save("model.mat", "model");
```
## Copy model to s3
```matlab
tar("model.tar.gz", "model.mat")
modelData = "s3://" + session.DefaultBucket + "/locally_trained_model/model.tar.gz";
copyfile("model.tar.gz", modelData);
```
## Deploy this model as a SageMaker endpoint

Since this model is a ClassificationDiscriminant we need a infernece handler that can deal with that type.

```matlab
smmodel = sagemaker.MATLABModel(modelData, role, "ClassificationDiscriminantInferenceHandler", session);
```

```TextOutput
Building production server archive for ClassificationDiscriminantInferenceHandler
Building docker image classificationdiscriminantinferencehandler
Runtime Image Already Exists
DOCKER CONTEXT LOCATION:
/local-ssd/ralcock/github.com/mathworks/Machine-Learning-with-MATLAB-and-Amazon-Sagemaker-Demo/examples/DeployExistingModel/ClassificationDiscriminantInferenceHandlerproductionServerArchive/sagemaker
FOR HELP GETTING STARTED WITH MICROSERVICE IMAGES, PLEASE READ:
/local-ssd/ralcock/github.com/mathworks/Machine-Learning-with-MATLAB-and-Amazon-Sagemaker-Demo/examples/DeployExistingModel/ClassificationDiscriminantInferenceHandlerproductionServerArchive/sagemaker/GettingStarted.txt
Sending build context to Docker daemon  163.8kB
Step 1/11 : FROM matlabruntime/r2023a/release/update0/f09040000000000000
 ---> 386c7edc62af
Step 2/11 : COPY ./applicationFilesForMATLABCompiler /usr/bin/mlrtapp
 ---> f6b07118e1d1
Step 3/11 : RUN chmod -R a+rX /usr/bin/mlrtapp/*
 ---> Running in 4aedbb7f07b3
Removing intermediate container 4aedbb7f07b3
 ---> 77355c862bfc
Step 4/11 : COPY ./routesFile /etc/matlabruntime/routes
 ---> fcb5de8e5035
Step 5/11 : RUN chmod -R a+rX /etc/matlabruntime/routes/*
 ---> Running in 499a89d47604
Removing intermediate container 499a89d47604
 ---> 1dbf0139f32f
Step 6/11 : RUN mkdir /etc/matlabruntime/helpers
 ---> Running in d06193a16665
Removing intermediate container d06193a16665
 ---> 31ca628c39c0
Step 7/11 : COPY ./entrypoint.sh /etc/matlabruntime/helpers/.
 ---> 29cacc980e8f
Step 8/11 : RUN chmod -R +x /etc/matlabruntime/helpers/*
 ---> Running in f1c99f96a8f5
Removing intermediate container f1c99f96a8f5
 ---> 488ec8c15b67
Step 9/11 : ENV SAGEMAKER_INFERENCE_HANDLER=ClassificationDiscriminantInferenceHandler
 ---> Running in 906ffaf261fe
Removing intermediate container 906ffaf261fe
 ---> 994b9dc9e5ee
Step 10/11 : RUN useradd -ms /bin/bash appuser
 ---> Running in 193c9b1fdae9
Removing intermediate container 193c9b1fdae9
 ---> ff0f0d988bb9
Step 11/11 : ENTRYPOINT /etc/matlabruntime/helpers/entrypoint.sh
 ---> Running in ed56ae084390
Removing intermediate container ed56ae084390
 ---> 94f2a3b29dfb
Successfully built 94f2a3b29dfb
Successfully tagged classificationdiscriminantinferencehandler:latest
Tagging and pushing classificationdiscriminantinferencehandler
Using existing repo classificationdiscriminantinferencehandler
Tagging classificationdiscriminantinferencehandler
Pushing image to ecr
Creating sagemaker model
```

```matlab
predictor = smmodel.deploy(uint8(1), "ml.m5.large")
```

```TextOutput
Deploying sagemaker model
----!
predictor = 
  MATLABPredictor with properties:
    EndpointName: "classificationdiscriminantinferencehand-2023-08-21-10-57-55-247"
```
# Make a prediction

This sends an HTTP request to the deployed endpoint

```matlab
sepal_length=5.1;sepal_width=3.5; petal_length=1.4;petal_width=0.2;
input = table(sepal_length,sepal_width,petal_length,petal_width)
```
| |sepal_length|sepal_width|petal_length|petal_width|
|:--:|:--:|:--:|:--:|:--:|
|1|5.1000|3.5000|1.4000|0.2000|

```matlab
prediction = predictor.predict(input)
```
| |species|
|:--:|:--:|
|1|'setosa'|

# Cleanup
```matlab
predictor.deleteModel();
predictor.deleteEndpoint();
```
