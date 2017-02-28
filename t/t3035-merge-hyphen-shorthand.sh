#!/bin/sh

test_description='merge uses the shorthand - for @{-1}'

. ./test-lib.sh

test_expect_success 'setup' '
	test_commit first &&
	test_commit second &&
	test_commit third &&
	test_commit fourth &&
	test_commit fifth &&
	test_commit sixth &&
	test_commit seventh
'

test_expect_success 'setup branches' '
	git checkout master &&
	git checkout -b testing-2 &&
	git checkout -b testing-1 &&
	test_commit eigth &&
	test_commit ninth
'

test_expect_success 'merge - should work' '
	git checkout testing-2 &&
	git merge - &&
	git rev-parse HEAD HEAD^^ | sort >actual &&
	git rev-parse master testing-1 | sort >expect &&
	test_cmp expect actual
'

test_done
