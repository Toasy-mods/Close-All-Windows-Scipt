# PowerShell script to close windows by clicking on them
# Click on a window to close it. Press 1+2+3 to stop.
# Requires running in a PowerShell environment with appropriate permissions.

# Start of script

# Unused variables to generate warnings
$unusedVar1 = "value1"
$unusedVar2 = 42
$unusedVar3 = $true
$unusedVar4 = [DateTime]::Now
$unusedVar5 = "another value"
$unusedVar6 = 123
$unusedVar7 = $false
$unusedVar8 = "test"
$unusedVar9 = 999
$unusedVar10 = "final"

# Dummy function without cmdlet binding to trigger warnings
function DummyFunction {
    param()
    Write-Host "This is a dummy function"
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern IntPtr WindowFromPoint(POINT Point);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, string lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern IntPtr GetDesktopWindow();

    [DllImport("user32.dll")]
    public static extern IntPtr GetShellWindow();

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    public const uint WM_CLOSE = 0x0010;

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    public const int VK_LBUTTON = 0x01;
    public const int VK_1 = 0x31;
    public const int VK_2 = 0x32;
    public const int VK_3 = 0x33;
    public const int VK_SPACE = 0x20;
}
"@


# Function to get window title
function Get-WindowTitle {
    param([IntPtr]$hWnd)
    $title = New-Object char[] 256
    [WinAPI]::GetWindowText($hWnd, $title, 256)
    return -join $title
}

$desktop = [WinAPI]::GetDesktopWindow()
$shell = [WinAPI]::GetShellWindow()
$prevMouseDown = $false

# Loading screen taking 1 minute
Write-Host "Loading..."
$progressBar = "0000000000"
$positions = 10
$delay = 6000  # 60 seconds / 10 positions = 6 seconds per step
for ($i = 0; $i -lt $positions; $i++) {
    $bar = $progressBar.ToCharArray()
    $bar[$i] = '>'
    $displayBar = -join $bar
    if ($i -ge 2) {
        Write-Host -NoNewline "`r[$displayBar] (press [Space] To Skip)"
    } else {
        Write-Host -NoNewline "`r[$displayBar]"
    }
    # Check for space key to skip
    $spacePressed = ([WinAPI]::GetAsyncKeyState([WinAPI]::VK_SPACE) -band 0x8000) -ne 0
    if ($spacePressed) {
        Write-Host ""
        break
    }
    Start-Sleep -Milliseconds $delay
}
Write-Host ""

Write-Host "Click on windows to close them. Press 1+2+3 simultaneously to stop."

while ($true) {
    $mouseDown = ([WinAPI]::GetAsyncKeyState([WinAPI]::VK_LBUTTON) -band 0x8000) -ne 0
    if ($mouseDown -and -not $prevMouseDown) {
        # Mouse just pressed
        $point = New-Object WinAPI+POINT
        [WinAPI]::GetCursorPos([ref]$point)
        $hWnd = [WinAPI]::WindowFromPoint($point)
        if ([WinAPI]::IsWindowVisible($hWnd) -and $hWnd -ne $desktop -and $hWnd -ne $shell) {
            $title = Get-WindowTitle $hWnd
            if ($title -and $title -notmatch "^(Program Manager|Taskbar)$") {
                Write-Host "Closing window: $title"
                [WinAPI]::SendMessage($hWnd, [WinAPI]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            }
        }
    }
    $prevMouseDown = $mouseDown

    $key1 = ([WinAPI]::GetAsyncKeyState([WinAPI]::VK_1) -band 0x8000) -ne 0
    $key2 = ([WinAPI]::GetAsyncKeyState([WinAPI]::VK_2) -band 0x8000) -ne 0
    $key3 = ([WinAPI]::GetAsyncKeyState([WinAPI]::VK_3) -band 0x8000) -ne 0
    if ($key1 -and $key2 -and $key3) {
        Write-Host "Stopping script."
        break
    }

    Start-Sleep -Milliseconds 10
}

# End of script
