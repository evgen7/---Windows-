#!/bin/sh
#
# Build and test Git in a docker container running a 32-bit Ubuntu Linux
#
# Usage:
#   run-linux32-build.sh [container-image]
#

CONTAINER="${1:-daald/ubuntu32:xenial}"

sudo docker run --interactive --volume "${PWD}:/usr/src/git" "$CONTAINER" \
    /bin/bash -c 'linux32 --32bit i386 sh -c "
    : update packages &&
    apt update >/dev/null &&
    apt install -y build-essential libcurl4-openssl-dev libssl-dev \
	libexpat-dev gettext python >/dev/null &&

    : build and test &&
    cd /usr/src/git &&
    export DEFAULT_TEST_TARGET='$DEFAULT_TEST_TARGET' &&
    export GIT_PROVE_OPTS=\"'"$GIT_PROVE_OPTS"'\" &&
    export GIT_TEST_OPTS=\"'"$GIT_TEST_OPTS"'\" &&
    export GIT_TEST_CLONE_2GB='$GIT_TEST_CLONE_2GB' &&
    make --jobs=2 &&
    make --quiet test || (

    : make test-results readable to non-root user on TravisCI &&
    test '$TRAVIS' &&
    find t/test-results/ -type f -exec chmod o+r {} \; &&
    false )
"'
