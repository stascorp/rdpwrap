@echo off
if exist "%~dp0autoupdate.bat" (
  call "%~dp0autoupdate.bat" -taskadd
) else (
  if exist "%~dp0..\autoupdate.bat" (
    call "%~dp0..\autoupdate.bat"  -taskadd
  )
)
pause