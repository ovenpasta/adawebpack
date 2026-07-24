/* Minimal sys/wait.h stub for WASI: wasi-libc has no processes, but
   adaint.c includes this header unconditionally on POSIX-ish targets.
   The declared functions have no implementation; the process-spawn
   entry points of adaint.c must not be reached under WASI. */
#ifndef _WASI_STUB_SYS_WAIT_H
#define _WASI_STUB_SYS_WAIT_H

#include <sys/types.h>

#define WNOHANG 1
#define WIFEXITED(s)   1
#define WEXITSTATUS(s) (((s) >> 8) & 0xff)

extern pid_t wait (int *status);
extern pid_t waitpid (pid_t pid, int *status, int options);

#endif
