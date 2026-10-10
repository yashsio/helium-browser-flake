#!/usr/bin/env bash
#
# Update sources.json with the latest Helium Linux release.
#
# Usage: ./update.sh
#
# Requires: nix, curl, git. Set GITHUB_TOKEN to avoid GitHub API rate limits.

set -euo pipefail

REPO="imputnet/helium-linux"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES="$DIR/sources.json"

api_get() {
  local url="$1"
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" "$url"
  else
    curl -fsSL "$url"
  fi
}

declare -A HASH URL

echo "==> Fetching latest release of ${REPO}"
RELEASE="$(api_get "https://api.github.com/repos/${REPO}/releases/latest")"
VERSION="$(printf '%s\n' "$RELEASE" \
  | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"

if [ -z "${VERSION}" ]; then
  echo "error: could not determine latest version" >&2
  exit 1
fi

CURRENT="$(grep -m1 '"version"' "$SOURCES" | sed -E 's/.*"version": *"([^"]+)".*/\1/')"

echo "    current: ${CURRENT}"
echo "    latest:  ${VERSION}"

if [ "$CURRENT" = "$VERSION" ]; then
  echo "==> Already up to date"
  exit 0
fi

prefetch() {
  local sys="$1" suffix="$2"
  local asset="helium-${VERSION}-${suffix}_linux.tar.xz"
  local url="https://github.com/${REPO}/releases/download/${VERSION}/${asset}"
  local hash32

  echo "    ${sys}: ${asset}"
  hash32="$(nix-prefetch-url --type sha256 "$url")"
  HASH["$sys"]="$(nix hash convert --to sri --hash-algo sha256 "$hash32")"
  URL["$sys"]="$url"
}

echo "==> Prefetching hashes"
prefetch x86_64-linux x86_64
prefetch aarch64-linux arm64

echo "==> Writing ${SOURCES}"

{
  printf '{\n'
  printf '  "version": "%s",\n' "$VERSION"
  printf '  "sources": {\n'
  printf '    "x86_64-linux": {\n'
  printf '      "url": "%s",\n' "${URL[x86_64-linux]}"
  printf '      "hash": "%s"\n' "${HASH[x86_64-linux]}"
  printf '    },\n'
  printf '    "aarch64-linux": {\n'
  printf '      "url": "%s",\n' "${URL[aarch64-linux]}"
  printf '      "hash": "%s"\n' "${HASH[aarch64-linux]}"
  printf '    }\n'
  printf '  }\n'
  printf '}\n'
} > "$SOURCES"

echo "==> Updated Helium to ${VERSION}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "version=${VERSION}"
    echo "changed=true"
  } >> "$GITHUB_OUTPUT"
fi
