/* argv.c plus the WASI command entry point.

   wasi-libc's crt1 (_start -> __main_void) calls __main_argc_argv, the name
   clang gives a C main (int argc, char **argv) on wasm, but the binder
   generates main (argc, argv, envp).  Bridge the two through
   Wasi_Run (wasi_run.adb), which runs main and hands an unhandled
   exception to the last chance handler.  This lives in the same object as
   argv.c because crt1 only references __main_argc_argv weakly, which does
   not pull an archive member; argv.o is always linked, since the
   binder-generated main sets gnat_argc / gnat_argv, and its strong
   reference to __gnat_wasi_main pulls in wasi_run.o.  */

#include "argv.c"

extern char **environ;
extern int __gnat_wasi_main (int argc, char **argv, char **envp);

int
__main_argc_argv (int argc, char **argv)
{
  return __gnat_wasi_main (argc, argv, environ);
}
