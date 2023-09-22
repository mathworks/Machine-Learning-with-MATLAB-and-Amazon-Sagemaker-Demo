
# <span style="color:rgb(213,80,0)">Training and deploying a MATLAB classification tree using Amazon SageMaker</span>
# Set up
```matlab
if isMATLABReleaseOlderThan('R2023a')
    error('This example requires MATLAB R2023a')
end
if ispc()
    error('This example is not supported on Windows')
end
```
## Add code to MATLAB path
```matlab
thisFolder = fileparts(which('TrainAndDeployClassificationTreeExample.mlx'));
assert(~isempty(thisFolder), "please cd to example folder");
rootFolder = fullfile(thisFolder, '..', '..');
addpath(fullfile(rootFolder, "matlab"));
```
## Set up Python environment

This has both the SageMaker & Docker SDKs installed

```matlab
sagemaker.pyenv(thisFolder);
```
## Create SageMaker session
```matlab
session = sagemaker.Session();
```
## IAM Role

Define the IAM role that training jobs and deployed models will use.


<samp>Note: py.sagemaker.getExecutionRole</samp> works on a SageMaker notebook instance, but elsewhere the role on local machine might not have the required access, so we hardcode a IAM role that does have required access.

```matlab
role = sprintf("arn:aws:iam::%s:role/service-role/AmazonSageMaker-ExecutionRole-20210727T152745", session.AccountID);
```
## Get name of training image

Get the name of training image that was previously built and pushed to Amazon Elastic Container Registry from docker folder.

```matlab
trainingImage = sprintf("%s.dkr.ecr.%s.amazonaws.com/matlab-sagemaker-training-%s:latest", session.AccountID, session.BotoRegionName, "r"+version('-release'));
```
# Create an estimator

Fitting this estimator will create a training job

```matlab
est = sagemaker.MATLABEstimator(...
    role, ...
    Session=session, ...
    Image=trainingImage, ...
    BaseJobName="MATLABBinaryDecisionTreeEstimator", ...
    Environment = loadenv(fullfile(rootFolder, "training.env")), ...
    TrainingFunction = @trainingFunction, ...
    HyperParameters = struct(), ... % named args to train_decision_tree
    InstanceType="ml.m5.large", ...
    MaxRunTime=minutes(10), ...    
    MaxWaitTime=minutes(20), ...
    UseSpotInstances=true);
```

```TextOutput
Analysing files required by training function
Packaging required files as a mltbx
Moved mltbx to default bucket
```
# Train the model
```matlab
load fisheriris.mat
species = string(species);
sepal_length = meas(:,1);
sepal_width = meas(:,2);
petal_length = meas(:,3);
petal_width = meas(:,4);
iris = table(species, sepal_length, sepal_width, petal_length, petal_width)
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

## Write training data to s3
```matlab
trainingDataLocation = "s3://" + session.DefaultBucket + "/data/training";
writetable(iris, trainingDataLocation+"/iri.csv")
```
## Create training job

We won't wait for this - this demonstrates how we could schedule multiple training jobs and attach to them later.

```matlab
est.fit(training=struct(Location=trainingDataLocation, ContentType="text/csv"), Wait=false)
```

```TextOutput
INFO:sagemaker:Creating training-job with name: MATLABBinaryDecisionTreeEstimator-2023-08-23-10-29-03-680
```

```matlab
trainingJob = est.LatestTrainingJob
```

```TextOutput
trainingJob = 
  TrainingJob with properties:
               Name: "MATLABBinaryDecisionTreeEstimator-2023-08-23-10-29-03-680"
             Status: "InProgress"
    SecondaryStatus: "Starting"
```

Since we didn't wait, so we now attach to the job - this will block until training is complete

```matlab
est = sagemaker.MATLABEstimator.attach(trainingJob.Name, session);
```

```TextOutput
2023-08-21 10:02:37 Starting - Preparing the instances for training
2023-08-21 10:02:37 Downloading - Downloading input data
2023-08-21 10:02:37 Training - Training image download completed. Training in progress.
2023-08-21 10:02:37 Uploading - Uploading generated training model
2023-08-21 10:02:37 Completed - Training job completed
```

Load the trained model

```matlab
localmodeltar = tempname;
copyfile(est.ModelData, localmodeltar);
files = untar(localmodeldata, tempname);
trained = load(files{1}, 'model');
disp(trained.model)
```

```TextOutput
  ClassificationTree
           PredictorNames: {'sepal_length'  'sepal_width'  'petal_length'  'petal_width'}
             ResponseName: 'species'
    CategoricalPredictors: []
               ClassNames: {'setosa'  'versicolor'  'virginica'}
           ScoreTransform: 'none'
          NumObservations: 300
  Properties, Methods
