#ifndef OP_ATTR_H
#define OP_ATTR_H
#define ATRPARAMNAMESIZE 128
#include <stdlib.h>

typedef struct {
    char operation[ATRPARAMNAMESIZE];
    int64_t axis;
    float coeff;
} OpAttr;
void setOpParam(OpAttr *opAttr);

#endif
