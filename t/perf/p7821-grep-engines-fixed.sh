#!/bin/sh

test_description="Comparison of fixed string grep under git-grep's regex engines"

. ./perf-lib.sh

test_perf_large_repo
test_checkout_worktree

for args in 'int' '-i int' 'æ' '-i æ'
do
	for engine in fixed basic extended perl
	do
		test_perf "$engine grep $args" "
			git -c grep.patternType=$engine grep $args >'out.$engine.$args' || :
		"
	done

	test_expect_success "assert that all engines found the same for $args" "
		test_cmp 'out.fixed.$args' 'out.basic.$args' &&
		test_cmp 'out.fixed.$args' 'out.extended.$args' &&
		test_cmp 'out.fixed.$args' 'out.perl.$args'
	"
done

test_done
