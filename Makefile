# Same name as in environment.yml
CONDA_ENV=codst
MY_SHELL:=bash
check_dirs := ./

# Need to specify bash in order for conda activate to work
SHELL:=/bin/$(MY_SHELL)

# Note that the extra activate is needed to ensure that the activate floats env to the front of PATH
CONDA_ACTIVATE=conda init ${MY_SHELL} ; source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate

all: conda-update pip-tools install-pre-commit

# Create or update conda env
conda-update:
	conda env update --prune -f environment.yml

# Compile exact pip packages
pip-tools:
	$(CONDA_ACTIVATE) $(CONDA_ENV)
	pip install pip-tools
	pip-compile requirement
	s/prod.in && pip-compile requirements/dev.in
	pip-sync requirements/prod.txt requirements/dev.txt

# Arcane incantation to print all the other targets, from https://stackoverflow.com/a/26339924
help:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

install-pre-commit:
	pre-commit install --install-hooks

style:
	isort --profile black $(check_dirs)
	black --target-version py38 $(check_dirs)

quality:
	isort --check-only --profile black $(check_dirs)
	black --check --target-version py38 $(check_dirs)
