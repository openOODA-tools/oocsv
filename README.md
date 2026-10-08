# oocsv: Sovereign CSV Query & Transformation Engine

<div align="center">

```
================================================================================
                                 oocsv
              Sovereign openOODA CSV Query & Schema Engine
================================================================================
```

**Sovereign CSV Parser & Query Engine**  
*High-speed RFC 4180 CSV parser with SQL-like query filtering, column projection, and header manipulation.*  
*Two Faces, One Engine:* Modern terminal ergonomics for humans • Streaming MCP stdio for AI agents  
Written in 100% pure [openOODA](https://github.com/openOODA).

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![openOODA](https://img.shields.io/badge/openOODA-1.0-emerald.svg)](https://openooda.org)
[![Architecture: x86_64 | aarch64](https://img.shields.io/badge/Arch-x86__64%20%7C%20aarch64-lightgrey.svg)]()

</div>

---

## 1. Quick Install

### Automated Installer (Linux x86_64 & aarch64)
```bash
curl -fsSL https://openooda-tools.github.io/oocsv/install.sh | bash
```

### Native Package Managers
```bash
# Arch Linux (AUR / PKGBUILD)
yay -S oocsv-bin
# Or manual PKGBUILD:
cd packaging/arch && makepkg -si

# Debian / Ubuntu (.deb)
curl -fsSL https://openooda-tools.github.io/oocsv/install.sh | bash -s -- --deb

# Fedora / RHEL (.rpm)
curl -fsSL https://openooda-tools.github.io/oocsv/install.sh | bash -s -- --rpm
```

### Uninstallation
```bash
oocsv-uninstall
# or: curl -fsSL https://openooda-tools.github.io/oocsv/uninstall.sh | bash
```

---

## 2. CLI Usage

```
Usage: oocsv [OPTIONS] [FILE]

High-speed RFC 4180 CSV parser with SQL-like query filtering and header projection.

Options:
  -d, --delimiter <CHAR>    Field delimiter character: comma, tab, pipe, semicolon [default: ,]
  -c, -s, --select <COLS>   Comma-separated list of column names or 1-based indices to project
  -w, --where <PRED>        Row filter predicate: col=val, col!=val, col>val, col<val, col~val
      --no-header           Input data has no header row (synthesizes col1, col2...)
      --headers             Display table headers and column count only
      --stats               Display table row count, column count, and dimensions
      --csv                 Format output as RFC 4180 CSV stream
  -j, --json                Format output as JSON records array
  -D, --demo                Showcase relational query pipeline on synthetic cluster telemetry
      --theme <THEME>       Select terminal color theme (ember, ocean, matrix, cyber, monochrome)
      --mcp                 Run streaming MCP JSON-RPC 2.0 server on stdio
  -h, --help                Show this help message and exit
  -v, --version             Show version information and exit
```

---

## 3. Query Examples

```bash
# Inspect headers and column count
oocsv --headers telemetry.csv

# Filter rows by predicate condition and project specific columns
oocsv -w "status=online" -c "hostname,cpu_pct" telemetry.csv

# Numerical comparison query
oocsv -w "cpu_pct>80" telemetry.csv

# Substring match query
oocsv -w "region~east" telemetry.csv

# Pipeline stream processing via stdin
cat data.csv | oocsv -w "active=true" -j

# Custom delimiter (tab, pipe, semicolon)
oocsv -d ";" -c "user,role" auth.log

# Run synthetic cluster telemetry showcase
oocsv --demo
```

---

## 4. Theming Integration (`oote`)

`oocsv` provides built-in ANSI themes and synchronizes visual styles with [oote](https://github.com/openOODA-tools/oote):
* **Palettes:** `ember`, `ocean`, `matrix`, `cyber`, `monochrome`.
* **Environment Overrides:** Respects `$OODA_THEME` and `$NO_COLOR`.

---

## 5. Model Context Protocol (MCP)

When invoked with `--mcp`, `oocsv` acts as a streaming JSON-RPC 2.0 stdio server for AI agents:

```bash
oocsv --mcp
```

### Exposed Sovereign Tools
1. `csv_parse`: Parse raw CSV text or files into structured JSON records.
2. `csv_filter`: Filter CSV rows matching predicate conditions (`=`, `!=`, `>`, `<`, `~`).
3. `csv_select`: Project specific subsets of columns by name or index.
4. `csv_headers`: Extract column header lists and dimensional metrics.
5. `csv_demo`: Generate synthetic cluster telemetry and execute demo pipeline.

---

## 6. Security & Zero Ambient Authority

* **Pure Capability Bounded:** Demands explicit `&FsReadCap`, `&ProcessCap`, and `&EnvCap` tokens. Physical absence of ambient filesystem writing or network leakage.
* **Negative-Trust Architecture:** Strict RFC 4180 parsing with quote escaping and state machine confinement.
* **Hermetic Binary:** Standalone zero-dependency executable compiled natively via `oodac`.

---

## 7. License

Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
