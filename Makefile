UPSTREAM = https://github.com/WordPress/wordpress-develop
SRC_DIR = src
# default branch is set to 'trunk'
BRANCH = trunk
RELEASE_PREFIX = wordpress
RELEASE_DIR = $(RELEASE_PREFIX)-$(BRANCH)
ARCHIVE_NAME = $(RELEASE_PREFIX)-$(BRANCH).tar.gz

# Default rule: clean, clone, patch, build_release
all: clean clone patch release_build build_release

# Remove the SRC_DIR directory
clean:
	@echo "Cleaning up the source directory..."
	rm -rf $(SRC_DIR)
	@echo "Cleaning up previous releases..."
	rm -rf $(RELEASE_PREFIX)-*

# Clone UPSTREAM to the specified SRC_DIR and switch to the desired branch
clone:
	@if [ -d $(SRC_DIR) ]; then \
		echo "Directory $(SRC_DIR) already exists. Delete it to clone again."; \
	else \
		git clone -b $(BRANCH) $(UPSTREAM) $(SRC_DIR); \
	fi

# Apply patches to the specified branch
patch:
	cd $(SRC_DIR) && git checkout $(BRANCH) && \
	for patchfile in $(CURDIR)/patches/*; do \
		git apply $$patchfile; \
	done

# Set up the development environment
setup:
	cd $(SRC_DIR) && npm install
	cd $(SRC_DIR) && npm run build:dev
	cd $(SRC_DIR) && npm run env:start
	cd $(SRC_DIR) && npm run env:install

# Build the WordPress release
release_build:
	cd $(SRC_DIR) && npm install && npm run build

# Create a distributable release
build_release: release_build
	@echo "Building WordPress release..."
	# Copying the necessary files/folders from the build directory to the release directory
	mkdir -p $(RELEASE_DIR)
	rsync -av --progress ./$(SRC_DIR)/build/ ./$(RELEASE_DIR)/
	# Change to the RELEASE_DIR and create the compressed archive from there
	cd $(RELEASE_DIR) && tar czvf ../$(ARCHIVE_NAME) *
	@echo "WordPress release built as $(ARCHIVE_NAME)"
