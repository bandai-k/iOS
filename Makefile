# モノレポ共通のタスク。macOS + Xcode 16 以降で実行する想定。
#
#   make list             … アプリとパッケージの一覧
#   make build APP=TimeZONE … 指定アプリをシミュレータ向けにビルド
#   make test             … 共有パッケージのテストを全部実行

APP ?= TimeZONE
DESTINATION ?= platform=iOS Simulator,name=iPhone 16

APPS := $(notdir $(patsubst %/,%,$(wildcard Apps/*/)))
PACKAGES := $(patsubst %/,%,$(wildcard Packages/*/))

.PHONY: help list build test clean

help:
	@echo "targets: list / build / test / clean"
	@echo "  make build APP=<app名>   (既定: $(APP))"

list:
	@echo "Apps:";     for a in $(APPS); do echo "  - $$a"; done
	@echo "Packages:"; for p in $(PACKAGES); do echo "  - $$p"; done

build:
	xcodebuild \
	  -project Apps/$(APP)/$(APP).xcodeproj \
	  -scheme $(APP) \
	  -destination "$(DESTINATION)" \
	  build

test:
	@for p in $(PACKAGES); do echo "==> $$p"; swift test --package-path $$p || exit 1; done

clean:
	rm -rf build
	@for p in $(PACKAGES); do rm -rf $$p/.build; done
