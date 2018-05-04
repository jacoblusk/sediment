local ffi = require("ffi")
local bit = require("bit")
local user32 = ffi.load("user32")
local kernel32 = ffi.load("kernel32")

ffi.cdef([[

//Window data types
typedef void *LPVOID;
typedef int BOOL;
typedef long LONG;
typedef unsigned long DWORD;
typedef void *HANDLE;
typedef HANDLE HWND;
typedef HANDLE HINSTANCE;
typedef HANDLE HMENU;
typedef HANDLE HMODULE;
typedef const char *LPCSTR;
typedef unsigned int UINT;
typedef unsigned long LRESULT;
typedef unsigned int UINT_PTR;
typedef UINT_PTR WPARAM;
typedef unsigned long LPARAM;

typedef LRESULT(__stdcall *WNDPROC)(HWND, UINT, WPARAM, LPARAM);

typedef struct tagPOINT {
  LONG x;
  LONG y;
} POINT;

typedef struct tagWNDCLASS {
  UINT      style;
  WNDPROC   lpfnWndProc;
  int       cbClsExtra;
  int       cbWndExtra;
  HINSTANCE hInstance;
  HANDLE    hIcon;
  HANDLE    hCursor;
  HANDLE    hbrBackground;
  LPCSTR    lpszMenuName;
  LPCSTR    lpszClassName;
} WNDCLASSA;

typedef struct tagMSG {
  HWND   hwnd;
  UINT   message;
  WPARAM wParam;
  LPARAM lParam;
  DWORD  time;
  POINT  pt;
} MSG, *LPMSG;

int MessageBoxA(HWND, LPCSTR, LPCSTR, UINT);
unsigned short RegisterClassA(const WNDCLASSA *);

unsigned int GetLastError(void);
HMODULE GetModuleHandleA(LPCSTR);
LRESULT DefWindowProcA(HWND, UINT, WPARAM, LPARAM);
HWND CreateWindowExA(
    DWORD dwExStyle,
    LPCSTR lpClassName,
    LPCSTR lpWindowName,
    DWORD dwStyle,
    int x,
    int y,
    int nWidth,
    int nHeight,
    HWND hWndParent,
    HMENU hMenu,
    HINSTANCE hInstance,
    LPVOID lpParam
);

BOOL PeekMessageA(
  LPMSG lpMsg,
  HWND  hWnd,
  UINT  wMsgFilterMin,
  UINT  wMsgFilterMax,
  UINT  wRemoveMsg
);

BOOL GetMessageA(LPMSG, HWND, UINT, UINT);

BOOL TranslateMessage(const LPMSG);
LRESULT DispatchMessageA(const LPMSG);

void PostQuitMessage(int);
void Sleep(DWORD);

]])

CS_OWNDC = 0x0020
CS_HREDRAW = 0X0002
CS_VREDRAW = 0X0001

WS_OVERLAPPED = 0
WS_CAPTION = 0x00C00000
WS_SYSMENU = 0x00080000
WS_THICKFRAME = 0x00040000
WS_MINIMIZEBOX = 0x00020000
WS_MAXIMIZEBOX = 0x00010000
WS_OVERLAPPEDWINDOW = bit.bor(WS_OVERLAPPED,
                              WS_CAPTION,
                              WS_SYSMENU,
                              WS_THICKFRAME,
                              WS_MINIMIZEBOX,
                              WS_MAXIMIZEBOX)
WS_VISIBLE = 0x10000000
CW_USEDEFAULT = 0x80000000

WM_QUIT = 0x0012
WM_DESTROY = 0x002
WM_PAINT = 0x0F
PM_REMOVE = 0x001

local current_handle = kernel32.GetModuleHandleA(nil);
local win_proc = ffi.cast("WNDPROC", function(hwnd, umsg, wparam, lparam)
    local result = 0

    if umsg == WM_DESTROY then
        user32.PostQuitMessage(0)
        result = user32.DefWindowProcA(hwnd, umsg, wparam, lparam)
    elseif usmsg == WM_PAINT then
        -- pass
    else
        result = user32.DefWindowProcA(hwnd, umsg, wparam, lparam)
    end

    return result
end)

local wndclass_ptr = ffi.new("WNDCLASSA[1]", {})
wndclass_ptr[0].style = bit.bor(CS_OWNDC, CS_HREDRAW, CS_VREDRAW)
wndclass_ptr[0].lpfnWndProc = win_proc
wndclass_ptr[0].hInstance = current_handle
wndclass_ptr[0].lpszClassName = "Hello!"

local result = user32.RegisterClassA(wndclass_ptr)
if result == 0 then
    local last_error = kernel32.GetLastError()
    io.stderr:write("RegisterClassA failed with: ", last_error)
    return
end

local window_handle = user32.CreateWindowExA(
    0,
    wndclass_ptr[0].lpszClassName,
    "Window Name!",
    bit.bor(WS_OVERLAPPED, WS_VISIBLE, WS_SYSMENU),
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    nil,
    nil,
    current_handle,
    nil
)

if window_handle == nil then
    local last_error = kernel32.GetLastError()
    io.stderr:write("CreateWindowExA failed with: ", last_error)
    return
end

local is_game_running = true
local msg_ptr = ffi.new("MSG[1]", {})

while is_game_running do
    local peek_result = user32.PeekMessageA(msg_ptr, nil, 0, 0, PM_REMOVE)
    while peek_result ~= 0 do
        if peek_result == -1 then
            local last_error = kernel32.GetLastError()
            io.stderr:write("PeekMessageA error: ", get_result)
            return
        end

        if msg_ptr[0].message == WM_QUIT then
            print("WM_QUIT!")
            return
        end

        user32.TranslateMessage(msg_ptr)
        user32.DispatchMessageA(msg_ptr)
        peek_result = user32.PeekMessageA(msg_ptr, window_handle, 0, 0, PM_REMOVE)
    end

end
