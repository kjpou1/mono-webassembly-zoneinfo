TOP=$(realpath $(CURDIR))

TZ_INPUT=$(TOP)/zoneinfodata
TZ_OUTPUT=$(TOP)/zoneinfo

EMSCRIPTEN_LOCAL_SDK_DIR=$(TOP)/emsdk
EMSCRIPTEN_SDK_DIR ?= $(EMSCRIPTEN_LOCAL_SDK_DIR)

.PHONY: all
all: build

#
# Targets for building time zone data
#

$(TZ_OUTPUT):
	mkdir -p $@

$(TZ_INPUT):
	mkdir -p $@

$(TZ_INPUT)/.stamp-tz-data: $(TZ_INPUT) | $(TZ_OUTPUT)
	curl -L https://data.iana.org/time-zones/tzdata-latest.tar.gz -o $(TZ_INPUT)/tzdata.tar.gz
	tar xvzf $(TZ_INPUT)/tzdata.tar.gz -C $(TZ_INPUT)
	touch $@

##
# Parameters:
# $(1) - input directory
# $(2) - output directory
# $(3) - continent
define TZExtractTemplate

zic/$(3): $(TZ_INPUT)/.stamp-tz-data
	zic -d $(2) $(1)/$(3)

build-tz-data: zic/$(3)

endef


$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),africa))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),antarctica))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),asia))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),australasia))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),etcetera))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),europe))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),northamerica))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),southamerica))
$(eval $(call TZExtractTemplate,$(TZ_INPUT),$(TZ_OUTPUT),backward))

copy-version: 
	cp $(TZ_INPUT)/version $(TZ_OUTPUT)/version

create-zone-module:
	$(RM) -r dist
	mkdir dist
	(cd src && dotnet run -i ../zoneinfo -o ../dist/mono-webassembly-zoneinfo.js)

.PHONY: dist
dist:
	npm install
	node ./node_modules/.bin/uglifyjs dist/mono-webassembly-zoneinfo.js -m -o dist/mono-webassembly-zoneinfo.min.js

build: build-tz-data copy-version create-zone-module dist package-zoneinfo

$(TOP)/emsdk:
	# Get the emsdk repo
	git clone https://github.com/emscripten-core/emsdk.git $(EMSCRIPTEN_SDK_DIR)

.stamp-wasm-checkout-and-update-emsdk: | $(EMSCRIPTEN_SDK_DIR)
	cd $(TOP)/emsdk && git reset --hard && git clean -xdff && git pull
	touch $@

.stamp-wasm-install-and-select-latest: .stamp-wasm-checkout-and-update-emsdk
	# Download and install the latest SDK tools.
	cd $(TOP)/emsdk && ./emsdk install latest
	# Make the "latest" SDK "active" for the current user. (writes ~/.emscripten file)
	cd $(TOP)/emsdk && ./emsdk activate latest
	# Activate PATH and other environment variables in the current terminal
	cd $(TOP)/emsdk && source ./emsdk_env.sh
	touch $@

package-zoneinfo: .stamp-wasm-install-and-select-latest
	python emsdk/upstream/emscripten/tools/file_packager.py dist/zoneinfo.data --preload zoneinfo --js-output=dist/mono-webassembly-zoneinfo-fs.js
	python emsdk/upstream/emscripten/tools/file_packager.py dist/zoneinfo.data --preload zoneinfo --separate-metadata --js-output=dist/mono-webassembly-zoneinfo-fs-smd.js

clean: 
	$(RM) -r $(TZ_INPUT) $(TZ_OUTPUT)
	$(RM) -r src/bin src/obj
	$(RM) -r node_modules
	$(RM) -r dist
	$(RM) -r emsdk
	$(RM) .stamp*

