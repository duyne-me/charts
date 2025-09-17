
HELM_DOCS_IMAGE = jnorwood/helm-docs:latest
CONTAINER_TOOL ?= docker
REPODIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
UID := $(shell id -u)
PLATFORM := $(shell uname -m)
DOCKER_PLATFORM := linux/$(if $(findstring $(PLATFORM),arm64),arm64,amd64)

gen-docs:
    @if command -v helm-docs >/dev/null 2>&1; then \
        helm-docs -c charts; \
    else \
        $(CONTAINER_TOOL) pull $(HELM_DOCS_IMAGE); \
        $(CONTAINER_TOOL) run --rm \
            -u $(UID) \
            --platform $(DOCKER_PLATFORM) \
            -v $(REPODIR):/helm-charts \
            -w /helm-charts \
            --entrypoint /usr/local/bin/helm-docs \
            $(HELM_DOCS_IMAGE) \
            -c charts; \
    fi