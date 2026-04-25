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

/* ---- file existence / regularity checks ---- */

int __gnat_file_exists (const char *name)
{
  return access (name, F_OK) == 0 ? 1 : 0;
}

int __gnat_is_regular_file_fd (int fd)
{
  struct stat st;
  if (fstat (fd, &st) != 0)
    return 0;
  return S_ISREG (st.st_mode) ? 1 : 0;
}

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

/* ---- path length / full path ---- */

#ifdef PATH_MAX
const int __gnat_max_path_len = PATH_MAX;
#else
const int __gnat_max_path_len = 1024;
#endif

void __gnat_full_name (const char *name, char *buffer)
{
  if (realpath (name, buffer) == NULL)
    strcpy (buffer, name);
}

/* ---- temp-name / case sensitivity ---- */

void __gnat_tmp_name (char *buf)
{
  /* Deliberately simple: produce a unique-ish /tmp path. Callers use
   * fopen, so collisions just retry. tmpnam is deprecated in glibc but
   * fine under Emscripten's MEMFS. */
  static unsigned long counter = 0;
  counter++;
  snprintf (buf, 256, "/tmp/gnat-%lu-%lu", (unsigned long) getpid (), counter);
}

int __gnat_get_file_names_case_sensitive (void) { return 1; }

/* ---- errno accessors (System.OS_Lib.Errno / Set_Errno) ---- */

int  __get_errno (void)        { return errno; }
void __set_errno (int value)   { errno = value; }

/* ---- fopen / unlink / open wrappers (encoding parameter ignored) ---- */

FILE *__gnat_fopen (const char *filename, const char *mode, int encoding)
{
  (void) encoding;
  return fopen (filename, mode);
}

FILE *__gnat_freopen (const char *filename, const char *mode,
                      FILE *stream, int encoding)
{
  (void) encoding;
  return freopen (filename, mode, stream);
}

int __gnat_unlink (const char *filename, int encoding)
{
  (void) encoding;
  return unlink (filename);
}

int __gnat_rename (const char *from, const char *to, int encoding)
{
  (void) encoding;
  return rename (from, to);
}

int __gnat_open (const char *filename, int oflag)
{
  return open (filename, oflag);
}

int __gnat_fputwc (int c, FILE *stream)
{
  return fputwc ((wchar_t) c, stream);
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
