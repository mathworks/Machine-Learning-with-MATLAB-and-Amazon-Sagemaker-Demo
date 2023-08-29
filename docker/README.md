# Create a SageMaker training image that uses MATLAB

## Build the training image
This creates `matlab-sagemaker-training-$(MATLAB_RELEASE)`
````shell
make
````

## Test the image locally
The training image is designed to be run by Sagemaker as part of a training job. To test the image locally we need to re-create how Sagemaker will run the image.

````shell
make test-local
````

## Push the image to Amazon ECR
To use the image in a training job the image must be pushed to Amazon ECR. You must be signed into your AWS account to do this.
This creates the registry and pushes the image. The full name of the image in ECR is `$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/matlab-sagemaker-training-$(MATLAB_RELEASE):latest`
````shell
make push
````




