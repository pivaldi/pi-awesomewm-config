SHELL := /bin/bash

# Make is verbose in Linux. Make it silent.
MAKEFLAGS += --silent
MAKEFLAGS += --no-print-directory

.PHONY: all
all: help


__link: ## Safe links file after backup. INTERNAL USE ONLY
	./scripts/mk-backup-file.sh $(_to) && (echo "Symlinking $(_from) to $(_to)"; ln -s $(_from) $(_to))

.PHONY: __cmd-exists
__cmd-exists: ## Test if a command exists. INTERNAL USE ONLY
	type $(cmd) &> /dev/null

.PHONY: install
install: ## Install the PI Awesome desktop config
	make __link _from=$(XDG_CONFIG_HOME)awesome/scripts/awm-xsession _to=~/.xsession
	make __link _from=$(XDG_CONFIG_HOME)awesome/scripts/awm-xinitrc _to=~/.xinitrc
	make __link _from=$(XDG_CONFIG_HOME)awesome/.xbindkeysrc _to=~/.xbindkeysrc
	make  __link _from=$(XDG_CONFIG_HOME)awesome/rofi _to=~/.config/rofi

.PHONY: help
help: ## Prints this help
	grep -h -P '^[a-zA-Z-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		column -t -s ':' -o ':' | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36mmake  %s\033[0m : %s\n", $$1, $$2}'
