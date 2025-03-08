//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

namespace Vectormath {

class Vector2 {
  public:
    Vector2() : mX{}, mY{} {};
    Vector2(float x, float y) : mX{x}, mY{y} {};

    float mX, mY;
};

} // namespace Vectormath