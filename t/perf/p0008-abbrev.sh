#!/bin/sh

test_description='Test object disambiguation through abbreviations'
. ./perf-lib.sh

test_perf_large_repo

test_perf 'find_unique_abbrev()' '
	test-abbrev
'

test_done
