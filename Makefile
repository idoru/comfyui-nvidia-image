# ------------------------------------------------------------------
# Makefile – build CUDA‑capability specific Docker images
# ------------------------------------------------------------------
# Target image name (change if you want a different repository)
IMG_NAME   ?= comfy-skcfi

# Supported compute capabilities (as floating‑point strings)
CCS        = 8.0 8.6 8.9 9.0 12.0

# ------------------------------------------------------------------
# All: build every image
# ------------------------------------------------------------------
.PHONY: all
all: sm80 sm86 sm89 sm90 sm120

# ------------------------------------------------------------------
# Generic rule – builds an image for a *single* compute‑capability
# ------------------------------------------------------------------
.PHONY: $(CCS)
$(CCS):
	@echo "==> Building $(IMG_NAME):sm$* (CC=$*)"
	@docker build --no-cache --build-arg COMPUTE_CAPABILITY=$* \
        -t $(IMG_NAME):sm$* .

# ------------------------------------------------------------------
# Pattern rule – allows “make sm80” style targets
# ------------------------------------------------------------------
.PHONY: build-sm%
build-sm%:
	# sm90 → 9.0, sm86 → 8.6, sm120 → 12.0, etc
	@CC=$$(echo $* | sed -E 's/^([0-9]+)([0-9])$$/\1.\2/') && \
	echo "==> Building $(IMG_NAME):sm$* (CC=$${CC})" && \
	docker build --no-cache --build-arg COMPUTE_CAPABILITY=$${CC} \
	             -t $(IMG_NAME):sm$* .

# ------------------------------------------------------------------
# Convenience single‑CC targets (for readability / explicitness)
# ------------------------------------------------------------------
.PHONY: sm80 sm86 sm89 sm90 sm120
sm80: build-sm80
sm86: build-sm86
sm89: build-sm89
sm90: build-sm90
sm120: build-sm120

# ------------------------------------------------------------------
# Clean – remove the images that we just built
# ------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "==> Removing images:"
	@for cc in $(CCS); do \
    IMG=$(IMG_NAME):sm$$cc; \
    echo "    $$IMG"; \
    docker rmi $$IMG 2>/dev/null || true; \
	done

# ------------------------------------------------------------------
# Help – show a quick reference
# ------------------------------------------------------------------
.PHONY: help
help:
	@echo "Makefile targets:"
	@echo "  all      – Build images for all supported compute capabilities."
	@echo "  smXX     – Build image for a single compute capability (e.g., sm80, sm90)."
	@echo "  clean    – Remove all images created by this Makefile."
	@echo "  help     – Show this help message."
