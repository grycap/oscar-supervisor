#!/usr/bin/env bash
#
# build.sh — Cross-compile the Go supervisor for all platforms/architectures.
#
# Dependencies (AWS SDK v2, gopkg.in/yaml.v3) are pure Go, so with
# CGO_ENABLED=0 every binary is STATIC and works with both glibc and musl
# (no "-alpine" variants needed, unlike PyInstaller binaries).
#
# Output: dist/binaries/<name>
set -euo pipefail

cd "$(dirname "$0")"

VERSION="${FAAS_VERSION:-$(git describe --tags --always 2>/dev/null || echo dev)}"
LDFLAGS="-s -w -X main.version=${VERSION}"
OUT=dist/binaries

mkdir -p "$OUT"

# build <goos> <goarch> [goarm] [extra-env...] <name>
build() {
	local os=$1 arch=$2 arm=$3 name=$4 extra=${5:-}
	echo "==> ${os}/${arch}${arm:+ (GOARM=${arm})} ${extra:+ (${extra})}  ->  ${name}"
	env GOOS="$os" GOARCH="$arch" GOARM="$arm" GOMIPS=softfloat GOMIPS64=softfloat \
		CGO_ENABLED=0 $extra \
		go build -trimpath -ldflags "$LDFLAGS" -o "$OUT/$name" ./cmd/faassupervisor
}

# ---- Linux (canonical project names + remaining architectures) ----
build linux amd64 ""      supervisor
build linux arm64 ""      supervisor-arm64
build linux 386 ""        supervisor-386
build linux arm  7        supervisor-arm
build linux arm  6        supervisor-arm6
build linux riscv64 ""    supervisor-riscv64
build linux ppc64le ""    supervisor-ppc64le
build linux ppc64 ""      supervisor-ppc64
build linux s390x ""      supervisor-s390x
build linux loong64 ""    supervisor-loong64
build linux mips64le ""   supervisor-mips64le
build linux mips64 ""     supervisor-mips64
build linux mipsle ""     supervisor-mipsle
build linux mips ""       supervisor-mips

# ---- Non-Linux (bonus: developer machines) ----
build darwin amd64 ""     supervisor-darwin-amd64
build darwin arm64 ""     supervisor-darwin-arm64
build windows amd64 ""    supervisor-windows-amd64.exe
build windows arm64 ""    supervisor-windows-arm64.exe
build windows 386 ""      supervisor-windows-386.exe
build freebsd amd64 ""    supervisor-freebsd-amd64
build freebsd arm64 ""    supervisor-freebsd-arm64
build freebsd 386 ""      supervisor-freebsd-386
build freebsd arm ""      supervisor-freebsd-arm
build freebsd riscv64 ""  supervisor-freebsd-riscv64

echo ""
echo "==> Done. Binaries in: $(pwd)/$OUT"
ls -1 "$OUT"
