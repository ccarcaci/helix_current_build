SHELL   := /bin/bash
IMAGE   := aclemons/slackware:15.0
BUILDER := helix-current-builder
# Git repository to build, e.g. a fork
REPO    ?= git@github.com:helix-editor/helix.git
# Branch or tag to build
REF     ?= master
# Build volume suffix (checkout + cargo target); defaults to the REPO owner
FLAVOUR ?= $(lastword $(filter-out $(lastword $(REPO_PATH)),$(REPO_PATH)))
# Rust toolchain baked into the builder image (match the repo's rust-toolchain.toml)
RUST_TOOLCHAIN ?= 1.90.0
# REPO split on / and : so https://host/owner/repo and git@host:owner/repo both end in "owner repo"
REPO_PATH = $(subst /, ,$(subst :,/,$(REPO)))
OUT     := $(CURDIR)/out
PKGNAME := helix-current
VOLUME_PREFIX  := $(PKGNAME)-
CONTAINER_NAME := helix_build

.PHONY: help image build install uninstall

# Show this help
help:
	@$(foreach v,$(shell awk '/^[A-Z_]+ *\?=/{print $$1}' $(MAKEFILE_LIST)),$v='$($v)') \
	awk '/^# /{c=substr($$0,3); next} \
	  /^[a-z][a-z_-]*:/ && c {t=$$0; sub(/:.*/,"",t); T[++nt]=sprintf("  make %-10s %s",t,c)} \
	  /^[A-Z_]+ *\?=/ && c {P[++np]=sprintf("  %-15s %s\n                  current: %s\n                  e.g. %s=... make build",$$1,c,ENVIRON[$$1],$$1)} \
	  {c=""} \
	  END {print "Commands:"; for(i=1;i<=nt;i++) print T[i]; \
	       print "\nParameters (VAR=value make <command>):"; for(i=1;i<=np;i++) print P[i]}' $(MAKEFILE_LIST)

# Build the builder image (Slackware build deps + rustup); cached after the first run
image:
	docker build \
	  --build-arg BASE_IMAGE=$(IMAGE) \
	  --build-arg RUST_TOOLCHAIN=$(RUST_TOOLCHAIN) \
	  --tag $(BUILDER) \
	  $(CURDIR)

# Fetch, compile and package Helix inside Docker; package lands in ./out
build: image
	mkdir --parents $(OUT)
	docker run --rm \
	  --env REPO=$(REPO) --env REF=$(REF) --env OWNER=$$(id --user):$$(id --group) \
	  --volume $(VOLUME_PREFIX)$(FLAVOUR):/work \
	  --volume $(OUT):/out \
	  --name $(CONTAINER_NAME) \
	  $(BUILDER)

# Install or upgrade the built package (as root: su -c "make install")
install:
	/sbin/upgradepkg --install-new $$(ls --sort=time $(OUT)/$(PKGNAME)-*.txz | head --lines=1)

# Remove package, ./out, flavour volumes, images and build cache (as root: su -c "make uninstall")
uninstall:
	-/sbin/removepkg $(PKGNAME)
	rm --recursive --force $(OUT)
	-docker volume ls --quiet | grep '^$(VOLUME_PREFIX)' | xargs --no-run-if-empty docker volume rm
	-docker image rm $(BUILDER) $(IMAGE)
	-docker buildx prune --force --filter description=$(BUILDER)
