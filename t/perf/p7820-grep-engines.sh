#!/bin/sh

test_description="Comparison of git-grep's regex engines"

. ./perf-lib.sh

test_perf_large_repo
test_checkout_worktree

for pattern in \
	'how.to' \
	'^how to' \
	'[how] to' \
	'\(e.t[^ ]*\|v.ry\) rare' \
	'm\(ú\|u\)lt.b\(æ\|y\)te'
do
	for engine in basic extended perl
	do
		if test $engine != "basic"
		then
			# Poor man's basic -> extended converter.
			pattern=$(echo $pattern | sed 's/\\//g')
		fi
		test_perf "$engine grep $pattern" "
			git -c grep.patternType=$engine grep -- '$pattern' >'out.$engine' || :
		"
	done

	test_expect_success "assert that all engines found the same for $pattern" "
		test_cmp 'out.basic' 'out.extended' &&
		test_cmp 'out.basic' 'out.perl'
	"
done

test_done
