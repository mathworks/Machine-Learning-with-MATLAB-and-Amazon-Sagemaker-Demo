Create a matlab-batch based image for SageMaker training
````
echo AWS_ACCOUNT_ID := myaccount >> Makefile.env
echo AWS_REGION := myregion > Makefile.env
make && make test-local && make push
````
