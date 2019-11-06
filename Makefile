TOP=$(realpath $(CURDIR))

TZ_INPUT=$(TOP)/zoneinfodata
TZ_OUTPUT=$(TOP)/zoneinfo

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

build: build-tz-data copy-version create-zone-module dist

clean: 
	$(RM) -r $(TZ_INPUT) $(TZ_OUTPUT)
	$(RM) -r src/bin src/obj
	$(RM) -r node_modules
	$(RM) -r dist

