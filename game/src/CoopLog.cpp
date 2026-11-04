//
// Simple file log for debugging: writes "coop.log" next to HadesCoopGame.dll
//

#include "pch.h"
#include "CoopLog.h"

#include <windows.h>
#include <cstdarg>
#include <cstdio>
#include <string>

static std::wstring g_logPath;

static std::wstring GetLogPath() {
    HMODULE module = nullptr;
    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       reinterpret_cast<LPCWSTR>(&GetLogPath), &module);

    wchar_t path[MAX_PATH]{};
    GetModuleFileNameW(module, path, MAX_PATH);

    std::wstring result = path;
    auto slash = result.find_last_of(L"\\/");
    result = (slash == std::wstring::npos ? L"" : result.substr(0, slash + 1)) + L"coop.log";
    return result;
}

void CoopLog::Init() {
    g_logPath = GetLogPath();
    FILE *file = nullptr;
    if (_wfopen_s(&file, g_logPath.c_str(), L"w") == 0 && file)
        fclose(file);
    Write("coop log started");
}

void CoopLog::Write(const char *format, ...) {
    if (g_logPath.empty())
        g_logPath = GetLogPath();

    FILE *file = nullptr;
    if (_wfopen_s(&file, g_logPath.c_str(), L"a") != 0 || !file)
        return;

    SYSTEMTIME time;
    GetLocalTime(&time);
    fprintf(file, "%02d:%02d:%02d.%03d ", time.wHour, time.wMinute, time.wSecond, time.wMilliseconds);

    va_list args;
    va_start(args, format);
    vfprintf(file, format, args);
    va_end(args);

    fputc('\n', file);
    fclose(file);
}
