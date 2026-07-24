/* Declarations wasi-libc omits on purpose (no processes on WASI) but that
   adaint.c references on POSIX-ish targets.  Force-included when compiling
   the host C files for the wasi runtime.  No implementations are provided:
   these adaint.c entry points must not be reached under WASI. */
#ifndef _WASI_MISSING_H
#define _WASI_MISSING_H

#include <sys/types.h>

extern pid_t fork (void);
extern pid_t getppid (void);
extern int   execv (const char *path, char *const argv[]);
extern int   execvp (const char *file, char *const argv[]);
extern int   dup (int fd);
extern int   dup2 (int oldfd, int newfd);
extern int   kill (pid_t pid, int sig);

struct timeval;
extern int   utimes (const char *path, const struct timeval times[2]);

#endif
