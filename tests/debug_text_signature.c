#include <stdbool.h>
#include <stdint.h>

static int debug_text_signature_accumulator = 0;

bool debug_text_signature_call(void *renderer, float x, float y, const char *text) {
  const unsigned char *p = (const unsigned char *)text;
  unsigned value = (unsigned)(uintptr_t)renderer;

  while (*p != 0) {
    value += *p;
    ++p;
  }

  value += (unsigned)(x * 10.0f);
  value += (unsigned)(y * 10.0f);
  debug_text_signature_accumulator = (int)value;
  return debug_text_signature_accumulator != 0;
}
