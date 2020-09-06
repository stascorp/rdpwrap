@echo off
if exist "%~dp0autoupdate.bat" (
  call "%~dp0autoupdate.bat" -taskremove
) else (
  if exist "%~dp0..\autoupdate.bat" (
    call "%~dp0..\autoupdate.bat"  -taskremove
  )
)
pause