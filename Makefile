

default:
	@echo "Please choose a valid target"

dist:
	@echo "Making a distribution folder"
	@mkdir -p dist/$(TARGET)
	@pushd dist/$(TARGET)

msys: TARGET="win64"
	@echo "Making MSYS Package"

deb: TARGET="debian"
	@echo "Making Deb Source Package"