#!/bin/sh

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 Intel Corporation

set -eu

SCRIPT_NAME=$(basename "$0")
PYELFTOOLS_SLOT=""
CONFIGURE_HUGEPAGES=0
MINIMAL=0

usage() {
  cat <<USAGE
Usage: $SCRIPT_NAME [options]

Prepare FreeBSD environment for Media Transport Library build based on doc/build_FREEBSD.md.

Options:
  --pyelftools-slot <slot>  Python slot for pyXX-pyelftools (example: 311, 312)
  --configure-hugepages     Configure loader.conf entries for contigmem hugepages
  --minimal                 Install only mandatory package set
  -h, --help                Show this help
USAGE
}

log() {
  printf '[freebsd_required] %s\n' "$*"
}

err() {
  printf '[freebsd_required] ERROR: %s\n' "$*" >&2
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    err "Please run as root (or with sudo)."
    exit 1
  fi
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --pyelftools-slot)
        [ "$#" -ge 2 ] || { err "Missing value for --pyelftools-slot"; exit 1; }
        PYELFTOOLS_SLOT="$2"
        shift 2
        ;;
      --configure-hugepages)
        CONFIGURE_HUGEPAGES=1
        shift
        ;;
      --minimal)
        MINIMAL=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

detect_pyelftools_pkg() {
  if [ -n "$PYELFTOOLS_SLOT" ]; then
    printf 'py%s-pyelftools' "$PYELFTOOLS_SLOT"
    return
  fi

  # Prefer currently installed py*-pyelftools package if present.
  INSTALLED=$(pkg query '%n' 'py*-pyelftools' 2>/dev/null | head -n 1 || true)
  if [ -n "$INSTALLED" ]; then
    printf '%s' "$INSTALLED"
    return
  fi

  # Fallback to default from docs.
  printf 'py311-pyelftools'
}

install_packages() {
  BASE_PKGS="git gcc meson pkgconf ninja python3 json-c libpcap"
  PYELFTOOLS_PKG=$(detect_pyelftools_pkg)

  log "Updating package metadata"
  pkg update -f

  log "Installing required packages: $BASE_PKGS $PYELFTOOLS_PKG"
  pkg install -y $BASE_PKGS "$PYELFTOOLS_PKG"

  if [ "$MINIMAL" -eq 0 ]; then
    OPTIONAL_PKGS="numa googletest sdl2 sdl2_ttf llvm clang"
    log "Installing optional packages from doc/build_FREEBSD.md: $OPTIONAL_PKGS"
    pkg install -y $OPTIONAL_PKGS || true
  fi
}

ensure_loader_conf_kv() {
  KEY="$1"
  VALUE="$2"
  LOADER_CONF="/boot/loader.conf"

  if [ ! -f "$LOADER_CONF" ]; then
    touch "$LOADER_CONF"
  fi

  if grep -Eq "^${KEY}=" "$LOADER_CONF"; then
    sed -i '' "s|^${KEY}=.*|${KEY}=\"${VALUE}\"|" "$LOADER_CONF"
  else
    printf '%s="%s"\n' "$KEY" "$VALUE" >> "$LOADER_CONF"
  fi
}

configure_hugepages() {
  log "Configuring contigmem hugepages in /boot/loader.conf"
  ensure_loader_conf_kv "vm.pmap.pg_ps_enabled" "1"
  ensure_loader_conf_kv "hw.contigmem.num_buffers" "1024"
  ensure_loader_conf_kv "hw.contigmem.buffer_size" "2097152"
  ensure_loader_conf_kv "contigmem_load" "YES"

  if kldstat -q -m contigmem; then
    log "contigmem kernel module already loaded"
  else
    log "Loading contigmem kernel module"
    kldload contigmem || log "Could not load contigmem now; reboot may be required"
  fi
}

verify_environment() {
  log "Verifying key tools"
  command -v git >/dev/null
  command -v meson >/dev/null
  command -v ninja >/dev/null
  command -v pkg-config >/dev/null

  if command -v dtrace >/dev/null 2>&1; then
    log "DTrace available: $(command -v dtrace)"
  else
    log "DTrace not found (expected path on FreeBSD: /usr/sbin/dtrace)"
  fi

  if pkg-config --exists libpcap; then
    log "libpcap pkg-config check passed"
  fi

  if pkg query '%n' 'py*-pyelftools' >/dev/null 2>&1; then
    log "pyelftools package installed"
  fi

  log "Environment preparation complete"
  log "Next steps: build DPDK v25.11, then export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig and build MTL"
}

parse_args "$@"
require_root
install_packages

if [ "$CONFIGURE_HUGEPAGES" -eq 1 ]; then
  configure_hugepages
fi

verify_environment
