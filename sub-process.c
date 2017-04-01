/*
 * Generic implementation of background process infrastructure.
 */
#include "sub-process.h"
#include "sigchain.h"
#include "pkt-line.h"

static int subprocess_map_initialized;
static struct hashmap subprocess_map;

static int cmd2process_cmp(const struct subprocess_entry *e1,
			   const struct subprocess_entry *e2,
			   const void *unused)
{
	return strcmp(e1->cmd, e2->cmd);
}

struct subprocess_entry *subprocess_find_entry(const char *cmd)
{
	struct subprocess_entry key;

	if (!subprocess_map_initialized) {
		subprocess_map_initialized = 1;
		hashmap_init(&subprocess_map, (hashmap_cmp_fn)cmd2process_cmp, 0);
		return NULL;
	}

	hashmap_entry_init(&key, strhash(cmd));
	key.cmd = cmd;
	return hashmap_get(&subprocess_map, &key, NULL);
}

int subprocess_read_status(int fd, struct strbuf *status)
{
	struct strbuf **pair;
	char *line;
	int len;

	for (;;) {
		len = packet_read_line_gently(fd, NULL, &line);
		if ((len == -1) || !line)
			break;
		pair = strbuf_split_str(line, '=', 2);
		if (pair[0] && pair[0]->len && pair[1]) {
			/* the last "status=<foo>" line wins */
			if (!strcmp(pair[0]->buf, "status=")) {
				strbuf_reset(status);
				strbuf_addbuf(status, pair[1]);
			}
		}
		strbuf_list_free(pair);
	}

	return len == -1 ? len : 0;
}

void subprocess_stop(struct subprocess_entry *entry)
{
	if (!entry)
		return;

	entry->process.clean_on_exit = 0;
	kill(entry->process.pid, SIGTERM);
	finish_command(&entry->process);

	hashmap_remove(&subprocess_map, entry, NULL);
}

static void subprocess_exit_handler(struct child_process *process)
{
	sigchain_push(SIGPIPE, SIG_IGN);
	/* Closing the pipe signals the filter to initiate a shutdown. */
	close(process->in);
	close(process->out);
	sigchain_pop(SIGPIPE);
	/* Finish command will wait until the shutdown is complete. */
	finish_command(process);
}

int subprocess_start(struct subprocess_entry *entry, const char *cmd,
	subprocess_start_fn startfn)
{
	int err;
	struct child_process *process;
	const char *argv[] = { cmd, NULL };

	if (!subprocess_map_initialized) {
		subprocess_map_initialized = 1;
		hashmap_init(&subprocess_map, (hashmap_cmp_fn)cmd2process_cmp, 0);
	}

	entry->cmd = cmd;
	process = &entry->process;

	child_process_init(process);
	process->argv = argv;
	process->use_shell = 1;
	process->in = -1;
	process->out = -1;
	process->clean_on_exit = 1;
	process->clean_on_exit_handler = subprocess_exit_handler;

	err = start_command(process);
	if (err) {
		error("cannot fork to run external filter '%s'", cmd);
		return err;
	}

	hashmap_entry_init(entry, strhash(cmd));

	err = startfn(entry);
	if (err) {
		error("initialization for external filter '%s' failed", cmd);
		subprocess_stop(entry);
		return err;
	}

	hashmap_add(&subprocess_map, entry);
	return 0;
}
