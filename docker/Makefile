# Copyright 2023 The MathWorks, Inc.

ROOT_DIR:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

ifndef VERBOSE
HIDE := @
endif

MATLAB_RELEASE ?= r2023a
REPO_NAME := matlab-sagemaker-training-$(MATLAB_RELEASE)

ENVFILE=$(ROOT_DIR)../.env
$(shell touch $(ENVFILE))

DOCKER ?= docker

AWS ?= $(DOCKER) run --rm -it -e AWS_PAGER= --env-file=$(ENVFILE) -e AWS_PROFILE -e AWS_DEFAULT_PROFILE -v ~/.aws:/root/.aws -v $(ROOT_DIR):/workspace docker.io/amazon/aws-cli

AWS_REGION := $(shell $(AWS) configure get region)
AWS_ACCOUNT_ID := $(shell $(AWS) sts get-caller-identity --query "Account" --output text)

ECR_REG := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
ECR_NAME := $(ECR_REG)/$(REPO_NAME)


build:
	$(HIDE)$(DOCKER) build --build-arg MATLAB_RELEASE=$(MATLAB_RELEASE) -t $(REPO_NAME) .

push:
	$(HIDE)$(DOCKER) tag $(REPO_NAME) $(ECR_NAME)
	$(HIDE)$(AWS) ecr get-login-password | docker login --username AWS --password-stdin $(ECR_REG)
	$(HIDE)$(AWS) ecr describe-repositories --repository-names $(REPO_NAME) || $(AWS) ecr create-repository --repository-name $(REPO_NAME)
	$(HIDE)$(DOCKER) push $(ECR_NAME)

test-local:
	$(HIDE)$(MAKE) -C ./test REPO_NAME=$(REPO_NAME) DOCKER=$(DOCKER)

.PHONY: build push test-local
