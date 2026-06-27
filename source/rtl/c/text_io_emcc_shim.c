/*
 * Minimal C-side glue for the rts-wasm-emcc Ada.Text_IO / System.File_IO
 * port. Upstream s-fileio.adb and i-cstrea.ads import a collection of
 * __gnat_* helpers that would normally live in gcc/ada/sysdep.c and
 * gcc/ada/cstreams.c. Those files pull in Windows / VxWorks / Solaris
 * branches. Emscripten is POSIX, so these tiny wrappers are all we need.
 *
 * Compiled with emcc (emscripten libc on top of MEMFS / NODEFS / etc).
 */

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <wchar.h>

/* ---- stdio.h constants exposed as int data symbols ---- */
/* Ada side declares these as "X : constant int" with pragma Import (C),
 * which lowers to WASM data symbols, so we must define them as data. */

const int __gnat_constant_eof      = EOF;
const int __gnat_constant_iofbf    = _IOFBF;
const int __gnat_constant_iolbf    = _IOLBF;
const int __gnat_constant_ionbf    = _IONBF;
const int __gnat_constant_seek_cur = SEEK_CUR;
const int __gnat_constant_seek_end = SEEK_END;
const int __gnat_constant_seek_set = SEEK_SET;

#ifdef L_tmpnam
const int __gnat_constant_l_tmpnam = L_tmpnam;
#else
const int __gnat_constant_l_tmpnam = 256;
#endif

/* stdin/stdout/stderr are imported as functions on the Ada side. */
FILE *__gnat_constant_stdin  (void) { return stdin;  }
FILE *__gnat_constant_stdout (void) { return stdout; }
FILE *__gnat_constant_stderr (void) { return stderr; }

/* ---- stdio thin wrappers (feof/ferror/fileno are macros in some libcs) */

int __gnat_feof   (FILE *s) { return feof   (s); }
int __gnat_ferror (FILE *s) { return ferror (s); }
int __gnat_fileno (FILE *s) { return fileno (s); }

/* ---- file regularity / type checks not provided by adaint.c ---- */

int __gnat_is_fifo (int fd)
{
  struct stat st;
  if (fstat (fd, &st) != 0)
    return 0;
  return S_ISFIFO (st.st_mode) ? 1 : 0;
}

int __gnat_is_file_not_found_error (int errno_value)
{
  return (errno_value == ENOENT || errno_value == ENOTDIR) ? 1 : 0;
}

/* ---- binary/text mode toggles (POSIX has no mode to switch) ---- */
/* Ada side declares these as procedures, so they return void. */

void __gnat_set_binary_mode (int fd) { (void) fd; }
void __gnat_set_text_mode   (int fd) { (void) fd; }
void __gnat_set_mode        (int fd, int mode) { (void) fd; (void) mode; }

/* Boolean flag consulted by a-textio / i-cstrea to decide whether to
 * append "b"/"t" to fopen mode strings. POSIX never needs this. */
const char __gnat_text_translation_required = 0;

/* ---- full path (not provided by adaint.c) ---- */

void __gnat_full_name (const char *name, char *buffer)
{
  if (realpath (name, buffer) == NULL)
    strcpy (buffer, name);
}

/* ---- errno accessors (System.OS_Lib.Errno / Set_Errno) ---- */

int  __get_errno (void)        { return errno; }
void __set_errno (int value)   { errno = value; }

/* ---- AdaWebPack console exports consumed by System.IO (s-io__wasm.adb) ----
 * The standalone rts-wasm resolves these from the JS loader; under Emscripten
 * we route them straight to stdout. */

void __gnat_put_char (char c) { fputc (c, stdout); }

void __gnat_put_string (const char *s, unsigned size)
{
  if (size > 0)
    fwrite (s, 1, (size_t) size, stdout);
}

void __gnat_put_int (int x) { fprintf (stdout, "%d", x); }

/* ---- 64-bit stream positioning (cstreams.c) for Ada.Streams.Stream_IO ---- */

long long __gnat_ftell64 (FILE *stream)
{
  return (long long) ftello (stream);
}

int __gnat_fseek64 (FILE *stream, long long offset, int origin)
{
  if ((off_t) offset == offset)
    return fseeko (stream, (off_t) offset, origin);
  errno = EINVAL;
  return -1;
}

/* ---- Get_Immediate (sysdep.c) ---- */

void getc_immediate (FILE *stream, int *ch, int *end_of_file)
{
  int c = getc (stream);
  if (c == EOF)
    {
      *end_of_file = 1;
      *ch = 0;
    }
  else
    {
      *end_of_file = 0;
      *ch = c;
    }
}

/* ---- directory / environment helpers (mkdir.c, env.c) ---- */

int __gnat_mkdir (char *dir_name, int encoding)
{
  (void) encoding;
  return mkdir (dir_name, S_IRWXU | S_IRWXG | S_IRWXO);
}

void __gnat_getenv (char *name, int *len, char **value)
{
  *value = getenv (name);
  *len = (*value == NULL) ? 0 : (int) strlen (*value);
}

void __gnat_setenv (char *name, char *value)
{
  setenv (name, value, 1);
}

/* __gnat_set_exit_status and gnat_exit_status come from the real upstream
 * gcc/ada/exit.c, compiled into the runtime alongside adaint.c / argv.c. */

/* ---- local time-zone offset (sysdep.c); Emscripten reports UTC ---- */

void __gnat_localtime_tzoff (const long long *timer,
                             const int *is_historic, long *off)
{
  (void) timer;
  (void) is_historic;
  *off = 0;
}

/* ---- last-chance unhandled-exception text output (a-elchha.adb) ---- */
/* Prints the GNAT exception message to stderr. Signature matches
 * a-elchha.adb's import: (address, length, line). */

void __gnat_put_exception (const char *msg, unsigned length, unsigned line)
{
  (void) line;
  if (length > 0)
    fwrite (msg, 1, (size_t) length, stderr);
  fputc ('\n', stderr);
  fflush (stderr);
}
