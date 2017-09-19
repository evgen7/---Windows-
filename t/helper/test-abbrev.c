#include "cache.h"

int cmd_main(int ac, const char **av)
{
	unsigned int hash_delt = 0x13579BDF;
	unsigned int hash_base = 0x01020304;
	struct object_id oid;
	int i, count = 0;
	int n = sizeof(struct object_id) / sizeof(int);

	setup_git_directory();
	while (count++ < 100000) {
		for (i = 0; i < n; i++)
			((unsigned int*)oid.hash)[i] = hash_base;

		find_unique_abbrev(oid.hash, MINIMUM_ABBREV);

		hash_base += hash_delt;
	}

	exit(0);
}
