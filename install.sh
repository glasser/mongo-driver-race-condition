#!/bin/bash

set -eu
set -o pipefail

cd "$(dirname "$0")"

MONGO_VERSION="3.4.9"

# ARCH/OS calculation borrowed from Meteor dev bundle.
UNAME="$(uname)"
ARCH="$(uname -m)"
if [ "$UNAME" == "Linux" ] ; then
    if [ "$ARCH" != "x86_64" ] ; then
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

    OS="linux"
elif [ "$UNAME" == "Darwin" ] ; then
    SYSCTL_64BIT=$(sysctl -n hw.cpu64bit_capable 2>/dev/null || echo 0)
    if [ "$ARCH" == "i386" ] && [ "1" != "$SYSCTL_64BIT" ] ; then
        # some older macos returns i386 but can run 64 bit binaries.
        # Probably should distribute binaries built on these machines,
        # but it should be OK for users to run.
        ARCH="x86_64"
    fi

    if [ "$ARCH" != "x86_64" ] ; then
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

    OS="osx"
else
    echo "Unsupported uname: ${UNAME}"
fi

echo "Installing Mongo ${MONGO_VERSION}"
MONGO_NAME="mongodb-${OS}-${ARCH}-${MONGO_VERSION}"
MONGO_TGZ="${MONGO_NAME}.tgz"
MONGO_URL="http://fastdl.mongodb.org/${OS}/${MONGO_TGZ}"

rm -rf "${MONGO_NAME}"
curl "${MONGO_URL}" | tar zx
mv "${MONGO_NAME}"/bin/mongod .
mv "${MONGO_NAME}"/bin/mongo .
rm -rf "${MONGO_NAME}"
