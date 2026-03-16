#include <string.h>
#include <stdint.h>

/* Consumes a char * and returns its length, or -1 for null pointer.
   Used by interfaces_c_strings_main.adb to verify that chars_ptr values
   produced by Interfaces.C.Strings.New_String are valid C strings. */
int interfaces_c_strings_check(const char *text)
{
    if (text == 0) return -1;
    return (int)strlen(text);
}
