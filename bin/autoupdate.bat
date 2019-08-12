<!-- : Begin batch script
@echo off
setLocal EnableExtensions
setlocal EnableDelayedExpansion

REM -------------------------------------------------------------------
REM
REM                        autoupdate.bat
REM
REM Automatic RDP Wrapper installer and updater // asmtron (11-08-2019)
REM -------------------------------------------------------------------
REM Options:
REM   -log        = redirect display output to the file autoupdate.log
REM   -taskadd    = add autorun of autoupdate.bat on startup in schedule task
REM   -taskremove = remove autorun of autoupdate.bat on startup in schedule task
REM
REM Info: 
REM   The autoupdater first use and check the official rdpwrap.ini.
REM   If a new termsrv.dll is not supported in the offical rdpwrap.ini,
REM   autoupdater first tries the asmtron rdpwrap.ini (disassembled and
REM   tested by asmtron). The autoupdater will also use rdpwrap.ini files
REM   of other contributors like the one of "saurav-biswas".
REM   Extra rdpwrap.ini sources can also be defined...
REM
REM { Special thak to binarymaster, saurav-biswas and all other contributors }

REM -----------------------------------------
REM Location of new/updated rdpwrap.ini files
REM -----------------------------------------
set rdpwrap_ini_update_github_1="https://raw.githubusercontent.com/asmtron/rdpwrap/patch-1/res/rdpwrap.ini"
set rdpwrap_ini_update_github_2="https://raw.githubusercontent.com/saurav-biswas/rdpwrap-1/patch-1/res/rdpwrap.ini"
REM set rdpwrap_ini_update_github_3="https://raw.githubusercontent.com/....Extra.3...."
REM set rdpwrap_ini_update_github_4="https://raw.githubusercontent.com/....Extra.4...."

set autoupdate_bat="%~dp0autoupdate.bat"
set autoupdate_log="%~dp0autoupdate.log"
set RDPWInst_exe="%~dp0RDPWInst.exe"
set rdpwrap_ini="%~dp0rdpwrap.ini"
set rdpwrap_ini_check=%rdpwrap_ini%
set rdpwrap_new_ini="%~dp0rdpwrap_new.ini"
set github_location=1


echo ___________________________________________
echo Automatic RDP Wrapper installer and updater
echo.
echo ^<check if the RDP Wrapper is up-to-date and working^>
echo.
REM check if admin
fsutil dirty query %systemdrive% >nul
if not %errorlevel% == 0 goto :not_admin
REM check for arguments
if /i "%~1"=="-log" (  
  echo %autoupdate_bat% output from %date% at %time% > %autoupdate_log%
  call %autoupdate_bat% >> %autoupdate_log%
  goto :finish
)
if /i "%~1"=="-taskadd" (
  echo [+] add autorun of %autoupdate_bat% on startup in the schedule task  
  schtasks /create /f /sc ONSTART /tn "RDP Wrapper Autoupdate" /tr "cmd.exe /C \"%~dp0autoupdate.bat\" -log" /ru SYSTEM /delay 0000:10
  goto :finish
)
if /i "%~1"=="-taskremove" (
  echo [-] remove autorun of %autoupdate_bat% on startup in the schedule task  
  schtasks /delete /f /tn "RDP Wrapper Autoupdate"
  goto :finish
)
if /i not "%~1"=="" (
  echo [x] Unknown argument specified: "%~1"
  echo [~] Supported argments/options are:
  echo     -log         =  redirect display output to the file autoupdate.log
  echo     -taskadd     =  add autorun of autoupdate.bat on startup in the schedule task
  echo     -taskremove  =  remove autorun of autoupdate.bat on startup in the schedule task
  goto :finish
)
REM check if file "RDPWInst.exe" exist
if not exist %RDPWInst_exe% goto :error_install
goto :start_check

:not_admin
echo [-] This script must be run as administrator to work properly!
echo     ^<Please use 'right click' on this batch file and select "Run As Administrator"^>
echo.
goto :finish
:error_install
echo [-] RDP Wrapper installer executable (RDPWInst.exe) not found!
echo Please extract all files from the downloaded RDP-Wrapper package or check your Antivirus.
echo.
goto :finish

