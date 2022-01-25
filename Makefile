DIST := dist
EXECUTABLE := gorush

GO ?= go
DEPLOY_IMAGE := $(EXECUTABLE)
GOFMT ?= gofumpt -l -s -extra

ARCHS ?= amd64
GOFILES := $(shell find . -name "*.go" -type f)
TAGS ?= sqlite
LDFLAGS ?= -X 'main.Version=$(VERSION)'



.PHONY: all
all: build

init:
ifeq ($(ANDROID_API_KEY),)
	@echo "Missing ANDROID_API_KEY Parameter"
	@exit 1
endif
ifeq ($(ANDROID_TEST_TOKEN),)
	@echo "Missing ANDROID_TEST_TOKEN Parameter"
	@exit 1
endif
	@echo "Already set ANDROID_API_KEY and ANDROID_TEST_TOKEN globale variable."

.PHONY: fmt
fmt:
	@hash gofumpt > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) install mvdan.cc/gofumpt@v0.1.1; \
	fi
	$(GOFMT) -w $(GOFILES)

.PHONY: fmt-check
fmt-check:
	@hash gofumpt > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) install mvdan.cc/gofumpt@v0.1.1; \
	fi
	@diff=$$($(GOFMT) -d $(GOFILES)); \
	if [ -n "$$diff" ]; then \
		echo "Please run 'make fmt' and commit the result:"; \
		echo "$${diff}"; \
		exit 1; \
	fi;

vet:
	$(GO) vet ./...

lint:
	@hash revive > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) install github.com/mgechev/revive@v1.0.5; \
	fi
	revive -config .revive.toml ./... || exit 1

.PHONY: install
install: $(GOFILES)
	$(GO) install -v -tags '$(TAGS)' -ldflags '$(EXTLDFLAGS)-s -w $(LDFLAGS)'
	@echo "\n==>\033[32m Installed gorush to ${GOPATH}/bin/gorush\033[m"

.PHONY: build
build: $(EXECUTABLE)

.PHONY: $(EXECUTABLE)
$(EXECUTABLE): $(GOFILES)
	$(GO) build -v -tags '$(TAGS)' -ldflags '$(EXTLDFLAGS)-s -w $(LDFLAGS)' -o release/$@

.PHONY: misspell-check
misspell-check:
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) install github.com/client9/misspell/cmd/misspell@v0.3.4; \
	fi
	misspell -error $(GOFILES)

.PHONY: misspell
misspell:
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) install github.com/client9/misspell/cmd/misspell@v0.3.4; \
	fi
	misspell -w $(GOFILES)

.PHONY: test
test: init fmt-check
	@$(GO) test -v -cover -tags $(TAGS) -coverprofile coverage.txt ./... && echo "\n==>\033[32m Ok\033[m\n" || exit 1

release: release-dirs release-build release-copy release-compress release-check

release-dirs:
	mkdir -p $(DIST)/binaries $(DIST)/release

.PHONY: release-compress
release-compress:
	@hash gxz > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) install github.com/ulikunitz/xz/cmd/gxz@v0.5.10; \
	fi
	cd $(DIST)/release/; for file in `find . -type f -name "*"`; do echo "compressing $${file}" && gxz -k -9 $${file}; done;

release-copy:
	$(foreach file,$(wildcard $(DIST)/binaries/$(EXECUTABLE)-*),cp $(file) $(DIST)/release/$(notdir $(file));)

release-check:
	cd $(DIST)/release; $(foreach file,$(wildcard $(DIST)/release/$(EXECUTABLE)-*),sha256sum $(notdir $(file)) > $(notdir $(file)).sha256;)


clean:
	$(GO) clean -modcache -x -i ./...
	find . -name coverage.txt -delete
	find . -name *.tar.gz -delete
	find . -name *.db -delete
	-rm -rf release dist .cover

version:
	@echo $(VERSION)
