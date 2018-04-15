@echo off
setlocal EnableDelayedExpansion
echo RDP Wrapper Library Installer v1.0
echo Copyright (C) Stas'M Corp. 2013
echo.

set PROCESSOR_ARCHITECTURE | find "x86" > nul
if !errorlevel!==0 (
	goto WOW64CHK
) else (
	goto UNSUPPORTED
)

:WOW64CHK
echo [*] Check if running WOW64 subsystem...
set PROCESSOR_ARCHITEW6432 > nul
if !errorlevel!==0 (
	goto UNSUPPORTED
) else (
	goto SUPPORTED
)

:SUPPORTED
echo [+] Processor architecture is Intel x86 [supported]
goto INSTALL

:UNSUPPORTED
echo [-] Unsupported processor architecture
goto END

:INSTALL
echo [*] Installing...
if not exist rdpwrap.dll (
	echo [-] Error: rdpwrap.dll file not found
	goto END
)
echo [*] Copying file to Program Files...
md "%ProgramFiles%\RDP Wrapper"
xcopy /y rdpwrap.dll "%ProgramFiles%\RDP Wrapper\"
if not !errorlevel!==0 (
	echo [-] Failed to copy rdpwrap.dll to Program Files folder
	goto END
)
echo [*] Modifying registry...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TermService\Parameters" /v ServiceDll /t REG_EXPAND_SZ /d "%ProgramFiles%\RDP Wrapper\rdpwrap.dll" /f
if not !errorlevel!==0 (
	echo [-] Failed to modify registry
	goto END
)
echo [*] Setting firewall configuration...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
netsh advfirewall firewall add rule name="Remote Desktop" dir=in protocol=tcp localport=3389 profile=any action=allow
netsh advfirewall firewall add rule name="Remote Desktop" dir=in protocol=udp localport=3389 profile=any action=allow
echo [*] Looking for TermService PID...
tasklist /SVC /FI "SERVICES eq TermService" | find "PID" /V
echo.
if !errorlevel!==0 (
	goto DONE
) else (
	goto SVCSTART
)

:SVCSTART
echo [*] TermService is stopped. Starting it...
sc config TermService start= auto | find "1060" > nul
if !errorlevel!==0 (
	echo [-] TermService is not installed. You need to install it manually.
	goto END
) else (
	net start TermService
	goto DONE
)

:DONE
echo [+] Installation complete!
echo Now reboot or restart service.
echo.
echo To reboot computer type:
echo shutdown /r
echo.
echo To restart TermService type:
echo taskkill /f /pid 1234         ^(replace 1234 with real PID which is shown above^)
echo net start TermService
echo.
echo If second method is used, and there are another services sharing svchost.exe,
echo you must start it too:
echo net start Service1
echo net start Service2
echo etc.
goto END

:END
