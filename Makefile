# oocsv v0.2.0 Makefile

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/oocsv

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)
VERSION ?= $(shell cat VERSION 2>/dev/null || echo 0.2.0)

.PHONY: build check line-cap file-law academy density verify clean test package package-deb package-rpm package-arch install uninstall

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/oocsv-linux-x86_64
	@sha256sum dist/oocsv-linux-x86_64 > dist/oocsv-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/oocsv-linux-x86_64)"

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot" | grep -v "/dist/" | grep -v "/.ooda-cache/"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ] && [ "$$f" != "./uninstall.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh and uninstall.sh: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./packaging*" -not -path "./qa*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

test: $(BIN)
	@echo "=== testing --help ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@echo "=== testing --version ==="
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version"
	@echo "=== testing internal anchors ==="
	@./$(BIN) --test | grep -q "oocsv: internal anchor tests PASSED" && echo "PASS: internal anchors"
	@echo "=== testing --demo view ==="
	@./$(BIN) --demo | grep -q "node-alpha" && echo "PASS: --demo view"
	@echo "=== testing --demo --json ==="
	@./$(BIN) --demo --json | grep -q '"tool": "oocsv"' && echo "PASS: --demo --json"
	@echo "=== testing --demo --csv ==="
	@./$(BIN) --demo --csv | grep -q "hostname,role,cpu_pct" && echo "PASS: --demo --csv"
	@echo "=== testing file query and filtering ==="
	@printf "name,dept,score\nAlice,eng,95\nBob,sales,72\nCarol,eng,88\n" > dist/sample.csv
	@./$(BIN) -w "dept=eng" -c "name,score" dist/sample.csv | grep -q "Alice" && echo "PASS: file filter and projection"
	@./$(BIN) -w "score>90" --csv dist/sample.csv | grep -q "Alice,eng,95" && echo "PASS: numeric filter"
	@echo "=== testing headers and stats ==="
	@./$(BIN) --headers dist/sample.csv | grep -q "name, dept, score" && echo "PASS: headers plain"
	@./$(BIN) --headers --json dist/sample.csv | grep -q '"headers": \["name"' && echo "PASS: headers json"
	@./$(BIN) --stats dist/sample.csv | grep -q "Rows: 3, Columns: 3" && echo "PASS: stats"
	@rm -f dist/sample.csv
	@echo "=== testing MCP initialize ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "protocolVersion" && echo "PASS: MCP initialize"
	@echo "=== testing MCP tools/list ==="
	@printf '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "csv_parse" && echo "PASS: MCP tools/list"
	@echo "=== testing MCP tools/call csv_parse ==="
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/call","name":"csv_parse","params":{"data":"a,b\\n1,2\\n"}}\n' | ./$(BIN) --mcp | grep -q 'records' && echo "PASS: MCP csv_parse"
	@echo "=== testing MCP tools/call csv_filter ==="
	@printf '{"jsonrpc":"2.0","id":4,"method":"tools/call","name":"csv_filter","params":{"data":"x,y\\nfoo,10\\nbar,20\\n","filter":"x=foo"}}\n' | ./$(BIN) --mcp | grep -q 'foo' && echo "PASS: MCP csv_filter"
	@echo "=== testing MCP tools/call csv_select ==="
	@printf '{"jsonrpc":"2.0","id":5,"method":"tools/call","name":"csv_select","params":{"data":"a,b,c\\n1,2,3\\n","columns":"a,c"}}\n' | ./$(BIN) --mcp | grep -q 'records' && echo "PASS: MCP csv_select"
	@echo "=== testing MCP tools/call csv_headers ==="
	@printf '{"jsonrpc":"2.0","id":6,"method":"tools/call","name":"csv_headers","params":{"data":"col1,col2\\n"}}\n' | ./$(BIN) --mcp | grep -q 'col1' && echo "PASS: MCP csv_headers"
	@echo "=== testing MCP tools/call csv_demo ==="
	@printf '{"jsonrpc":"2.0","id":7,"method":"tools/call","name":"csv_demo"}\n' | ./$(BIN) --mcp | grep -q 'node-alpha' && echo "PASS: MCP csv_demo"
	@echo "ALL TESTS PASSED"

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/oocsv
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/oocsv-uninstall
	@echo "installed oocsv and oocsv-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/oocsv $(DESTDIR)$(BINDIR)/oocsv-uninstall
	@if [ "$(PURGE)" = "1" ]; then rm -rf $(HOME)/.cache/oocsv $(HOME)/.config/oocsv; echo "purged user cache and config"; fi
	@echo "uninstalled oocsv and oocsv-uninstall from $(DESTDIR)$(BINDIR)"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/oocsv
	@chmod 0755 dist/deb-root/usr/bin/oocsv
	@cp uninstall.sh dist/deb-root/usr/bin/oocsv-uninstall
	@chmod 0755 dist/deb-root/usr/bin/oocsv-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/oocsv_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/oocsv_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/oocsv-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/oocsv.spec > ~/rpmbuild/SPECS/oocsv.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/oocsv.spec
	@cp ~/rpmbuild/RPMS/x86_64/oocsv-$(VERSION)*.rpm dist/
	@echo "built dist RPM package"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/oocsv
	@chmod 0755 dist/arch-pkg/usr/bin/oocsv
	@cp uninstall.sh dist/arch-pkg/usr/bin/oocsv-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/oocsv-uninstall
	@printf "pkgname = oocsv\npkgbase = oocsv\npkgver = $(VERSION)-1\npkgdesc = High-speed RFC 4180 CSV parser with SQL-like query filtering and header projection.\nurl = https://github.com/openOODA-tools/oocsv\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = oocsv\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/oocsv-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/oocsv-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch
	@cd dist && sha256sum oocsv* > checksums.txt 2>/dev/null || true
	@echo "built all packages and dist/checksums.txt"

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
