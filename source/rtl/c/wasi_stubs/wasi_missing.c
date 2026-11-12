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
