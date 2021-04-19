<!-- : Begin batch script
@echo off
setLocal EnableExtensions
setlocal EnableDelayedExpansion
::                                        _                   _                
::              _                        | |      _          | |          _    
::   ____ _   _| |_  ___  _   _ ____   _ | | ____| |_  ____  | | _   ____| |_  
::  / _  | | | |  _)/ _ \| | | |  _ \ / || |/ _  |  _)/ _  ) | || \ / _  |  _) 
:: ( ( | | |_| | |_| |_| | |_| | | | ( (_| ( ( | | |_( (/ / _| |_) ( ( | | |__ 
::  \_||_|\____|\___\___/ \____| ||_/ \____|\_||_|\___\____(_|____/ \_||_|\___)
::                             |_|                                             
::
:: Automatic RDP Wrapper installer and updater             asmtron (2021-04-19)
:: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
:: Options:
::   -log        = redirect display output to the file autoupdate.log
::   -taskadd    = add autorun of autoupdate.bat on startup in schedule task
::   -taskremove = remove autorun of autoupdate.bat on startup in schedule task
::
:: Info:
::   The autoupdater first use and check the official rdpwrap.ini.
::   If a new termsrv.dll is not supported in the offical rdpwrap.ini,
::   autoupdater first tries the asmtron rdpwrap.ini (disassembled and
::   tested by asmtron). The autoupdater will also use rdpwrap.ini files
::   of other contributors like the one of "sebaxakerhtc, affinityv, DrDrrae, saurav-biswas".
::   Extra rdpwrap.ini sources can also be defined...
::
:: { Special thanks to binarymaster and all other contributors }
::
:: -----------------------------------------
:: Location of new/updated rdpwrap.ini files
:: -----------------------------------------
set rdpwrap_ini_update_github_1="https://raw.githubusercontent.com/asmtron/rdpwrap/master/res/rdpwrap.ini"
set rdpwrap_ini_update_github_2="https://raw.githubusercontent.com/sebaxakerhtc/rdpwrap.ini/master/rdpwrap.ini"
set rdpwrap_ini_update_github_3="https://raw.githubusercontent.com/affinityv/INI-RDPWRAP/master/rdpwrap.ini"
set rdpwrap_ini_update_github_4="https://raw.githubusercontent.com/DrDrrae/rdpwrap/master/res/rdpwrap.ini"
set rdpwrap_ini_update_github_5="https://raw.githubusercontent.com/saurav-biswas/rdpwrap-1/master/res/rdpwrap.ini"
:: set rdpwrap_ini_update_github_6="https://raw.githubusercontent.com/....Extra.6...."
:: set rdpwrap_ini_update_github_7="https://raw.githubusercontent.com/....Extra.7...."
::
set autoupdate_bat="%~dp0autoupdate.bat"
set autoupdate_log="%~dp0autoupdate.log"
set RDPWInst_exe="%~dp0RDPWInst.exe"
set rdpwrap_ini="%~dp0rdpwrap.ini"
set rdpwrap_ini_check=%rdpwrap_ini%
set rdpwrap_new_ini="%~dp0rdpwrap_new.ini"
set github_location=1
set retry_network_check=0
::
echo ___________________________________________
echo Automatic RDP Wrapper installer and updater
echo.
echo ^<check if the RDP Wrapper is up-to-date and working^>
echo.
:: check if admin
fsutil dirty query %systemdrive% >nul
if not %errorlevel% == 0 goto :not_admin
:: check for arguments
if /i "%~1"=="-log" (
    echo %autoupdate_bat% output from %date% at %time% > %autoupdate_log%
    call %autoupdate_bat% >> %autoupdate_log%
    goto :finish
)
if /i "%~1"=="-taskadd" (
    echo [+] add autorun of %autoupdate_bat% on startup in the schedule task.
    schtasks /create /f /sc ONSTART /tn "RDP Wrapper Autoupdate" /tr "cmd.exe /C \"%~dp0autoupdate.bat\" -log" /ru SYSTEM /delay 0000:10
    powershell "$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries; Set-ScheduledTask -TaskName 'RDP Wrapper Autoupdate' -Settings $settings"
    goto :finish
)
if /i "%~1"=="-taskremove" (
    echo [-] remove autorun of %autoupdate_bat% on startup in the schedule task^^!
    schtasks /delete /f /tn "RDP Wrapper Autoupdate"
    goto :finish
)
if /i not "%~1"=="" (
    echo [x] Unknown argument specified: "%~1"
    echo [*] Supported argments/options are:
    echo     -log         =  redirect display output to the file autoupdate.log
    echo     -taskadd     =  add autorun of autoupdate.bat on startup in the schedule task
    echo     -taskremove  =  remove autorun of autoupdate.bat on startup in the schedule task
    goto :finish
)
:: check if file "RDPWInst.exe" exist
if not exist %RDPWInst_exe% goto :error_install
goto :start_check
::
:not_admin
color 0e
echo ___________________________________
echo [x] ERROR - No Administrator Rights
echo [*] This script must be run as administrator to work properly^^!
echo     ^<Please use 'right click' on this batch file and select "Run As Administrator"^>
echo.
timeout 60
goto :finish
:error_install
echo [-] RDP Wrapper installer executable (RDPWInst.exe) not found^^!
echo Please extract all files from the downloaded RDP Wrapper package or check your Antivirus.
echo.
goto :finish
::
:start_check
set rdpwrap_installed="0"
:: ----------------------------------
:: 1) check if TermService is running
:: ----------------------------------
sc queryex "TermService"|find "STATE"|find /v "RUNNING" >nul&&(
    echo [-] TermService NOT running^^!
    call :install
)||(
    echo [+] TermService running.
)
:: ------------------------------------------
:: 2) check if listener session rdp-tcp exist
:: ------------------------------------------
set rdp_tcp_session=""
set rdp_tcp_session_id=0
if exist %windir%\system32\query.exe (
    for /f "tokens=1-2* usebackq" %%a in (
        `query session rdp-tcp`
    ) do (
        set rdp_tcp_session=%%a
        set /a rdp_tcp_session_id=%%b 2>nul
    )
) else (
    for /f "tokens=2* usebackq" %%a in (
        `reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v "fDenyTSConnections" 2^>nul`
    ) do (
        if "%%a"=="REG_DWORD" (
            set rdp_tcp_session=AllowTSConnection
            if "%%b"=="0x0" (set rdp_tcp_session_id=1)
        )
    )
)
if %rdp_tcp_session_id%==0 (
    echo [-] Listener session rdp-tcp NOT found^^!
    call :install
) else (
    echo [+] Found listener session: %rdp_tcp_session% ^(ID: %rdp_tcp_session_id%^).
)
:: -----------------------------------------
:: 3) check if rdpwrap.dll exist in registry
:: -----------------------------------------
reg query "HKLM\SYSTEM\CurrentControlSet\Services\TermService\Parameters" /f "rdpwrap.dll" >nul&&(
    echo [+] Found windows registry entry for "rdpwrap.dll".
)||(
    echo [-] NOT found windows registry entry for "rdpwrap.dll"^^!
    if %rdpwrap_installed%=="0" (
        call :install
    )
)
:: ------------------------------
:: 4) check if rdpwrap.ini exists
:: ------------------------------
if exist %rdpwrap_ini% (
    echo [+] Found file: %rdpwrap_ini%.
) else (
    echo [-] File NOT found: %rdpwrap_ini%^^!
    if %rdpwrap_installed%=="0" (
        call :install
    )
)
:: ---------------------------------------------------------------
:: 5) get file version of %windir%\System32\termsrv.dll
:: ---------------------------------------------------------------
for /f "tokens=* usebackq" %%a in (
    `cscript //nologo "%~f0?.wsf" //job:fileVersion "%windir%\System32\termsrv.dll"`
) do (
    set termsrv_dll_ver=%%a
)
if "%termsrv_dll_ver%"=="" (
    echo [x] Error on getting the file version of "%windir%\System32\termsrv.dll"^^!
    goto :finish
) else (
    echo [+] Installed "termsrv.dll" version: %termsrv_dll_ver%.
)
:: ----------------------------------------------------------------------------------------
:: 6) check if installed fileversion is different to the last saved fileversion in registry
:: ----------------------------------------------------------------------------------------
echo [*] Read last "termsrv.dll" version from the windows registry...
for /f "tokens=2* usebackq" %%a in (
    `reg query "HKEY_LOCAL_MACHINE\SOFTWARE\RDP-Wrapper\Autoupdate" /v "termsrv.dll" 2^>nul`
) do (
    set last_termsrv_dll_ver=%%b
)
if "%last_termsrv_dll_ver%"=="%termsrv_dll_ver%" (
    echo [+] Current "termsrv.dll v.%termsrv_dll_ver%" same as last "termsrv.dll v.%last_termsrv_dll_ver%".
) else (
    echo [-] Current "termsrv.dll v.%termsrv_dll_ver%" different from last "termsrv.dll v.%last_termsrv_dll_ver%"^^!
    echo [*] Update current "termsrv.dll" version to the windows registry...
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\RDP-Wrapper\Autoupdate" /v "termsrv.dll" /t REG_SZ /d "%termsrv_dll_ver%" /f
    if %rdpwrap_installed%=="0" (
        call :install
    )
)
:: ---------------------------------------------------------------
:: 7) check if installed termsrv.dll version exists in rdpwrap.ini
:: ---------------------------------------------------------------
:check_update
if exist %rdpwrap_ini_check% (
    echo [*] Start searching [%termsrv_dll_ver%] version entry in file %rdpwrap_ini_check%...
    findstr /c:"[%termsrv_dll_ver%]" %rdpwrap_ini_check% >nul&&(
        echo [+] Found "termsrv.dll" version entry [%termsrv_dll_ver%] in file %rdpwrap_ini_check%.
        echo [*] RDP Wrapper seems to be up-to-date and working...
    )||(
        echo [-] NOT found "termsrv.dll" version entry [%termsrv_dll_ver%] in file %rdpwrap_ini_check%^^!
        if not "!rdpwrap_ini_update_github_%github_location%!" == "" (
            set rdpwrap_ini_url=!rdpwrap_ini_update_github_%github_location%!
            call :update
            goto :check_update
        )
        goto :finish
    )
) else (
    echo [-] File NOT found: %rdpwrap_ini_check%.
    echo [*] Give up - Please check if Antivirus/Firewall blocks the file %rdpwrap_ini_check%^^!
    goto :finish
)
goto :finish
::
:: -----------------------------------------------------
:: Install RDP Wrapper (exactly uninstall and reinstall)
:: -----------------------------------------------------
:install
echo.
echo [*] Uninstall and reinstall RDP Wrapper...
echo.
set rdpwrap_installed="1"
%RDPWInst_exe% -u
%RDPWInst_exe% -i -o
call :setNLA
goto :eof
::
:: -------------------
:: Restart RDP Wrapper
:: -------------------
:restart
echo.
echo [*] Restart RDP Wrapper with new ini (uninstall and reinstall)...
echo.
%RDPWInst_exe% -u
if exist %rdpwrap_new_ini% (
    echo.
    echo [*] Use latest downloaded rdpwrap.ini from GitHub...
    echo     -^> %rdpwrap_ini_url% 
    echo       -^> %rdpwrap_new_ini%
    echo         -^> %rdpwrap_ini%
    echo [+] copy %rdpwrap_new_ini% to %rdpwrap_ini%...
    copy %rdpwrap_new_ini% %rdpwrap_ini%
    echo.
) else (
    echo [x] ERROR - File %rdpwrap_new_ini% is missing ^^!
)
%RDPWInst_exe% -i
call :setNLA
goto :eof
::
:: --------------------------------------------------------------------
:: Download up-to-date (alternative) version of rdpwrap.ini from GitHub
:: --------------------------------------------------------------------
:update
echo [*] check network connectivity...
:netcheck
ping -n 1 google.com>nul
if errorlevel 1 (
    goto waitnetwork
) else (
    goto download
)
:waitnetwork
echo [.] Wait for network connection is available...
ping 127.0.0.1 -n 11>nul
set /a retry_network_check=retry_network_check+1
:: wait for a maximum of 5 minutes
if %retry_network_check% LSS 30 goto netcheck
:download
set /a github_location=github_location+1
echo.
echo [*] Download latest version of rdpwrap.ini from GitHub...
echo     -^> %rdpwrap_ini_url%
for /f "tokens=* usebackq" %%a in (
    `cscript //nologo "%~f0?.wsf" //job:fileDownload %rdpwrap_ini_url% %rdpwrap_new_ini%`
) do (
    set "download_status=%%a"
)
if "%download_status%"=="-1" (
    echo [+] Successfully download from GitHhub latest version to %rdpwrap_new_ini%.
    set rdpwrap_ini_check=%rdpwrap_new_ini%
    call :restart
) else (
    echo [-] FAILED to download from GitHub latest version to %rdpwrap_new_ini%^^!
    echo [*] Please check you internet connection/firewall and try again^^!
)
goto :eof
::
:: --------------------------------
:: Set Network Level Authentication
:: --------------------------------
:setNLA
echo [*] Set Network Level Authentication in the windows registry...
reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t reg_dword /d 0x2 /f
reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MinEncryptionLevel /t reg_dword /d 0x2 /f
goto :eof
::
:: -------
:: E X I T
:: -------
:finish
echo.
exit /b
::
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
