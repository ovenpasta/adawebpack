/* Native WebAssembly EH personality-call layer for the STANDALONE (tlsf)
   runtime.

   On the emcc runtime these symbols come from Emscripten's bundled libunwind
   (system/lib/libunwind/src/Unwind-wasm.c).  The standalone runtime links
   -nostdlib with no libunwind, so it must provide the same thin layer itself.

   Wasm stack unwinding is performed by the engine via the throw/catch
   instructions, so there is no libunwind-style frame walker here.  Instead the
   backend (WasmEHPrepare) inserts a call to _Unwind_CallPersonality in each
   landing pad, communicating with the personality through the fixed global
   __wasm_lpad_context.  Its layout {lpad_index, lsda, selector} and the symbol
   name are an ABI contract with LLVM and must match exactly.

   Adapted from LLVM libunwind (Apache-2.0 WITH LLVM-exception).  Single-
   threaded: the thread_local of the upstream file is dropped.  Prototypes are
   matched to the toolchain's <unwind.h> (clang's, which uses _Unwind_Word /
   _Unwind_Ptr / void *), not Emscripten's uintptr_t variants. */

#include <stdint.h>
#include <unwind.h>

/* Defined in raise-gcc.c (routes to the GNAT personality on wasm). */
_Unwind_Reason_Code
__gxx_personality_wasm0 (int version, _Unwind_Action actions,
                         _Unwind_Exception_Class exceptionClass,
                         _Unwind_Exception *unwind_exception,
                         struct _Unwind_Context *context);

struct _Unwind_LandingPadContext
{
  /* Input to the personality function. */
  uintptr_t lpad_index;   /* landing pad index */
  uintptr_t lsda;         /* LSDA address */

  /* Output computed by the personality function. */
  uintptr_t selector;     /* selector value */
};

/* Communication channel between compiler-generated landing pads and the
   personality function.  The name is fixed by the LLVM backend. */
struct _Unwind_LandingPadContext __wasm_lpad_context;

/* Called from a landing pad in compiler-generated code.  Wasm has no two-phase
   unwinding, so only the cleanup (search) phase is run. */
_Unwind_Reason_Code
_Unwind_CallPersonality (void *exception_ptr)
{
  _Unwind_Exception *exception_object = (_Unwind_Exception *) exception_ptr;

  /* Reset the selector. */
  __wasm_lpad_context.selector = 0;

  return __gxx_personality_wasm0
    (1, _UA_SEARCH_PHASE, exception_object->exception_class, exception_object,
     (struct _Unwind_Context *) &__wasm_lpad_context);
}

/* Raise: throw a wasm exception carrying the occurrence pointer (tag 0). */
_Unwind_Reason_Code
_Unwind_RaiseException (_Unwind_Exception *exception_object)
{
  __builtin_wasm_throw (0, exception_object);
}

void
_Unwind_DeleteException (_Unwind_Exception *exception_object)
{
  if (exception_object->exception_cleanup != 0)
    (*exception_object->exception_cleanup) (_URC_FOREIGN_EXCEPTION_CAUGHT,
                                            exception_object);
}

/* Personality helper: only used to store the selector (index 1). */
void
_Unwind_SetGR (struct _Unwind_Context *context, int index, _Unwind_Word value)
{
  if (index == 1)
    ((struct _Unwind_LandingPadContext *) context)->selector = value;
}

/* Personality helper: the result is used as a 1-based index after subtracting
   1, so add 2 here (matches upstream libunwind). */
_Unwind_Word
_Unwind_GetIP (struct _Unwind_Context *context)
{
  return ((struct _Unwind_LandingPadContext *) context)->lpad_index + 2;
}

void
_Unwind_SetIP (struct _Unwind_Context *context, _Unwind_Word value)
{
  (void) context;
  (void) value;
}

void *
_Unwind_GetLanguageSpecificData (struct _Unwind_Context *context)
{
  return (void *) ((struct _Unwind_LandingPadContext *) context)->lsda;
}

_Unwind_Ptr
_Unwind_GetRegionStart (struct _Unwind_Context *context)
{
  (void) context;
  return 0;
}

/* libc abort: referenced by raise-gcc.c on the unreachable/fatal paths.  The
   standalone runtime has no libc, so trap. */
void
abort (void)
{
  __builtin_trap ();
}
