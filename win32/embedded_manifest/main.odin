package manifest_example

import runtime "base:runtime"
import win "core:sys/windows"

main :: proc() {
	instance := win.HINSTANCE(win.GetModuleHandleW(nil))
	assert(instance != nil, "Failed to fetch current instance")
	CLASS_NAME :: "ManifestExampleWindow"

	startup_info : win.STARTUPINFOW
	win.GetStartupInfoW(&startup_info)
	nCmdShow := (startup_info.dwFlags & win.STARTF_USESHOWWINDOW) != 0 ? cast(win.c_int)startup_info.wShowWindow : win.SW_SHOWDEFAULT

	cls := win.WNDCLASSW {
		lpfnWndProc = wndproc,
		lpszClassName = CLASS_NAME,
		hInstance = instance,
		hCursor = win.LoadCursorA(nil, win.IDC_ARROW),
		hbrBackground = win.GetSysColorBrush(win.COLOR_3DFACE),
	}

	class := win.RegisterClassW(&cls)
	assert(class != 0, "Class creation failed")

	hwnd := win.CreateWindowW(CLASS_NAME,
		"Manifest example",
		win.WS_OVERLAPPEDWINDOW,
		win.CW_USEDEFAULT, 0, 800, 600,
		nil, nil, instance, nil)

	assert(hwnd != nil, "Window creation failed")

	win.ShowWindow(hwnd, nCmdShow)
	win.UpdateWindow(hwnd)

	msg: win.MSG

	for	win.GetMessageW(&msg, nil, 0, 0) > 0 {
		win.TranslateMessage(&msg)
		win.DispatchMessageW(&msg)
	}
}

wndproc :: proc "system"(hwnd: win.HWND, msg: win.UINT, wparam: win.WPARAM, lparam: win.LPARAM) -> win.LRESULT {
	switch msg {
	case win.WM_CREATE:
		context = runtime.default_context()
		// Create a button to demonstrate the visual effect of Common Controls v6.
		button := win.CreateWindowExW(0, "BUTTON", "",
			win.WS_CHILD | win.WS_VISIBLE,
			10, 10, 150, 30,
			hwnd, nil, nil, nil)
		assert(button != nil, "Button creation failed")

		// In addition to the change in visual appearance of the button we just created,
		// we *attempt* to detect programmatically whether we've successfully linked to Common Controls v6.
		// However, this is not an intended use case, so it may or may not work reliably on your system.
		// Do NOT use this in production code.
		if win.GetWindowTheme(button) != nil {
			// Common Controls v6 is probably linked successfully.
			win.SetWindowTextW(button, "Modern button")
		} else {
			// Common Controls v6 is probably not linked successfully.
			win.SetWindowTextW(button, "Dated button")
		}
	case win.WM_DESTROY:
		win.PostQuitMessage(0)
	}
	return win.DefWindowProcW(hwnd, msg, wparam, lparam)
}
