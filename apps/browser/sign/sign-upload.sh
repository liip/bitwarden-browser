#!/usr/bin/env bash
set -e
# Sign and upload the extension to the mozilla addons hub
#
# - You need to build the extension first:
# > npm run dist:firefox
# - You need to set your credentials in the environment:
# > FIREFOX_JWT_ISSUER=... FIREFOX_JWT_SECRET=... ./sign-upload.sh
#
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${SCRIPT_DIR}

VARIANT=${1:-"firefox"}
FIREFOX_MANIFEST_V3="../src/manifest.v3.json"
FIREFOX_SOURCE="../dist/dist-firefox.zip"
DO_BUILD=0
if [ "$1" == "--build" ]; then
  DO_BUILD=1
fi


if [ "$(command -v jq)" = "" ]; then
  2>&1 echo "jq is required to run this script"
  exit 1
fi

if [[ -z "${FIREFOX_JWT_ISSUER}" ]]; then
  2>&1 echo "FIREFOX_JWT_ISSUER is required to run this script"
  exit 1
fi
if [[ -z "${FIREFOX_JWT_SECRET}" ]]; then
  2>&1 echo "FIREFOX_JWT_SECRET is required to run this script"
  exit 1
fi

FIREFOX_GUID=$(jq ".applications.gecko.id" $FIREFOX_MANIFEST_V3 | tr -d '"')
FIREFOX_VERSION_NUMBER=$(jq ".version" $FIREFOX_MANIFEST_V3 | tr -d '"' | tr -d '{' | tr -d '}')

# Make sure vendors are installed
if [[ ! -d node_modules ]]; then
  npm install
fi

# Build the extension if needed
if [ "$DO_BUILD" == "1" ]; then
  cd ..
  npm run dist:firefox
  cd ${SCRIPT_DIR}
fi

# Check if the extension is built
if [[ ! -f $FIREFOX_SOURCE ]]; then
  2>&1 echo "$FIREFOX_SOURCE is missing, build the extension first"
  exit 1

fi

# Fix the path to the extension
FIREFOX_SOURCE_PATH=$(realpath $FIREFOX_SOURCE)

# build it
echo "Upload extension as ${FIREFOX_GUID}"
env "FIREFOX_JWT_ISSUER=${FIREFOX_JWT_ISSUER}" \
 "FIREFOX_JWT_SECRET=${FIREFOX_JWT_SECRET}" \
 "FIREFOX_GUID=${FIREFOX_GUID}" \
 "FIREFOX_VERSION_NUMBER=${FIREFOX_VERSION_NUMBER}" \
 "FIREFOX_SOURCE_PATH=${FIREFOX_SOURCE_PATH}" \
node sign-upload.js
