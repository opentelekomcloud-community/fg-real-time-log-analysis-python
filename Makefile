SHELL := /bin/bash

# Terraform backend configuration
BACKEND_CONFIG_BUCKET := "doc-samples-tf-backend"
BACKEND_CONFIG_KEY := "terraform_state/python/real-time-log-analysis.tf"
BACKEND_CONFIG_REGION := "eu-de"
BACKEND_CONFIG_ENDPOINTS := "endpoints={s3=\"https://obs.eu-de.otc.t-systems.com\"}"

CURRENT_MAKEFILE := $(firstword $(MAKEFILE_LIST))

.SILENT: display_log_object

create_package:
	python3 createZip.py

tf_init:
	terraform -chdir=terraform \
	  init \
	  -backend-config=$(BACKEND_CONFIG_ENDPOINTS) \
	  -backend-config="bucket=$(BACKEND_CONFIG_BUCKET)" \
	  -backend-config="key=$(BACKEND_CONFIG_KEY)" \
	  -backend-config="region=$(BACKEND_CONFIG_REGION)"

tf_plan:
	if [ ! -f "terraform/.terraform.lock.hcl" ]; then \
		$(MAKE) -f $(CURRENT_MAKEFILE) tf_init; \
	fi
	terraform -chdir=terraform \
	  plan \
	  -var-file="variables.tfvars"

tf_apply: create_package
	if [ ! -f "terraform/.terraform.lock.hcl" ]; then \
		$(MAKE) -f $(CURRENT_MAKEFILE) tf_init; \
	fi
	terraform -chdir=terraform \
	  apply -auto-approve \
	  -var-file="variables.tfvars"

tf_destroy:
	terraform -chdir=terraform \
	  destroy -auto-approve \
	  -var-file="variables.tfvars"

get_auth_token:
	$(eval OTC_X_AUTH_TOKEN := $(shell ./utils/tokenFromUsername.sh))

test_deployed_info: get_auth_token
	# getting the Function URN from terraform output...
	$(eval MY_FUNCTION_URN := $(shell terraform -chdir=terraform output -raw FG_PRODUCE_URN))
	# calling the deployed function via FunctionGraph API...
	@curl -X POST \
	 -H "Content-Type: application/json" \
	 -H "x-auth-token: $(OTC_X_AUTH_TOKEN)" \
	 -d '{"key":"This is an INFO message"}' \
	 https://functiongraph.$(OTC_SDK_REGION).otc.t-systems.com/v2/$(OTC_SDK_PROJECTID)/fgs/functions/$(MY_FUNCTION_URN):latest/invocations
	@echo ""
	# finished

test_deployed_warn: get_auth_token
	# getting the Function URN from terraform output...
	$(eval MY_FUNCTION_URN := $(shell terraform -chdir=terraform output -raw FG_PRODUCE_URN))
	# calling the deployed function via FunctionGraph API...
	@curl -X POST \
	 -H "Content-Type: application/json" \
	 -H "x-auth-token: $(OTC_X_AUTH_TOKEN)" \
	 -d '{"key":"This is a WARNING message"}' \
	 https://functiongraph.$(OTC_SDK_REGION).otc.t-systems.com/v2/$(OTC_SDK_PROJECTID)/fgs/functions/$(MY_FUNCTION_URN):latest/invocations
	@echo ""
	# finished

test_deployed_error: get_auth_token
	# getting the Function URN from terraform output...
	$(eval MY_FUNCTION_URN := $(shell terraform -chdir=terraform output -raw FG_PRODUCE_URN))
	# calling the deployed function via FunctionGraph API...
	@curl -X POST \
	 -H "Content-Type: application/json" \
	 -H "x-auth-token: $(OTC_X_AUTH_TOKEN)" \
	 -d '{"key":"This is an ERROR message"}' \
	 https://functiongraph.$(OTC_SDK_REGION).otc.t-systems.com/v2/$(OTC_SDK_PROJECTID)/fgs/functions/$(MY_FUNCTION_URN):latest/invocations
	@echo ""
	# finished


list_log_objects:
	$(eval LOGBUCKET_NAME := $(shell terraform -chdir=terraform output -raw logbucket_name))
	s3cmd \
	--access_key=$(TF_VAR_OTC_SDK_AK) \
	--secret_key=$(TF_VAR_OTC_SDK_SK) \
	--no-ssl \
	ls s3://$(LOGBUCKET_NAME)/log/

display_log_object:
  # usage:
  # make display_log_object file=s3://bucket/key
	if [ -z "$(file)" ]; then \
		echo "missing parameter"; \
	else \
		./utils/catOBSfile.sh $(file); \
	fi
	@echo ""

.PHONY: tf_init tf_plan tf_apply tf_destroy create_package get_auth_token test_deployed_info test_deployed_warn test_deployed_error list_log_objects
