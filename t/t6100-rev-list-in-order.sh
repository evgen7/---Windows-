#!/bin/sh

test_description='miscellaneous rev-list tests'

. ./test-lib.sh


test_expect_success 'setup' '
	for x in one two three four
	do
		echo $x >$x &&
		git add $x &&
		git commit -m "add file $x"
	done &&
	for x in four three
	do
		git rm $x &&
		git commit -m "remove $x"
	done &&
	git rev-list --in-commit-order --objects HEAD >actual.raw &&
	cut -c 1-40 >actual <actual.raw &&

	git cat-file --batch-check="%(objectname)" >expect.raw <<-\EOF &&
		HEAD^{commit}
		HEAD^{tree}
		HEAD^{tree}:one
		HEAD^{tree}:two
		HEAD~1^{commit}
		HEAD~1^{tree}
		HEAD~1^{tree}:three
		HEAD~2^{commit}
		HEAD~2^{tree}
		HEAD~2^{tree}:four
		HEAD~3^{commit}
		# HEAD~3^{tree} skipped
		HEAD~4^{commit}
		# HEAD~4^{tree} skipped
		HEAD~5^{commit}
		HEAD~5^{tree}
	EOF
	grep -v "#" >expect <expect.raw &&

	test_cmp expect actual
'

test_done
