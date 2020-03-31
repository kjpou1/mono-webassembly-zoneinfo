TOP=$(realpath $(CURDIR))

TZ_INPUT=$(TOP)/zoneinfodata
TZ_OUTPUT=$(TOP)/zoneinfo

EMSCRIPTEN_LOCAL_SDK_DIR=$(TOP)/emsdk
EMSCRIPTEN_SDK_DIR ?= $(EMSCRIPTEN_LOCAL_SDK_DIR)

FILEPACKAGER_LOCAL_DIR=$(TOP)/file-packager
FILEPACKAGER_DLL_DIR=$(FILEPACKAGER_LOCAL_DIR)/src/bin
FILEPACKAGER_SRC_FILES=$(FILEPACKAGER_LOCAL_DIR)/src/Program.cs
FILEPACKAGER_PRJ_DIR ?= $(FILEPACKAGER_LOCAL_DIR)/src


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

zic/$(3)-$(3): $(TZ_INPUT)/.stamp-tz-data
	zic -d $(2)-$(3) $(1)/$(3)

build-tz-data: zic/$(3)

build-tz-data-$(3): zic/$(3)-$(3)

package-zoneinfo-$(3): build-tz-data-$(3) copy-version .stamp-filepackager-install-and-build | dist
	dotnet run --project $(FILEPACKAGER_PRJ_DIR)/Mono.WebAssembly.FilePackager.csproj -t dist/zoneinfo-$(3).data --preload zoneinfo-$(3) --no-heap-copy --js-output=dist/mono-webassembly-zoneinfo-$(3)-fs.js

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

.PHONY: dist
dist:
	mkdir -p $@

create-zone-module: | dist
	(cd src && dotnet run -i ../zoneinfo -o ../dist/mono-webassembly-zoneinfo.js)

.PHONY: minify
minify:
	npm install
	node ./node_modules/.bin/uglifyjs dist/mono-webassembly-zoneinfo.js -m -o dist/mono-webassembly-zoneinfo.min.js

build: 
	make package-zoneinfo 
	make package-zoneinfo-separate-metadata 
	make package-zoneinfo-africa 
	make package-zoneinfo-antarctica
	make package-zoneinfo-asia
	make package-zoneinfo-australasia
	make package-zoneinfo-etcetera
	make package-zoneinfo-europe
	make package-zoneinfo-northamerica
	make package-zoneinfo-southamerica
	#make package-zoneinfo-backward

# $(TOP)/emsdk:
# 	# Get the emsdk repo
# 	git clone https://github.com/emscripten-core/emsdk.git $(EMSCRIPTEN_SDK_DIR)

# .stamp-wasm-checkout-and-update-emsdk: | $(EMSCRIPTEN_SDK_DIR)
# 	cd $(TOP)/emsdk && git reset --hard && git clean -xdff && git pull
# 	touch $@

# .stamp-wasm-install-and-select-latest: .stamp-wasm-checkout-and-update-emsdk
# 	# Download and install the latest SDK tools.
# 	cd $(TOP)/emsdk && ./emsdk install latest
# 	# Make the "latest" SDK "active" for the current user. (writes ~/.emscripten file)
# 	cd $(TOP)/emsdk && ./emsdk activate latest
# 	# Activate PATH and other environment variables in the current terminal
# 	cd $(TOP)/emsdk && source ./emsdk_env.sh
# 	touch $@

$(TOP)/file-packager:
	# Get the dotnet file packager repo
	git clone https://github.com/kjpou1/Mono.WebAssembly.FilePackager.git $(FILEPACKAGER_LOCAL_DIR)

.stamp-filepackager-checkout-and-update: | $(FILEPACKAGER_LOCAL_DIR)
	cd $(FILEPACKAGER_LOCAL_DIR) && git reset --hard && git clean -xdff && git pull
	touch $@

.stamp-filepackager-install-and-build: .stamp-filepackager-checkout-and-update $(FILEPACKAGER_SRC_FILES)
	# Make the file packager project
	cd $(FILEPACKAGER_PRJ_DIR) && dotnet publish Mono.WebAssembly.FilePackager.sln -c Release

package-zoneinfo: build-tz-data copy-version .stamp-filepackager-install-and-build | dist
	dotnet run --project $(FILEPACKAGER_PRJ_DIR)/Mono.WebAssembly.FilePackager.csproj -t dist/zoneinfo.data --preload zoneinfo --no-heap-copy --js-output=dist/mono-webassembly-zoneinfo-fs.js

package-zoneinfo-separate-metadata: build-tz-data copy-version .stamp-filepackager-install-and-build | dist
	dotnet run --project $(FILEPACKAGER_PRJ_DIR)/Mono.WebAssembly.FilePackager.csproj -t dist/zoneinfo.data --preload zoneinfo --no-heap-copy --separate-metadata --js-output=dist/mono-webassembly-zoneinfo-fs-smd.js

# package-zoneinfo-emsdk: build-tz-data copy-version .stamp-wasm-install-and-select-latest | dist
# 	#python emsdk/upstream/emscripten/tools/file_packager.py dist/zoneinfo.data --preload zoneinfo --no-heap-copy --js-output=dist/mono-webassembly-zoneinfo-fs-emsdk.js
# 	python emsdk/upstream/emscripten/tools/file_packager.py dist/zoneinfo.data --preload zoneinfo --no-heap-copy --separate-metadata --js-output=dist/mono-webassembly-zoneinfo-fs-emsdk-smd.js

clean: 
	$(RM) -r $(TZ_INPUT) $(TZ_OUTPUT) $(TZ_OUTPUT)-*
	$(RM) -r src/bin src/obj
	$(RM) -r node_modules
	$(RM) -r dist
	$(RM) -r file-packager
	$(RM) .stamp*

