/* Only for DC_SHA1_EXTERNAL; sharing the same hooks as built-in sha1dc */

#include "cache.h"
#include <sha1.h>
#include "sha1dc_git.c"

void git_SHA1DCInit(SHA1_CTX *ctx)
{
	SHA1DCInit(ctx);
	SHA1DCSetSafeHash(ctx, 0);
}
