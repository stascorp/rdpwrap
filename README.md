RDP Wrapper Library by Stas'M

Project page: http://stascorp.com/load/1-1-0-63

The goal of this project is to enable Remote Desktop Host support and concurrent RDP sessions on reduced functionality systems for home usage.

RDP Wrapper works as a layer between Service Control Manager and Terminal Services, so the original termsrv.dll file remains untouched. Also this method is very strong against Windows Update.

This solution was inspired by Windows Product Policy Editor, big thanks to kost :)
- binarymaster
(http://forums.mydigitallife.info/threads/39411)

Attention:
It's recommended to have original termsrv.dll file with the RDP Wrapper installation. If you have modified it before with other patchers, it may become unstable and crash in any moment.

Information:
• Source code is available, so you can build it on your own
• RDP Wrapper does not patch termsrv.dll, it loads termsrv with different parameters
• RDPWInst and RDPChecker can be redistributed without development folder and batch files
• RDPWInst can be used for unattended installation / deployment
• Windows 2000, XP and Server 2003 will not be supported

Porting to other platforms:
• ARM for Windows RT (see links below)
• IA-64 for Itanium-based Windows Server? Well, I have no idea :)

Links:
Active discussion in the comments here:
http://andrewblock.net/2013/07/19/enable-remote-desktop-on-windows-8-core/
MDL Projects and Applications thread here:
http://forums.mydigitallife.info/threads/55935-RDP-Wrapper-Library-(works-with-Windows-8-1-Basic)
Some ideas about porting to ARM for Windows RT (post #23):
http://forum.xda-developers.com/showthread.php?t=2093525&page=3

Files description:

RDPWInst.exe       RDP Wrapper Library installer/uninstaller
RDPCheck.exe       Local RDP Checker (you can check the RDP is working)
install.bat        Quick install batch file
uninstall.bat      Quick uninstall batch file
devel              Development folder (source code, resources, etc.)

Change log:

2014.10.21
• Installer updated
• Added feature to install RDP Wrapper to System32 directory
• Fixed issue in the installer - NLA setting now remains unchanged
• Local RDP Checker updated
• SecurityLayer and UserAuthentification values changed on check start
• RDP Checker restores values on exit

2014.10.20
• Version 1.3
• Added support for Windows 10 Technical Preview
• Added support for Windows 7 with KB2984972
• Added support for Windows 8 with KB2973501
• Added extended support for Windows Vista (SP0, SP1 and SP2)
• Added extended support for Windows 7 (SP0 and SP1)
• Some improvements in the source code
• Installer updated to v2.2
• Fixed installation bug in Vista x64 (wrong expand path)
• Local RDP Checker updated
• Added description to error 0x708

2014.07.26
• Version 1.2
• Added support for Windows 8 Developer Preview
• Added support for Windows 8 Consumer Preview
• Added support for Windows 8 Release Preview
• Added support for Windows 8.1 Preview
• Added support for Windows 8.1
• More details you will see in the source code
• Installer updated to v2.1

2013.12.09
• C++ port of RDP Wrapper was made by Fusix
• x64 architecture is supported now
• Added new command line installer v2.0
• Added local RDP checker
• Source code (C++ port, installer 2.0, local RDP checker) is also included

2013.10.25
• Version 1.1 source code is available

2013.10.22
• Version 1.1
• Stable release
• Improved wrapper (now it can wrap internal unexported termsrv.dll SL Policy function)
• Added support for Windows 8 Single Language (tested on Acer Tablet PC with Intel Atom Z2760)

2013.10.19
• Version 1.0
• First [beta] version
• Basic SL Policy wrapper

Supported Terminal Services versions:
• 6.0.X.X (Windows Vista / Server 2008)
• 6.0.6000.16386 (Windows Vista)
• 6.0.6001.18000 (Windows Vista SP1)
• 6.0.6002.18005 (Windows Vista SP2)
• 6.1.X.X (Windows 7 / Server 2008 R2)
• 6.1.7600.16385 (Windows 7)
• 6.1.7601.17514 (Windows 7 SP1)
• 6.1.7601.18540 (Windows 7 SP1 with KB2984972 GDR)
• 6.1.7601.22750 (Windows 7 SP1 with KB2984972 LDR)
• 6.2.8102.0 (Windows 8 Developer Preview)
• 6.2.8250.0 (Windows 8 Consumer Preview)
• 6.2.8400.0 (Windows 8 Release Preview)
• 6.2.9200.16384 (Windows 8 / Server 2012)
• 6.2.9200.17048 (Windows 8 with KB2973501 GDR)
• 6.2.9200.21166 (Windows 8 with KB2973501 LDR)
• 6.3.9431.0 (Windows 8.1 Preview)
• 6.3.9600.16384 (Windows 8.1 / Server 2012 R2)
• 6.3.9600.17095 (Windows 8.1 with KB2959626)
• 6.4.9841.0 (Windows 10 Technical Preview)

Confirmed working on:
• Windows Vista Starter (x86 - Service Pack 1 and higher)
• Windows Vista Home Basic (x86 - Service Pack 1 and higher)
• Windows Vista Home Premium (x86 - Service Pack 1 and higher)
• Windows Vista Business (x86 - Service Pack 1 and higher)
• Windows Vista Enterprise (x86 - Service Pack 1 and higher)
• Windows Vista Ultimate (x86 - Service Pack 1 and higher)
• Windows 7 Starter
• Windows 7 Home Basic
• Windows 7 Home Premium
• Windows 7 Professional
• Windows 7 Enterprise
• Windows 7 Ultimate
• Windows 8 Developer Preview
• Windows 8 Consumer Preview
• Windows 8 Release Preview
• Windows 8
• Windows 8 Single Language
• Windows 8 Pro
• Windows 8 Enterprise
• Windows 8.1 Preview
• Windows 8.1
• Windows 8.1 Single Language
• Windows 8.1 Pro
• Windows 8.1 Enterprise
• Windows 10 Technical Preview

Working partially:
• Windows Vista Starter RTM x86 (termsrv.dll 6.0.6000.16386 : RDP works, but termsrv.dll crashes on logon attempt)

Installation instructions:
1. Download and unpack files
2. Run install.bat as administrator (right click)
3. See command output for details

To uninstall:
1. Run uninstall.bat as administrator (right click)
2. See command output for details
