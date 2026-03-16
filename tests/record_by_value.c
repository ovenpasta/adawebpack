#include <stdint.h>

typedef struct {
    int32_t a;
    int32_t b;
} int_pair;

int32_t record_by_value_call(int_pair value)
{
    return value.a + value.b;
}

int_pair record_by_value_return(int32_t a, int32_t b)
{
    int_pair result;
    result.a = a;
    result.b = b;
    return result;
}
