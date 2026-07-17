#!/usr/bin/env bash

get_installed_kronk_version() {
  if ! command -v kronk >/dev/null 2>&1; then
    echo ""
    return 1
  fi

  kronk --version 2>/dev/null | awk '{print $NF}' | sed 's/^v//'
}

get_latest_kronk_version() {
  local latest
  latest="$(curl -fsSL https://api.github.com/repos/ardanlabs/kronk/releases/latest 2>/dev/null | jq -r '.tag_name // empty' 2>/dev/null || true)"
  echo "${latest#v}"
}

ensure_go_available() {
  if command -v go >/dev/null 2>&1; then
    return 0
  fi

  red "ERROR: Go is required to install/update Kronk"
  yellow "  Fix: install Go and ensure 'go' is available in PATH"
  return 1
}

ensure_go_bin_in_path() {
  local go_bin
  go_bin="$(go env GOPATH 2>/dev/null)/bin"
  if [[ -n "$go_bin" && ":$PATH:" != *":$go_bin:"* ]]; then
    export PATH="$go_bin:$PATH"
  fi
}

install_or_update_kronk() {
  local target="$1"

  ensure_go_available || return 1
  ensure_go_bin_in_path

  yellow "  Installing/Updating Kronk to v$target..."
  GO111MODULE=on go install "github.com/ardanlabs/kronk/cmd/kronk@v${target}"
}

check_kronk_updates() {
  local auto_yes="${KRONK_AUTO_UPDATE:-false}"

  local current latest
  current="$(get_installed_kronk_version || true)"
  latest="$(get_latest_kronk_version)"

  if [[ -z "$latest" ]]; then
    yellow "  Warning: Unable to resolve latest Kronk version; keeping current install"
    return 0
  fi

  if [[ -z "$current" ]]; then
    yellow "  Kronk is not installed; installing latest v$latest..."
    install_or_update_kronk "$latest"
    return 0
  fi

  if [[ "$current" == "$latest" ]]; then
    green "  Kronk: v$current (latest) ✓"
    return 0
  fi

  yellow "  Kronk update available: v$current -> v$latest"
  if [[ "$auto_yes" == "true" ]]; then
    install_or_update_kronk "$latest"
    return 0
  fi

  read -r -p "  Update Kronk now? [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES) install_or_update_kronk "$latest" ;;
    *) yellow "  Skipping Kronk update" ;;
  esac
}
