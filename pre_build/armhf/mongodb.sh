#!/usr/bin/env bash
VER=3.2.22-2

TMP=$(mktemp -d)

curl -sL "https://github.com/ddcc/mongodb/releases/download/v${VER}/mongodb_${VER}_armhf.deb" -o "${TMP}/mongodb_${VER}_armhf.deb"
curl -sL "https://github.com/ddcc/mongodb/releases/download/v${VER}/mongodb-server_${VER}_all.deb" -o "${TMP}/mongodb-server_${VER}_all.deb"
for f in clients server-core; do
  pn="mongodb-${f}_${VER}_armhf.deb"
  curl -sL "https://github.com/ddcc/mongodb/releases/download/v${VER}/${pn}" -o "${TMP}/${pn}"
done

apt -qy install "$TMP/"*
rm -rf "$TMP"
