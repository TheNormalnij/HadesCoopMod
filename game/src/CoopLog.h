//
// Simple file log for debugging: writes "coop.log" next to HadesCoopGame.dll
//

#pragma once

namespace CoopLog {
void Init();
void Write(const char *format, ...);
} // namespace CoopLog
