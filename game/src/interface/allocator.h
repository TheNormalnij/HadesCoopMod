//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include <malloc.h>
#include <utility>

namespace SGG {
template <typename T, typename... Args>
T *New(Args&& ...args) {
    void *pointer = _aligned_malloc(sizeof(T), std::alignment_of<T>::value);
    T::internal_constructor(pointer, std::forward<Args>(args)...);
    return (T *)pointer;
};
} // namespace SGG
