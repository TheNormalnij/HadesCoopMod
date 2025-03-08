
#pragma once

#define SGG_OFFSET_TO(type, offset) reinterpret_cast<type *>(reinterpret_cast<uintptr_t>(this) + offset);

#define SGG_OFFSET_TO_SET(offset, value)                                                                               \
    decltype(value) *ptr = SGG_OFFSET_TO(decltype(value), offset);                                                     \
    *ptr = value