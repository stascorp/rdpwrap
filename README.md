<b>RDP Wrapper Library by Stas'M</b><br>
<br>
The goal of this project is to enable Remote Desktop Host support and concurrent RDP sessions on reduced functionality systems for home usage.<br>
<br>
RDP Wrapper works as a layer between Service Control Manager and Terminal Services, so the original termsrv.dll file remains untouched. Also this method is very strong against Windows Update.<br>
<br>
Screenshots:<br>
<div style="padding-top: 4px; width: 534px; white-space: nowrap; overflow: auto; overflow-y: hidden">
<a href="http://stascorp.com/images/rdpwrap/VistaST.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pVistaST.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/VistaHB.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pVistaHB.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win7ST.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin7ST.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win7HB.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin7HB.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win8DP.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin8DP.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win8CP.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin8CP.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win8RP.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin8RP.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win8.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin8.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win81P.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin81P.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win81.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin81.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win10TP.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin10TP.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win10PTP.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin10PTP.jpg"></a>&nbsp;
<a href="http://stascorp.com/images/rdpwrap/Win10.png" target="_blank"><img src="http://stascorp.com/images/rdpwrap/pWin10.jpg"></a>&nbsp;
</div><br>
This solution was inspired by <a href="http://forums.mydigitallife.info/threads/39411-Windows-Product-Policy-Editor" target="_blank">Windows Product Policy Editor</a>, big thanks to <b>kost</b> :)<br>
- binarymaster<br>
<br>
Attention:<br>
It's recommended to have original termsrv.dll file with the RDP Wrapper installation. If you have modified it before with other patchers, it may become unstable and crash in any moment.<br>
<br>
Information:<br>
• Source code is available, so you can build it on your own<br>
• RDP Wrapper does not patch termsrv.dll, it loads termsrv with different parameters<br>
• RDPWInst and RDPChecker can be redistributed without development folder and batch files<br>
• RDPWInst can be used for unattended installation / deployment<br>
• Windows 2000, XP and Server 2003 will not be supported<br>
<br>
Porting to other platforms:<br>
• <b>ARM</b> for Windows RT (see links below)<br>
• <b>IA-64</b> for Itanium-based Windows Server? <i>Well, I have no idea</i> :)<br>
<br>
Building the binaries:<br>
• <b>x86 Delphi version</b> can be built with <i>Embarcadero RAD Studio 2010</i><br>
• <b>x86/x64 C++ version</b> can be built with <i>Microsoft Visual Studio 2013</i><br>
<br>
<b>Links:</b><br>
• Official GitHub repository:<br>
<a href="https://github.com/binarymaster/rdpwrap/" target="_blank">https://github.com/binarymaster/rdpwrap/</a><br>
• Active discussion in the comments here:<br>
<a href="http://andrewblock.net/2013/07/19/enable-remote-desktop-on-windows-8-core/" target="_blank" title="Enable remote desktop on Windows 8 core / basic">Enable remote desktop on Windows 8 core / basic - Andrew Block .net</a><br>
• MDL Projects and Applications thread here:<br>
<a href="http://forums.mydigitallife.info/threads/55935-RDP-Wrapper-Library-(works-with-Windows-8-1-Basic)" target="_blank" title="Enable remote desktop on Windows 8 core / basic">RDP Wrapper Library (works with Windows 8.1 Basic)</a><br>
• Some ideas about porting to ARM for Windows RT (post #23):<br>
<a href="http://forum.xda-developers.com/showthread.php?t=2093525&page=3" target="_blank" title="Enable remote desktop on Windows 8 core / basic">[Q] Mod Windows RT to enable Remote Desktop</a><br>
• Adding «Remote Desktop Users» group:<br>
<a href="http://superuser.com/questions/680572/" target="_blank">http://superuser.com/questions/680572/</a><br>
<br>
<b>Tutorial videos:</b><br>
• <a href="http://www.youtube.com/watch?v=W9BpbEt1yJw" target="_blank">Updating RDP Wrapper INI file manually</a><br>
• <a href="http://www.youtube.com/watch?v=FiD86tmRBtk" target="_blank">How to find offsets for new termsrv.dll versions</a><br>
<br>
Files description:<br>
<br>
<table style="border-collapse: collapse; width: 100%; border: 1px solid black;" width="" align="">
<tbody>
<tr><td style="border: 1px solid black;"><b>RDPWInst.exe</b></td><td style="border: 1px solid black;">RDP Wrapper Library installer/uninstaller</td></tr>
<tr><td style="border: 1px solid black;"><b>RDPCheck.exe</b></td><td style="border: 1px solid black;">Local RDP Checker (you can check the RDP is working)</td></tr>
<tr><td style="border: 1px solid black;"><b>RDPConf.exe</b></td><td style="border: 1px solid black;">RDP Wrapper Configuration</td></tr>
<tr><td style="border: 1px solid black;"><b>install.bat</b></td><td style="border: 1px solid black;">Quick install batch file</td></tr>
<tr><td style="border: 1px solid black;"><b>uninstall.bat</b></td><td style="border: 1px solid black;">Quick uninstall batch file</td></tr>
</tbody>
</table><br>
Change log:<br>
<br>
<b><u>2014.12.11</u></b><br>
• Version 1.5<br>
• Added INI config support<br>
• Configuration is stored in INI file now<br>
• We can extend version support without building new binaries<br>
• Added support for Windows 8.1 with KB3000850<br>
• Added support for Windows 10 Technical Preview Update 2<br>
• Installer updated<br>
• RDP Config updated<br>
• Diagnostics feature added to RDP Config<br>
<br>
<b><u>2014.11.14</u></b><br>
• Version 1.4<br>
• Added support for Windows 10 Technical Preview Update 1<br>
• Added support for Windows Vista SP2 with KB3003743<br>
• Added support for Windows 7 SP1 with KB3003743<br>
• Added new RDP Configuration Program<br>
<br>
<b><u>2014.10.21</u></b><br>
• Installer updated<br>
• Added feature to install RDP Wrapper to System32 directory<br>
• Fixed issue in the installer - NLA setting now remains unchanged<br>
• Local RDP Checker updated<br>
• SecurityLayer and UserAuthentification values changed on check start<br>
• RDP Checker restores values on exit<br>
<br>
<b><u>2014.10.20</u></b><br>
• Version 1.3<br>
• Added support for Windows 10 Technical Preview<br>
• Added support for Windows 7 with KB2984972<br>
• Added support for Windows 8 with KB2973501<br>
• Added extended support for Windows Vista (SP0, SP1 and SP2)<br>
• Added extended support for Windows 7 (SP0 and SP1)<br>
• Some improvements in the source code<br>
• Installer updated to v2.2<br>
• Fixed installation bug in Vista x64 (wrong expand path)<br>
• Local RDP Checker updated<br>
• Added description to error 0x708<br>
<br>
<b><u>2014.07.26</u></b><br>
• Version 1.2<br>
• Added support for Windows 8 Developer Preview<br>
• Added support for Windows 8 Consumer Preview<br>
• Added support for Windows 8 Release Preview<br>
• Added support for Windows 8.1 Preview<br>
• Added support for Windows 8.1<br>
• More details you will see in the source code<br>
• Installer updated to v2.1<br>
<br>
<b><u>2013.12.09</u></b><br>
• C++ port of RDP Wrapper was made by <b>Fusix</b><br>
• x64 architecture is supported now<br>
• Added new command line installer v2.0<br>
• Added local RDP checker<br>
• Source code (C++ port, installer 2.0, local RDP checker) is also included<br>
<br>
<b><u>2013.10.25</u></b><br>
• Version 1.1 source code is available<br>
<br>
<b><u>2013.10.22</u></b><br>
• Version 1.1<br>
• Stable release<br>
• Improved wrapper (now it can wrap internal unexported termsrv.dll SL Policy function)<br>
• Added support for Windows 8 Single Language (tested on Acer Tablet PC with Intel Atom Z2760)<br>
<br>
<b><u>2013.10.19</u></b><br>
• Version 1.0<br>
• First [beta] version<br>
• Basic SL Policy wrapper<br>
<br>
<b>Supported Terminal Services versions:</b><br>
• <u>6.0.X.X</u> (Windows Vista / Server 2008)<br>
• <u>6.0.6000.16386</u> (Windows Vista)<br>
• <u>6.0.6001.18000</u> (Windows Vista SP1)<br>
• <u>6.0.6002.18005</u> (Windows Vista SP2)<br>
• <u>6.0.6002.19214</u> (Windows Vista SP2 with KB3003743 GDR)<br>
• <u>6.0.6002.23521</u> (Windows Vista SP2 with KB3003743 LDR)<br>
• <u>6.1.X.X</u> (Windows 7 / Server 2008 R2)<br>
• <u>6.1.7600.16385</u> (Windows 7)<br>
• <u>6.1.7601.17514</u> (Windows 7 SP1)<br>
• <u>6.1.7601.18540</u> (Windows 7 SP1 with KB2984972 GDR)<br>
• <u>6.1.7601.22750</u> (Windows 7 SP1 with KB2984972 LDR)<br>
• <u>6.1.7601.18637</u> (Windows 7 SP1 with KB3003743 GDR)<br>
• <u>6.1.7601.22843</u> (Windows 7 SP1 with KB3003743 LDR)<br>
• <u>6.2.8102.0</u> (Windows 8 Developer Preview)<br>
• <u>6.2.8250.0</u> (Windows 8 Consumer Preview)<br>
• <u>6.2.8400.0</u> (Windows 8 Release Preview)<br>
• <u>6.2.9200.16384</u> (Windows 8 / Server 2012)<br>
• <u>6.2.9200.17048</u> (Windows 8 with KB2973501 GDR)<br>
• <u>6.2.9200.21166</u> (Windows 8 with KB2973501 LDR)<br>
• <u>6.3.9431.0</u> (Windows 8.1 Preview)<br>
• <u>6.3.9600.16384</u> (Windows 8.1 / Server 2012 R2)<br>
• <u>6.3.9600.17095</u> (Windows 8.1 with KB2959626)<br>
• <u>6.3.9600.17415</u> (Windows 8.1 with KB3000850)<br>
• <u>6.4.9841.0</u> (Windows 10 Technical Preview)<br>
• <u>6.4.9860.0</u> (Windows 10 Technical Preview Update 1)<br>
• <u>6.4.9879.0</u> (Windows 10 Technical Preview Update 2)<br>
• <u>10.0.9926.0</u> (Windows 10 Pro Technical Preview)<br>
• <u>10.0.10041.0</u> (Windows 10 Pro Technical Preview Update 1)<br>
• <u>10.0.10240.16384</u> (Windows 10 RTM)<br>
<br>
<b>Confirmed working on:</b><br>
• Windows Vista Starter (x86 - Service Pack 1 and higher)<br>
• Windows Vista Home Basic<br>
• Windows Vista Home Premium<br>
• Windows Vista Business<br>
• Windows Vista Enterprise<br>
• Windows Vista Ultimate<br>
• Windows 7 Starter<br>
• Windows 7 Home Basic<br>
• Windows 7 Home Premium<br>
• Windows 7 Professional<br>
• Windows 7 Enterprise<br>
• Windows 7 Ultimate<br>
• Windows 8 Developer Preview<br>
• Windows 8 Consumer Preview<br>
• Windows 8 Release Preview<br>
• Windows 8<br>
• Windows 8 Single Language<br>
• Windows 8 Pro<br>
• Windows 8 Enterprise<br>
• Windows 8.1 Preview<br>
• Windows 8.1<br>
• Windows 8.1 Connected (with Bing)<br>
• Windows 8.1 Single Language<br>
• Windows 8.1 Connected Single Language (with Bing)<br>
• Windows 8.1 Pro<br>
• Windows 8.1 Enterprise<br>
• Windows 10 Technical Preview<br>
• Windows 10 Pro Technical Preview<br>
• Windows 10 Pro<br>
• Windows 10 Enterprise<br>
<br>
<b>Known issues:</b><br>
• RDP works, but termsrv.dll crashes on logon attempt - Windows Vista Starter RTM x86 (termsrv.dll 6.0.6000.16386)<br>
• If Terminal Services hangs at startup, try to add <b>rdpwrap.dll</b> to antivirus exclusions. Also try to isolate RDP Wrapper from other shared services by the command:<br>
<tt>sc config TermService type= own</tt><br>
• RDP Wrapper Installer can be removed by AVG Free Antivirus after reboot - add it to exclusions.<br>
<br>
<u>Installation instructions:</u><br>
1. Download latest release binaries and unpack files<br>
2. Run <b>Command Prompt (cmd)</b> as administrator<br>
3. Change directory to where you extracted the files<br>
4. Type <b>install.bat</b> and press Enter<br>
5. See command output for details<br>
<br>
<u>To uninstall:</u><br>
1. Run <b>Command Prompt</b> as administrator<br>
2. Change directory to where you extracted the files<br>
3. Type <b>uninstall.bat</b> and press Enter<br>
4. See command output for details<br>
