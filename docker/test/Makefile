ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
BASE_DIR=$(ROOT_DIR)opt/ml

DOCKER_RUN_ARGS:=-v ~/.aws:/root/.aws -v $(ROOT_DIR)matlab/:/submit_dir -v $(BASE_DIR):/opt/ml --rm --env-file=../../training.env

.PHONY: test interactive

test:
	@mkdir -p $(BASE_DIR)/model
	@rm -fr $(BASE_DIR)/model/*
	@mkdir -p $(BASE_DIR)/output
	@rm -fr $(BASE_DIR)/output/*
	$(DOCKER) run $(DOCKER_RUN_ARGS) -e MATLAB_REQUIRED_PRODUCTS=Optimization_Toolbox $(REPO_NAME) train

interactive:
	$(DOCKER) run $(DOCKER_RUN_ARGS) -it --entrypoint bash $(REPO_NAME) 	