```
# Deploy the model

Deploying the model:

-  compiles <samp>ClassificationTreeInferenceHandler</samp>.m (and s<samp>agemaker_inference.DefaultInferenceRouter</samp>) as a production server archive 
-  builds a (modified) microservice container 
-  pushes that container to ECR 
-  Deploys the model using that container as a sagemaker endpoint 

<samp>ClassificationTreeInferenceHandler</samp> is a class that implements model evaluation for models of type <samp>ClassificationTree</samp>.

```matlab
predictor = est.deploy(role, "ClassificationTreeInferenceHandler", uint8(1), "ml.m5.large")
```

```TextOutput
Building production server archive for ClassificationTreeInferenceHandler
Building docker image classificationtreeinferencehandler
Runtime Image Already Exists
DOCKER CONTEXT LOCATION:
/local-ssd/ralcock/github.com/mathworks/Machine-Learning-with-MATLAB-and-Amazon-Sagemaker-Demo/examples/TrainAndDeployClassificationTree/ClassificationTreeInferenceHandlerproductionServerArchive/sagemaker
FOR HELP GETTING STARTED WITH MICROSERVICE IMAGES, PLEASE READ:
/local-ssd/ralcock/github.com/mathworks/Machine-Learning-with-MATLAB-and-Amazon-Sagemaker-Demo/examples/TrainAndDeployClassificationTree/ClassificationTreeInferenceHandlerproductionServerArchive/sagemaker/GettingStarted.txt
Sending build context to Docker daemon  163.8kB
Step 1/11 : FROM matlabruntime/r2023a/release/update0/f09040000000000000
 ---> 386c7edc62af
Step 2/11 : COPY ./applicationFilesForMATLABCompiler /usr/bin/mlrtapp
 ---> 31d05f4013e1
Step 3/11 : RUN chmod -R a+rX /usr/bin/mlrtapp/*
 ---> Running in 705592d052b2
Removing intermediate container 705592d052b2
 ---> e3327f2aa025
Step 4/11 : COPY ./routesFile /etc/matlabruntime/routes
 ---> e0d3d1900b10
Step 5/11 : RUN chmod -R a+rX /etc/matlabruntime/routes/*
 ---> Running in 4f6d4aa10bea
Removing intermediate container 4f6d4aa10bea
 ---> 18be12e094cd
Step 6/11 : RUN mkdir /etc/matlabruntime/helpers
 ---> Running in 4bba80dc1351
Removing intermediate container 4bba80dc1351
 ---> f1d18106cc7c
Step 7/11 : COPY ./entrypoint.sh /etc/matlabruntime/helpers/.
 ---> 66c2860c0017
Step 8/11 : RUN chmod -R +x /etc/matlabruntime/helpers/*
 ---> Running in 6f2ddefecff6
Removing intermediate container 6f2ddefecff6
 ---> be08407a9bae
Step 9/11 : ENV SAGEMAKER_INFERENCE_HANDLER=ClassificationTreeInferenceHandler
 ---> Running in 89a3060d8f2b
Removing intermediate container 89a3060d8f2b
 ---> 3a0bc06dbccf
Step 10/11 : RUN useradd -ms /bin/bash appuser
 ---> Running in c70d6d100095
Removing intermediate container c70d6d100095
 ---> fb08ecb97a18
Step 11/11 : ENTRYPOINT /etc/matlabruntime/helpers/entrypoint.sh
 ---> Running in 6f9b934ca580
Removing intermediate container 6f9b934ca580
 ---> 2853fddf794d
Successfully built 2853fddf794d
Successfully tagged classificationtreeinferencehandler:latest
Tagging and pushing classificationtreeinferencehandler
Using existing repo classificationtreeinferencehandler
Tagging classificationtreeinferencehandler
Pushing image to ecr
Creating sagemaker model
Deploying sagemaker model
INFO:sagemaker:Creating model with name: classificationtreeinferencehandler-2023-08-21-10-33-35-706
INFO:sagemaker:Creating endpoint-config with name classificationtreeinferencehandler-2023-08-21-10-33-36-523
INFO:sagemaker:Creating endpoint with name classificationtreeinferencehandler-2023-08-21-10-33-36-523
----!
predictor = 
  MATLABPredictor with properties:
    EndpointName: "classificationtreeinferencehandler-2023-08-21-10-33-36-523"
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
```

```TextOutput
INFO:sagemaker:Deleting model with name: classificationtreeinferencehandler-2023-08-21-10-33-35-706
```

```matlab
predictor.deleteEndpoint();
```

```TextOutput
INFO:sagemaker:Deleting endpoint configuration with name: classificationtreeinferencehandler-2023-08-21-10-33-36-523
INFO:sagemaker:Deleting endpoint with name: classificationtreeinferencehandler-2023-08-21-10-33-36-523
```
# Training Function
```matlab
function trainingFunction(env, varargin)

trainingDataStore = tabularTextDatastore(...
    env.ChannelInputFolders.training, ...
    IncludeSubfolders=true, ...
    TextType="string");
trainingData = readall(trainingDataStore);

model = fitctree(trainingData, "species", varargin{:});

% Save the fitted model to /opt/ml/model/model.mat
save(fullfile(env.ModelFolder, 'model'), 'model');
end
```
