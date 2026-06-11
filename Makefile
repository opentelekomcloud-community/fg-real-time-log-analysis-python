SHELL := /bin/bash

# Terraform backend configuration
BACKEND_CONFIG_BUCKET := "doc-samples-tf-backend"
BACKEND_CONFIG_KEY := "terraform_state/python/real-time-log-analysis.tf"
BACKEND_CONFIG_REGION := "eu-de"
BACKEND_CONFIG_ENDPOINTS := "endpoints={s3=\"https://obs.eu-de.otc.t-systems.com\"}"

CURRENT_MAKEFILE := $(firstword $(MAKEFILE_LIST))

.SILENT: display_log_object

# Check required environment variables before executing any other target
check_envars:
	@missing=0; \
	RED='\033[0;31m' ; GREEN='\033[0;32m' ; NC='\033[0m' ; \
	provider_vars=(\
	  TF_VAR_OTC_SDK_AK \
	  TF_VAR_OTC_SDK_SK \
	  TF_VAR_OTC_SDK_DOMAIN_NAME \
	  TF_VAR_OTC_SDK_PROJECTID \
	  TF_VAR_OTC_SDK_PROJECTNAME \
	  TF_VAR_OTC_IAM_ENDPOINT \
	  AWS_ACCESS_KEY_ID \
	  AWS_SECRET_ACCESS_KEY \
	  AWS_REQUEST_CHECKSUM_CALCULATION \
	); \
	project_vars=(\
	  TF_VAR_SMN_EMAIL_ADDRESS \
	); \
	test_vars=( \
	  OTC_USER_NAME \
	  OTC_USER_PASSWORD \
	  OTC_SDK_REGION \
	  OTC_DOMAIN_NAME \
	  OTC_SDK_PROJECTNAME \
	  OTC_SDK_PROJECTID \
	  OTC_IAM_ENDPOINT \
	); \
	vars+=( "$${provider_vars[@]}" "$${project_vars[@]}" "$${test_vars[@]}" ); \
	printf "Checking required environment variables...\n"; \
	for var in "$${vars[@]}"; do \
	  if [[ -z "$${!var}" ]]; then \
	    printf "$${RED}[MISSING] $${var}$${NC}\n"; \
	    missing=1; \
	  fi; \
	done; \
	if [[ "$${AWS_REQUEST_CHECKSUM_CALCULATION}" != "when_required" ]]; then \
	  printf "$${RED}[WARN]    AWS_REQUEST_CHECKSUM_CALCULATION should be \"when_required\" (current: $${AWS_REQUEST_CHECKSUM_CALCULATION})$${NC}\n"; \
	fi; \
	if [[ $$missing -ne 0 ]]; then \
	  printf "$${RED}One or more required environment variables are missing.$${NC}\n"; \
	  exit 2; \
	fi; \
	printf "$${GREEN}All required environment variables are set$${NC}\n."

# create deployment package (zip file) for the FunctionGraph function
create_package: check_envars
	python3 createZip.py

# Terraform commands
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

# get auth token for FunctionGraph API calls
get_auth_token:
	$(eval OTC_X_AUTH_TOKEN := $(shell ./utils/tokenFromUsername.sh))

# test the deployed function by invoking it via FunctionGraph API with different log levels
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

# list log objects in the log bucket using s3cmd
list_log_objects:
	$(eval LOGBUCKET_NAME := $(shell terraform -chdir=terraform output -raw logbucket_name))
	s3cmd \
	--access_key=$(TF_VAR_OTC_SDK_AK) \
	--secret_key=$(TF_VAR_OTC_SDK_SK) \
	--no-ssl \
	ls s3://$(LOGBUCKET_NAME)/log/

# display the content of a log object using the provided shell script
display_log_object:
  # usage:
  # make display_log_object file=s3://bucket/key
	if [ -z "$(file)" ]; then \
		echo "missing parameter"; \
	else \
		./utils/catOBSfile.sh $(file); \
	fi
	@echo ""

.PHONY: check_envars tf_init tf_plan tf_apply tf_destroy create_package get_auth_token test_deployed_info test_deployed_warn test_deployed_error list_log_objects display_log_object
