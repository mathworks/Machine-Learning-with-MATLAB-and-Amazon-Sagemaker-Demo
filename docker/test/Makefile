ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
BASE_DIR=$(ROOT_DIR)/opt/ml

.PHONY: test interactive

tests:
	@mkdir -p $(BASE_DIR)/model
	@rm -fr $(BASE_DIR)/model/*
	@mkdir -p $(BASE_DIR)/output
	@rm -fr $(BASE_DIR)/output/*
	$(DOCKER) run -v ~/.aws:/root/.aws -v $(ROOT_DIR)/matlab/:/submit_dir -v $(BASE_DIR):/opt/ml -v --rm --env-file=../../training.env -e MATLAB_REQUIRED_PRODUCTS=Optimization_Toolbox $(REPO_NAME) train

interactive:
	$(DOCKER) run -v $(BASE_DIR):/opt/ml -v $(ROOT_DIR)/matlab/:/submit_dir --rm --env-file=../../training.env -it --entrypoint bash $(REPO_NAME) 	