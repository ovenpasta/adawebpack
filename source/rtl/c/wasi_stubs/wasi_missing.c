/* Definitions wasi-libc lacks, needed by the GNAT runtime host files.

   tmpnam: not in wasi-libc (no global /tmp in the capability model).
   Referenced by adaint.c __gnat_tmp_name.  Generate names under the
   preopen root; uniqueness is probed with fopen like adaint's own
   VxWorks branch.  */

#include <stdio.h>

static char tmpnam_static_buf[32];

char *
tmpnam (char *s)
{
  static unsigned counter = 0;
  char *buf = s != 0 ? s : tmpnam_static_buf;
  FILE *f;

  do
    {
      snprintf (buf, 32, "/gnattmp.%05u", counter++);
      f = fopen (buf, "r");
      if (f != 0)
        fclose (f);
    }
  while (f != 0 && counter < 100000u);
  return buf;
}

/* ---- process control (adaint.c / s-os_lib) ----
   WASI has no processes: these are declared (wasi_missing.h, signal.h) but
   defined nowhere, so without them any program referencing GNAT.OS_Lib's
   spawn / kill / wait entry points fails to link.  They fail at run time
   instead, with ENOSYS.  */

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern char **environ;

pid_t fork (void) { errno = ENOSYS; return -1; }
pid_t getppid (void) { return 1; }
int execv (const char *path, char *const argv[])
{ (void) path; (void) argv; errno = ENOSYS; return -1; }
pid_t waitpid (pid_t pid, int *status, int options)
{ (void) pid; (void) status; (void) options; errno = ECHILD; return -1; }
int kill (pid_t pid, int sig)
{ (void) pid; (void) sig; errno = ENOSYS; return -1; }

/* mktemp: like tmpnam above, an unused name under the preopen root.  */

char *
mktemp (char *template)
{
  size_t len = strlen (template);
  static unsigned counter = 0;
  FILE *f;

  if (len < 6 || strcmp (template + len - 6, "XXXXXX") != 0)
    {
      errno = EINVAL;
      template[0] = '\0';
      return template;
    }
  do
    {
      snprintf (template + len - 6, 7, "%06u", counter++ % 1000000u);
      f = fopen (template, "r");
      if (f != 0)
        fclose (f);
    }
  while (f != 0 && counter < 1000000u);
  return template;
}

/* ---- sysdep.c pieces not covered by text_io_emcc_shim.c ----  */

/* Must match the value in sysdep.c (Ada.Calendar checks for it).  */
long __gnat_invalid_tzoff = 259273;

/* Ada.Directories.Name_Case_Kind: Case_Sensitive.  */
int __gnat_name_case_equivalence (void) { return 1; }

/* Get_Immediate (File, Item, Available): return at once with Available
   False when no input is ready.  Only the descriptor is polled, so input
   already buffered in the FILE is seen on the next blocking read.  */

#include <poll.h>

void
getc_immediate_nowait (FILE *stream, int *ch, int *end_of_file, int *avail)
{
  struct pollfd p = { .fd = fileno (stream), .events = POLLIN };
  int c;

  *ch = 0;
  *end_of_file = 0;
  if (poll (&p, 1, 0) <= 0)   /* nothing ready, or an error */
    {
      *avail = 0;
      return;
    }
  c = getc (stream);
  *avail = 1;
  *end_of_file = (c == EOF);
  *ch = (c == EOF) ? 0 : c;
}

/* ---- env.c pieces not covered by text_io_emcc_shim.c ----  */

char **__gnat_environ (void) { return environ; }
void __gnat_unsetenv (char *name) { unsetenv (name); }

void
__gnat_clearenv (void)
{
  while (environ != 0 && environ[0] != 0)
    {
      char *eq = strchr (environ[0], '=');
      size_t n = eq != 0 ? (size_t) (eq - environ[0]) : strlen (environ[0]);
      char *name = malloc (n + 1);

      if (name == 0)
        break;
      memcpy (name, environ[0], n);
      name[n] = '\0';
      if (unsetenv (name) != 0)
        {
          free (name);
          break;
        }
      free (name);
    }
}

/* ---- cio.c (GNAT.IO) pieces; put_char_stderr is in wasm_eh_support.c ----  */

int get_char (void) { return getchar (); }
int get_int (void) { int x = 0; return scanf (" %d", &x) == 1 ? x : 0; }
void put_char (int c) { putchar (c); }
void put_int (int x) { printf ("%d", x); }
void put_int_stderr (int x) { fprintf (stderr, "%d", x); }
