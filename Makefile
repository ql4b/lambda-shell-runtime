.PHONY: help build push clean base tiny micro full

PLATFORM ?= linux/arm64
TAG ?= lambda-shell-runtime
VERSION ?= develop
REGISTRY ?= ghcr.io/ql4b

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: tiny micro full ## Build all variants locally

base: ## Build base image
	VERSION=$(VERSION) ./build --platform $(PLATFORM) --tag $(TAG) --load base

tiny: base ## Build tiny variant
	VERSION=$(VERSION) ./build --platform $(PLATFORM) --tag $(TAG) --load tiny

micro: base ## Build micro variant  
	VERSION=$(VERSION) ./build --platform $(PLATFORM) --tag $(TAG) --load micro

full: base ## Build full variant
	VERSION=$(VERSION) ./build --platform $(PLATFORM) --tag $(TAG) --load full

push-base: ## Push base to registry
	VERSION=$(VERSION) ./build --platform $(PLATFORM) --tag $(REGISTRY)/$(TAG) --push base

push: ## Push all variants to registry
	VERSION=$(VERSION) ./build --platform $(PLATFORM) --tag $(REGISTRY)/$(TAG) --push tiny micro full

clean: ## Remove local images
	docker rmi -f $(TAG):base $(TAG):tiny $(TAG):micro $(TAG):full 2>/dev/null || true