#!/usr/bin/env bash
#
# Script to trigger the Git for Windows build and test run.
# Set the $GFW_CI_TOKEN as environment variable.
# Pass the branch (only branches on https://github.com/git/git are
# supported) and a commit hash.
#

test $# -ne 2 && echo "Unexpected number of parameters" && exit 1
test -z "$GFW_CI_TOKEN" && echo "GFW_CI_TOKEN not defined" && exit

BRANCH=$1
COMMIT=$2

gfwci () {
	local CURL_ERROR_CODE HTTP_CODE
	exec 3>&1
	while test -z $HTTP_CODE
	do
	HTTP_CODE=$(curl \
		-H "Authentication: Bearer $GFW_CI_TOKEN" \
		--silent --retry 5 --write-out '%{HTTP_CODE}' \
		--output >(sed "$(printf '1s/^\xef\xbb\xbf//')" >cat >&3) \
		"https://git-for-windows-ci.azurewebsites.net/api/TestNow?$1" \
	)
	CURL_ERROR_CODE=$?
		# The GfW CI web app sometimes returns HTTP errors of
		# "502 bad gateway" or "503 service unavailable".
		# Wait a little and retry if it happens. More info:
		# https://docs.microsoft.com/en-in/azure/app-service-web/app-service-web-troubleshoot-http-502-http-503
		if test $HTTP_CODE -eq 502 || test $HTTP_CODE -eq 503
		then
			sleep 10
			HTTP_CODE=
		fi
	done
	if test $CURL_ERROR_CODE -ne 0
	then
		return $CURL_ERROR_CODE
	fi
	if test "$HTTP_CODE" -ge 400 && test "$HTTP_CODE" -lt 600
	then
		return 127
	fi
}

# Trigger build job
BUILD_ID=$(gfwci "action=trigger&branch=$BRANCH&commit=$COMMIT&skipTests=false")
if test $? -ne 0
then
	echo "Unable to trigger Visual Studio Team Services Build"
	echo "$BUILD_ID"
	exit 1
fi

# Check if the $BUILD_ID contains a number
case $BUILD_ID in
''|*[!0-9]*) echo "Unexpected build number: $BUILD_ID" && exit 1
esac

echo "Visual Studio Team Services Build #${BUILD_ID}"

# Wait until build job finished
STATUS=
RESULT=
while true
do
	LAST_STATUS=$STATUS
	STATUS=$(gfwci "action=status&buildId=$BUILD_ID")
	test "$STATUS" = "$LAST_STATUS" || printf "\nStatus: %s " "$STATUS"
	printf "."

	case "$STATUS" in
	inProgress|postponed|notStarted) sleep 10               ;; # continue
		 "completed: succeeded") RESULT="success"; break;; # success
		    "completed: failed")                   break;; # failure
	*) echo "Unhandled status: $STATUS";               break;; # unknown
	esac
done

# Print log
echo ""
echo ""
gfwci "action=log&buildId=$BUILD_ID" | cut -c 30-

# Set exit code for TravisCI
test "$RESULT" = "success"
