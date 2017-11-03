#ifndef BISECT_H
#define BISECT_H

/*
 * Find bisection. If something is found, `reaches` will be the number of
 * commits that the best commit reaches. `all` will be the count of
 * non-SAMETREE commits. If `find_all` is set, all non-SAMETREE commits are
 * returned sorted, otherwise only a single best commit is returned. The
 * original list will be left in an undefined state and should not be examined.
 */
extern struct commit_list *find_bisection(struct commit_list *list,
					  int *reaches, int *all,
					  int find_all);

extern struct commit_list *filter_skipped(struct commit_list *list,
					  struct commit_list **tried,
					  int show_all,
					  int *count,
					  int *skipped_first);

#define BISECT_SHOW_ALL		(1<<0)
#define REV_LIST_QUIET		(1<<1)

struct rev_list_info {
	struct rev_info *revs;
	int flags;
	int show_timestamp;
	int hdr_termination;
	const char *header_prefix;
};

extern int bisect_next_all(const char *prefix, int no_checkout);

extern int estimate_bisect_steps(int all);

extern void read_bisect_terms(const char **bad, const char **good);

extern int bisect_clean_state(void);

#endif
