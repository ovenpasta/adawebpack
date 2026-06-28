/* WebAssembly EH runtime support: symbols referenced by the ported GNAT
   exception runtime that emscripten's libc/libunwind does not provide. */
#include <stdio.h>
#include <stdint.h>

/* DWARF text/data relocation bases: meaningless on wasm (the LSDA does not
   use DW_EH_PE_textrel/datarel encodings).  Provided so raise-gcc.c links. */
uintptr_t _Unwind_GetTextRelBase (void *context) { (void) context; return 0; }
uintptr_t _Unwind_GetDataRelBase (void *context) { (void) context; return 0; }

/* GNAT console stderr hook (normally from gcc/ada/cio.c). */
void put_char_stderr (int c) { fputc (c, stderr); }

/* No call-chain capture on wasm: report zero frames. */
int __gnat_backtrace (void **array, int size, void *exclude_min,
		      void *exclude_max, int skip)
{
  (void) array; (void) size; (void) exclude_min;
  (void) exclude_max; (void) skip;
  return 0;
}

/* Terminate hook (normally from the binder/init.c).  Not reached on the
   handled path; abort if an exception goes unhandled. */
void __gnat_unhandled_terminate (void) { __builtin_trap (); }