:start_check
REM ----------------------------------
REM 1) check if TermService is running
REM ----------------------------------
sc queryex "TermService"|find "STATE"|find /v "RUNNING" >nul&&(
    echo [-] TermService not running!
    call :install
)||(
    echo [+] TermService running.
)
REM -----------------------------------------
REM 2) check if rdpwrap.dll exist in registry
REM -----------------------------------------
reg query HKLM\SYSTEM\CurrentControlSet\Services\TermService\Parameters /f "rdpwrap.dll" >nul&&(
    echo [+] Found windows registry entry for "rdpwrap.dll".
)||(
    echo [-] NOT found windows registry entry for "rdpwrap.dll"!
    call :install
)
REM ------------------------------
REM 3) check if rdpwrap.ini exists
REM ------------------------------
if exist %rdpwrap_ini% (
    echo [+] Found file: %rdpwrap_ini%
) else (
    echo [-] File NOT found: %rdpwrap_ini%!
    call :install
)
REM ---------------------------------------------------------------
REM 4) check if installed termsrv.dll version exists in rdpwrap.ini
REM ---------------------------------------------------------------
:check_update
for /f "tokens=* usebackq" %%a in (
    `cscript //nologo "%~f0?.wsf" //job:fileVersion %windir%\System32\termsrv.dll`
) do (
    set "termsrv_dll_ver=%%a"
)
echo [+] Installed "termsrv.dll" version: %termsrv_dll_ver%
if exist %rdpwrap_ini_check% (
    echo [~] Start searching [%termsrv_dll_ver%] version entry in file %rdpwrap_ini_check% ...
    findstr /c:"[%termsrv_dll_ver%]" %rdpwrap_ini_check% >nul&&(
        echo [+] Found "termsrv.dll" version entry [%termsrv_dll_ver%] in file %rdpwrap_ini_check%
        echo [~] RDP-Wrapper seems to be up-to-date and working...
    )||(
        echo [-] NOT found "termsrv.dll" version entry [%termsrv_dll_ver%] in file %rdpwrap_ini_check%!        
        if not "!rdpwrap_ini_update_github_%github_location%!" == "" (            
            set rdpwrap_ini_url=!rdpwrap_ini_update_github_%github_location%!
        		call :update
        		goto :check_update
        )
        goto :finish
    )
) else (
    echo [-] File NOT found: %rdpwrap_ini_check%
    echo [~] Give up - Please check if Antivirus/Firewall blocks the file %rdpwrap_ini_check%!
    goto :finish
)
goto :finish

REM -----------------------------------------------------
REM Install RDP Wrapper (exactly uninstall and reinstall)
REM -----------------------------------------------------
:install
echo.
echo [~] Install RDP Wrapper ...
echo.
%RDPWInst_exe% -u
%RDPWInst_exe% -i -o
goto :eof

REM -------------------
REM Restart RDP-Wrapper
REM -------------------
:restart
echo.
echo [~] ReStart RDP Wrapper ...
echo.
%RDPWInst_exe% -r
goto :eof

REM --------------------------------------------------------------------
REM Download up-to-date (alternative) version of rdpwrap.ini from GitHub
REM --------------------------------------------------------------------
:update
set /a github_location=github_location+1
echo.
echo [~] Download latest version of rdpwrap.ini from GitHub
echo     -^> %rdpwrap_ini_url%
for /f "tokens=* usebackq" %%a in (
    `cscript //nologo "%~f0?.wsf" //job:fileDownload %rdpwrap_ini_url% %rdpwrap_new_ini%`
) do (
    set "download_status=%%a"
)
if "%download_status%"=="-1" (
    echo [+] Successfully download from GitHhub latest version to %rdpwrap_new_ini%
    set rdpwrap_ini_check=%rdpwrap_new_ini%
    echo [~] Start copy %rdpwrap_new_ini% to %rdpwrap_ini% ...
    copy /y %rdpwrap_new_ini% %rdpwrap_ini%
    call :restart
) else (
    echo [-] FAILED to download from GitHub latest version to %rdpwrap_new_ini%
    echo [~] Please check you internet connection/firewall and try again!
)
goto :eof


:finish
echo.
exit /b


--- Begin wsf script --- fileVersion/fileDownload --->
<package>
  <job id="fileVersion"><script language="VBScript">
    set args = WScript.Arguments
    Set fso = CreateObject("Scripting.FileSystemObject")
    WScript.Echo fso.GetFileVersion(args(0))
    Wscript.Quit
  </script></job>
  <job id="fileDownload"><script language="VBScript">
    set args = WScript.Arguments
    WScript.Echo SaveWebBinary(args(0), args(1))
    Wscript.Quit
    Function SaveWebBinary(strUrl, strFile) 'As Boolean
        Const adTypeBinary = 1
        Const adSaveCreateOverWrite = 2
        Const ForWriting = 2
        Dim web, varByteArray, strData, strBuffer, lngCounter, ado
        On Error Resume Next
        'Download the file with any available object
        Err.Clear
        Set web = Nothing
        Set web = CreateObject("WinHttp.WinHttpRequest.5.1")
        If web Is Nothing Then Set web = CreateObject("WinHttp.WinHttpRequest")
        If web Is Nothing Then Set web = CreateObject("MSXML2.ServerXMLHTTP")
        If web Is Nothing Then Set web = CreateObject("Microsoft.XMLHTTP")
        web.Open "GET", strURL, False
        web.Send
        If Err.Number <> 0 Then
            SaveWebBinary = False
            Set web = Nothing
            Exit Function
        End If
        If web.Status <> "200" Then
            SaveWebBinary = False
            Set web = Nothing
            Exit Function
        End If
        varByteArray = web.ResponseBody
        Set web = Nothing
        'Now save the file with any available method
        On Error Resume Next
        Set ado = Nothing
        Set ado = CreateObject("ADODB.Stream")
        If ado Is Nothing Then
            Set fs = CreateObject("Scripting.FileSystemObject")
            Set ts = fs.OpenTextFile(strFile, ForWriting, True)
            strData = ""
            strBuffer = ""
            For lngCounter = 0 to UBound(varByteArray)
                ts.Write Chr(255 And Ascb(Midb(varByteArray,lngCounter + 1, 1)))
            Next
            ts.Close
        Else
            ado.Type = adTypeBinary
            ado.Open
            ado.Write varByteArray
            ado.SaveToFile strFile, adSaveCreateOverWrite
            ado.Close
        End If
        SaveWebBinary = True
    End Function
  </script></job>
</package>  