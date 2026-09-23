ENV ?= dev
MODULE_DIRS := $(wildcard modules/*)
ENV_DIRS := environments/dev environments/staging environments/prod

.PHONY: fmt validate plan lint scan check

fmt:
	terraform fmt -recursive modules environments

validate:
	@for d in $(MODULE_DIRS) $(ENV_DIRS); do \
		echo "=== validating $$d ==="; \
		(cd $$d && terraform init -backend=false -input=false >/dev/null && terraform validate) || exit 1; \
	done

plan:
	cd environments/$(ENV) && terraform plan

lint:
	tflint --init
	tflint --recursive

# Uses trivy, not tfsec: tfsec's HCL parser can't handle Terraform 1.5+
# `check` blocks (used in modules/ecs/variables.tf) and tfsec's own
# maintainers now point users to Trivy as the successor.
scan:
	trivy config .

check: fmt validate lint scan
