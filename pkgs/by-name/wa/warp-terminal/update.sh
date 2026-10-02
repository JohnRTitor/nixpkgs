#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git curl --pure
#shellcheck shell=bash
set -eu -o pipefail

cd "$(dirname "$0")"
nixpkgs=../../../../.

# Warp tags the open-source "warp-oss" channel separately from the stable
# channel that ships the prebuilt binaries on releases.warp.dev. Only tags with
# a channel suffix (stable_XX / preview_XX / dev_XX) are buildable from source,
# so pick the newest of those.
get_latest_version() {
    curl -sS 'https://api.github.com/repos/warpdotdev/Warp/tags?per_page=100' \
        | grep -o '"name": *"v[^"]*"' \
        | sed 's/.*"v//; s/"$//' \
        | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.(stable|preview|dev)_[0-9]+$' \
        | sort -r \
        | head -n 1
}

old_version=$(sed -n 's/^  version = "\(.*\)";$/\1/p' ./package.nix | head -n 1)
old_hash=$(sed -n '/owner = "warpdotdev";/{n;n;s/.*hash = "\(.*\)";/\1/p}' ./package.nix | head -n 1)

version=$(get_latest_version)
if [[ -z $version ]]; then
    echo "ERROR: could not determine the latest warp-oss tag" >&2
    exit 1
fi

echo "old version: $old_version"
echo "new version: $version"

if [[ $version == "$old_version" ]]; then
    echo "warp-terminal is already up to date at $version"
    exit 0
fi

substituteInPlace ./package.nix \
    --replace-fail "version = \"$old_version\"" "version = \"$version\""

hash=$(nix-prefetch-git --quiet --fetch-submodules \
    "https://github.com/warpdotdev/Warp" "refs/tags/v$version" \
    | nix hash to-sri --stdin)
substituteInPlace ./package.nix --replace-fail "$old_hash" "$hash"

cat <<EOF

Updated warp-terminal to $version.

Two things still need attention before this will build:

  1. Run './scripts/build-metallib.py' on macOS to regenerate shaders.metallib.
     Apple's Metal compiler is not available under Nix, so the Metal shader
     library has to be prebuilt and committed.
  2. Set cargoHash = ""; in package.nix, build, and copy the reported
     'got: sha256-...' value back into cargoHash.
  3. Check that the warp-proto-apis and workflows revs in package.nix are still
     the ones referenced by the new source tree, and refresh their hashes if
     they changed.
EOF
