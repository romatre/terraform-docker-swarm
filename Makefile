.DEFAULT_GOAL := help
TERRAFORM_BIN = terraform

validate: terraform-fmt terraform-validate	## Validate syntax

plan:	terraform-validate terraform-get terraform-plan ## Plan changes

apply: terraform-validate terraform-get terraform-apply ## Apply Changes

destroy: terraform-destroy	## Destroy infrastructure

output: terraform-output		## Display State Output

terraform-validate:
	$(TERRAFORM_BIN) validate

terraform-get:
	$(TERRAFORM_BIN) get

terraform-plan:
	$(TERRAFORM_BIN) plan -var-file=variables.tfvars

terraform-apply:
	$(TERRAFORM_BIN) apply -var-file=variables.tfvars

terraform-fmt:
	$(TERRAFORM_BIN) fmt -list

terraform-destroy:
	$(TERRAFORM_BIN) destroy -var-file=variables.tfvars

terraform-output:
	$(TERRAFORM_BIN) output

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
