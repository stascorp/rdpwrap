// RDPWrap C++ port by Fusix (Nikita Parshin)
// assisted by binarymaster (Stas'M)

// Terminal Services supported versions
// 6.0.X.X        (Windows Vista, any)               [policy hook only]
// 6.0.6000.16386 (Windows Vista)                    [policy hook + extended patch]
// 6.0.6001.18000 (Windows Vista SP1)                [policy hook + extended patch]
// 6.0.6001.22565 (Windows Vista SP1 with KB977541)  [todo]
// 6.0.6001.22635 (Windows Vista SP1 with KB970911)  [todo]
// 6.0.6001.22801 (Windows Vista SP1 with KB2381675) [todo]
// 6.0.6002.18005 (Windows Vista SP2)                [policy hook + extended patch]
// 6.0.6002.22269 (Windows Vista SP2 with KB977541)  [todo]
// 6.0.6002.22340 (Windows Vista SP2 with KB970911)  [todo]
// 6.0.6002.22515 (Windows Vista SP2 with KB2381675) [todo]
// 6.0.6002.22641 (Windows Vista SP2 with KB2523307) [todo]
// 6.1.X.X        (Windows 7, any)                   [policy hook only]
// 6.1.7600.16385 (Windows 7)                        [policy hook + extended patch]
// 6.1.7600.20890 (Windows 7 with KB2479710)         [todo]
// 6.1.7600.21316 (Windows 7 with KB2750090)         [todo]
// 6.1.7601.17514 (Windows 7 SP1)                    [policy hook + extended patch]
// 6.1.7601.21650 (Windows 7 SP1 with KB2479710)     [todo]
// 6.1.7601.21866 (Windows 7 SP1 with KB2647409)     [todo]
// 6.1.7601.22104 (Windows 7 SP1 with KB2750090)     [todo]
// 6.1.7601.18540 (Windows 7 SP1 with KB2984972 GDR) [policy hook + extended patch]
// 6.1.7601.22750 (Windows 7 SP1 with KB2984972 LDR) [policy hook + extended patch]
// 6.2.8102.0     (Windows 8 Developer Preview)      [policy hook + extended patch]
// 6.2.8250.0     (Windows 8 Consumer Preview)       [policy hook + extended patch]
// 6.2.8400.0     (Windows 8 Release Preview)        [policy hook + extended patch]
// 6.2.9200.16384 (Windows 8)                        [policy hook + extended patch]
// 6.2.9200.17048 (Windows 8 with KB2973501 GDR)     [policy hook + extended patch]
// 6.2.9200.21166 (Windows 8 with KB2973501 LDR)     [policy hook + extended patch]
// 6.3.9431.0     (Windows 8.1 Preview)              [init hook + extended patch]
// 6.3.9600.16384 (Windows 8.1)                      [init hook + extended patch]
// 6.3.9600.17095 (Windows 8.1 with KB2959626)       [init hook + extended patch]
// 6.4.9841.0     (Windows 10 Technical Preview)     [init hook + extended patch]
// 6.4.9860.0     (Windows 10 Technical Preview 1)   [init hook + extended patch]

// Known failures
// 6.0.6000.16386 (Windows Vista RTM x86, crashes on logon attempt)

// Internal changelog:

// 2014.11.02 :
// - researching termsrv.dll 6.4.9860.0
// - done

// 2014.10.19 :
// - added support for version 6.0.6000.16386 (x64)
// - added support for version 6.0.6001.18000 (x64)
// - added support for version 6.1.7600.16385

// 2014.10.18 :
// - corrected some typos in source
// - simplified signature constants
// - added support for version 6.0.6000.16386 (x86)
// - added support for version 6.0.6001.18000 (x86)
// - added support for version 6.0.6002.18005
// - added support for version 6.1.7601.17514
// - added support for version 6.1.7601.18540
// - added support for version 6.1.7601.22750
// - added support for version 6.2.9200.17048
// - added support for version 6.2.9200.21166

// 2014.10.17 :
// - collecting information about all versions of Terminal Services beginning from Vista
// - added [todo] to the versions list

// 2014.10.16 :
// - got new updates: KB2984972 for Win 7 (still works with 2 concurrent users) and KB2973501 for Win 8 (doesn't work)

// 2014.10.02 :
// - researching Windows 10 TP Remote Desktop
// - done! even without debugging symbols ^^)

// 2014.07.25 :
// - added few comments about ARM platform for developers

// 2014.07.22 :
// - fixed bug in x64 signatures

// 2014.07.20 :
// - added support for Windows 8 Release Preview
// - added support for Windows 8 Consumer Preview
// - added support for Windows 8 Developer Preview

// 2014.07.19 :
// - improved patching of Windows 8
// - added policy patches
// - will patch CDefPolicy::Query
// - will patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled

// 2014.07.18 :
// - researched patched files from MDL forum
// - CSLQuery::GetMaxSessions requires no patching
// - it's better to change the default policy, so...
// - will patch CDefPolicy::Query
// - will patch CEnforcementCore::GetInstanceOfTSLicense
// - will patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
// - the function CSLQuery::Initialize is hooked correctly

// 2014.07.17 :
// - will hook only CSLQuery::Initialize function
// - CSLQuery::GetMaxSessions will be patched
// - added x86 signatures for 6.3.9431.0 (Windows 8.1 Preview)
// - added x64 signatures for 6.3.9431.0 (Windows 8.1 Preview)
// - just for check ^^)

// 2014.07.16 :
// - changing asm opcodes is bad, will hook CSL functions

// 2014.07.15 :
// - added x86 signatures for 6.3.9600.16384 (Windows 8.1)
// - added x64 signatures for 6.3.9600.16384 (Windows 8.1)
// - added x86 signatures for 6.3.9600.17095 (Windows 8.1 with KB2959626)
// - added x64 signatures for 6.3.9600.17095 (Windows 8.1 with KB2959626)

#include "stdafx.h"

typedef struct
{
	union
	{
		struct 
		{
			WORD Minor;
			WORD Major;
		} wVersion;
		DWORD dwVersion;
	};
	WORD Release;
	WORD Build;
} FILE_VERSION;

#ifdef _WIN64
typedef unsigned long long PLATFORM_DWORD;
struct FARJMP
{	// x64 far jump | opcode | assembly
	BYTE MovOp;		// 48	mov rax, ptr
	BYTE MovRegArg;	// B8
	DWORD64 MovArg;	// PTR
	BYTE PushRaxOp; // 50	push rax
	BYTE RetOp;		// C3	retn
};
// x64 signatures
char CDefPolicy_Query_eax_rcx_jmp[] = {0xB8, 0x00, 0x01, 0x00, 0x00, 0x89, 0x81, 0x38, 0x06, 0x00, 0x00, 0x90, 0xEB};
char CDefPolicy_Query_eax_rdi[] = {0xB8, 0x00, 0x01, 0x00, 0x00, 0x89, 0x87, 0x38, 0x06, 0x00, 0x00, 0x90};
char CDefPolicy_Query_eax_rcx[] = {0xB8, 0x00, 0x01, 0x00, 0x00, 0x89, 0x81, 0x38, 0x06, 0x00, 0x00, 0x90};

// termsrv.dll build 6.0.6000.16386

// Original
// .text:000007FF7573C88F          mov     eax, [rcx+638h]
// .text:000007FF7573C895          cmp     [rcx+63Ch], eax
// .text:000007FF7573C89B          jnz     short loc_7FF7573C8B3
//_______________
//
// Changed
// .text:000007FF7573C88F          mov     eax, 100h
// .text:000007FF7573C894          mov     [rcx+638h], eax
// .text:000007FF7573C89A          nop
// .text:000007FF7573C89B          jmp     short loc_7FF7573C8B3
// char CDefPolicy_Query_eax_rcx_jmp[]

// termsrv.dll build 6.0.6001.18000

// Original
// .text:000007FF76285BD7          mov     eax, [rcx+638h]
// .text:000007FF76285BDD          cmp     [rcx+63Ch], eax
// .text:000007FF76285BE3          jnz     short loc_7FF76285BFB
//_______________
//
// Changed
// .text:000007FF76285BD7          mov     eax, 100h
// .text:000007FF76285BDC          mov     [rcx+638h], eax
// .text:000007FF76285BE2          nop
// .text:000007FF76285BE3          jmp     short loc_7FF76285BFB
// char CDefPolicy_Query_eax_rcx_jmp[]

// termsrv.dll build 6.0.6002.18005

// Original
// .text:000007FF76725E83          mov     eax, [rcx+638h]
// .text:000007FF76725E89          cmp     [rcx+63Ch], eax
// .text:000007FF76725E8F          jz      short loc_7FF76725EA7
//_______________
//
// Changed
// .text:000007FF76725E83          mov     eax, 100h
// .text:000007FF76725E88          mov     [rcx+638h], eax
// .text:000007FF76725E8E          nop
// .text:000007FF76725E8F          jmp     short loc_7FF76725EA7
// char CDefPolicy_Query_eax_rcx_jmp[]

// termsrv.dll build 6.1.7600.16385

// Original
// .text:000007FF75A97AD2          cmp     [rdi+63Ch], eax
// .text:000007FF75A97AD8          jz      loc_7FF75AA4978
//_______________
//
// Changed
// .text:000007FF75A97AD2          mov     eax, 100h
// .text:000007FF75A97AD7          mov     [rdi+638h], eax
// .text:000007FF75A97ADD          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.1.7601.17514

// Original
// .text:000007FF75A97D8A          cmp     [rdi+63Ch], eax
// .text:000007FF75A97D90          jz      loc_7FF75AA40F4
//_______________
//
// Changed
// .text:000007FF75A97D8A          mov     eax, 100h
// .text:000007FF75A97D8F          mov     [rdi+638h], eax
// .text:000007FF75A97D95          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.1.7601.18540

// Original
// .text:000007FF75A97C82          cmp     [rdi+63Ch], eax
// .text:000007FF75A97C88          jz      loc_7FF75AA3FBD
//_______________
//
// Changed
// .text:000007FF75A97C82          mov     eax, 100h
// .text:000007FF75A97C87          mov     [rdi+638h], eax
// .text:000007FF75A97C8D          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.1.7601.22750

// Original
// .text:000007FF75A97C92          cmp     [rdi+63Ch], eax
// .text:000007FF75A97C98          jz      loc_7FF75AA40A2
//_______________
//
// Changed
// .text:000007FF75A97C92          mov     eax, 100h
// .text:000007FF75A97C97          mov     [rdi+638h], eax
// .text:000007FF75A97C9D          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.2.8102.0

// Original
// .text:000000018000D3E6          cmp     [rdi+63Ch], eax
// .text:000000018000D3EC          jz      loc_180027792
//_______________
//
// Changed
// .text:000000018000D3E6          mov     eax, 100h
// .text:000000018000D3EB          mov     [rdi+638h], eax
// .text:000000018000D3F1          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.2.8250.0

// Original
// .text:000000018001187A          cmp     [rdi+63Ch], eax
// .text:0000000180011880          jz      loc_1800273A2
//_______________
//
// Changed
// .text:000000018001187A          mov     eax, 100h
// .text:000000018001187F          mov     [rdi+638h], eax
// .text:0000000180011885          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.2.8400.0

// Original
// .text:000000018001F102          cmp     [rdi+63Ch], eax
// .text:000000018001F108          jz      loc_18003A02E
//_______________
//
// Changed
// .text:000000018001F102          mov     eax, 100h
// .text:000000018001F107          mov     [rdi+638h], eax
// .text:000000018001F10D          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.2.9200.16384

// Original
// .text:000000018002A31A          cmp     [rdi+63Ch], eax
// .text:000000018002A320          jz      loc_18003A0F9
//_______________
//
// Changed
// .text:000000018002A31A          mov     eax, 100h
// .text:000000018002A31F          mov     [rdi+638h], eax
// .text:000000018002A325          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.2.9200.17048

// Original
// .text:000000018001F206          cmp     [rdi+63Ch], eax
// .text:000000018001F20C          jz      loc_18003A1B4
//_______________
//
// Changed
// .text:000000018001F206          mov     eax, 100h
// .text:000000018001F20B          mov     [rdi+638h], eax
// .text:000000018001F211          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.2.9200.21166

// Original
// .text:000000018002A3B6          cmp     [rdi+63Ch], eax
// .text:000000018002A3BC          jz      loc_18003A174
//_______________
//
// Changed
// .text:000000018002A3B6          mov     eax, 100h
// .text:000000018002A3BB          mov     [rdi+638h], eax
// .text:000000018002A3C1          nop
// char CDefPolicy_Query_eax_rdi[]

// termsrv.dll build 6.3.9431.0

// Original
// .text:00000001800350FD          cmp     [rcx+63Ch], eax
// .text:0000000180035103          jz      loc_18004F6AE
//_______________
//
// Changed
// .text:00000001800350FD          mov     eax, 100h
// .text:0000000180035102          mov     [rcx+638h], eax
// .text:0000000180035108          nop
// char CDefPolicy_Query_eax_rcx[]

// termsrv.dll build 6.3.9600.16384

// Original
// .text:0000000180057829          cmp     [rcx+63Ch], eax
// .text:000000018005782F          jz      loc_18005E850
//_______________
//
// Changed
// .text:0000000180057829          mov     eax, 100h
// .text:000000018005782E          mov     [rcx+638h], eax
// .text:0000000180057834          nop
// char CDefPolicy_Query_eax_rcx[]

// termsrv.dll build 6.3.9600.17095

// Original
// .text:000000018001F6A1          cmp     [rcx+63Ch], eax
// .text:000000018001F6A7          jz      loc_18007284B
//_______________
//
// Changed
// .text:000000018001F6A1          mov     eax, 100h
// .text:000000018001F6A6          mov     [rcx+638h], eax
// .text:000000018001F6AC          nop
// char CDefPolicy_Query_eax_rcx[]

// termsrv.dll build 6.4.9841.0

// Original
// .text:000000018000C125          cmp     [rcx+63Ch], eax
// .text:000000018000C12B          jz      sub_18003BABC
//_______________
//
// Changed
// .text:000000018000C125          mov     eax, 100h
// .text:000000018000C12A          mov     [rcx+638h], eax
// .text:000000018000C130          nop
// char CDefPolicy_Query_eax_rcx[]

// termsrv.dll build 6.4.9860.0

// Original
// .text:000000018000B9F5          cmp     [rcx+63Ch], eax
// .text:000000018000B9FB          jz      sub_18003B9C8
//_______________
//
// Changed
// .text:000000018000B9F5          mov     eax, 100h
// .text:000000018000B9FA          mov     [rcx+638h], eax
// .text:000000018000BA00          nop
// char CDefPolicy_Query_eax_rcx[]

#else
typedef unsigned long PLATFORM_DWORD;
struct FARJMP
{	// x86 far jump | opcode | assembly
	BYTE PushOp;	// 68	push ptr
	DWORD PushArg;	// PTR
	BYTE RetOp;		// C3	retn
};
// x86 signatures
char CDefPolicy_Query_edx_ecx[] = {0xBA, 0x00, 0x01, 0x00, 0x00, 0x89, 0x91, 0x20, 0x03, 0x00, 0x00, 0x5E, 0x90};
char CDefPolicy_Query_eax_esi[] = {0xB8, 0x00, 0x01, 0x00, 0x00, 0x89, 0x86, 0x20, 0x03, 0x00, 0x00, 0x90};
char CDefPolicy_Query_eax_ecx[] = {0xB8, 0x00, 0x01, 0x00, 0x00, 0x89, 0x81, 0x20, 0x03, 0x00, 0x00, 0x90};

// termsrv.dll build 6.0.6000.16386

// Original
// .text:6F335CD8          cmp     edx, [ecx+320h]
// .text:6F335CDE          pop     esi
// .text:6F335CDF          jz      loc_6F3426F1
//_______________
//
// Changed
// .text:6F335CD8          mov     edx, 100h
// .text:6F335CDD          mov     [ecx+320h], edx
// .text:6F335CE3          pop     esi
// .text:6F335CE4          nop
// char CDefPolicy_Query_edx_ecx[]

// termsrv.dll build 6.0.6001.18000

// Original
// .text:6E817FD8          cmp     edx, [ecx+320h]
// .text:6E817FDE          pop     esi
// .text:6E817FDF          jz      loc_6E826F16
//_______________
//
// Changed
// .text:6E817FD8          mov     edx, 100h
// .text:6E817FDD          mov     [ecx+320h], edx
// .text:6E817FE3          pop     esi
// .text:6E817FE4          nop
// char CDefPolicy_Query_edx_ecx[]

// termsrv.dll build 6.0.6002.18005

// Original
// .text:6F5979C0          cmp     edx, [ecx+320h]
// .text:6F5979C6          pop     esi
// .text:6F5979C7          jz      loc_6F5A6F26
//_______________
//
// Changed
// .text:6F5979C0          mov     edx, 100h
// .text:6F5979C5          mov     [ecx+320h], edx
// .text:6F5979CB          pop     esi
// .text:6F5979CC          nop
// char CDefPolicy_Query_edx_ecx[]

// termsrv.dll build 6.1.7600.16385

// Original
// .text:6F2F96F3          cmp     eax, [esi+320h]
// .text:6F2F96F9          jz      loc_6F30E256
//_______________
//
// Changed
// .text:6F2F96F3          mov     eax, 100h
// .text:6F2F96F8          mov     [esi+320h], eax
// .text:6F2F96FE          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.1.7601.17514

// Original
// .text:6F2F9D53          cmp     eax, [esi+320h]
// .text:6F2F9D59          jz      loc_6F30B25E
//_______________
//
// Changed
// .text:6F2F9D53          mov     eax, 100h
// .text:6F2F9D58          mov     [esi+320h], eax
// .text:6F2F9D5E          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.1.7601.18540

// Original
// .text:6F2F9D9F          cmp     eax, [esi+320h]
// .text:6F2F9DA5          jz      loc_6F30B2AE
//_______________
//
// Changed
// .text:6F2F9D9F          mov     eax, 100h
// .text:6F2F9DA4          mov     [esi+320h], eax
// .text:6F2F9DAA          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.1.7601.22750

// Original
// .text:6F2F9E21          cmp     eax, [esi+320h]
// .text:6F2F9E27          jz      loc_6F30B6CE
//_______________
//
// Changed
// .text:6F2F9E21          mov     eax, 100h
// .text:6F2F9E26          mov     [esi+320h], eax
// .text:6F2F9E2C          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.2.8102.0

// Original
// .text:1000E47C          cmp     eax, [esi+320h]
// .text:1000E482          jz      loc_1002D775
//_______________
//
// Changed
// .text:1000E47C          mov     eax, 100h
// .text:1000E481          mov     [esi+320h], eax
// .text:1000E487          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.2.8250.0

// Original
// .text:10013520          cmp     eax, [esi+320h]
// .text:10013526          jz      loc_1002DB85
//_______________
//
// Changed
// .text:10013520          mov     eax, 100h
// .text:10013525          mov     [esi+320h], eax
// .text:1001352B          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.2.8400.0

// Original
// .text:10013E48          cmp     eax, [esi+320h]
// .text:10013E4E          jz      loc_1002E079
//_______________
//
// Changed
// .text:10013E48          mov     eax, 100h
// .text:10013E4D          mov     [esi+320h], eax
// .text:10013E53          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.2.9200.16384

// Original
// .text:10013F08          cmp     eax, [esi+320h]
// .text:10013F0E          jz      loc_1002E161
//_______________
//
// Changed
// .text:10013F08          mov     eax, 100h
// .text:10013F0D          mov     [esi+320h], eax
// .text:10013F13          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.2.9200.17048

// Original
// .text:1001F408          cmp     eax, [esi+320h]
// .text:1001F40E          jz      loc_1002E201
//_______________
//
// Changed
// .text:1001F408          mov     eax, 100h
// .text:1001F40D          mov     [esi+320h], eax
// .text:1001F413          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.2.9200.21166

// Original
// .text:10013F30          cmp     eax, [esi+320h]
// .text:10013F36          jz      loc_1002E189
//_______________
//
// Changed
// .text:10013F30          mov     eax, 100h
// .text:10013F35          mov     [esi+320h], eax
// .text:10013F3B          nop
// char CDefPolicy_Query_eax_esi[]

// termsrv.dll build 6.3.9431.0

// Original
// .text:1002EA25          cmp     eax, [ecx+320h]
// .text:1002EA2B          jz      loc_100348C1
//_______________
//
// Changed
// .text:1002EA25          mov     eax, 100h
// .text:1002EA2A          mov     [ecx+320h], eax
// .text:1002EA30          nop
// char CDefPolicy_Query_eax_ecx[]

// termsrv.dll build 6.3.9600.16384

// Original
// .text:10016115          cmp     eax, [ecx+320h]
// .text:1001611B          jz      loc_10034DE1
//_______________
//
// Changed
// .text:10016115          mov     eax, 100h
// .text:1001611A          mov     [ecx+320h], eax
// .text:10016120          nop
// char CDefPolicy_Query_eax_ecx[]

// termsrv.dll build 6.3.9600.17095

// Original
// .text:10037529          cmp     eax, [ecx+320h]
// .text:1003752F          jz      loc_10043662
//_______________
//
// Changed
// .text:10037529          mov     eax, 100h
// .text:1003752E          mov     [ecx+320h], eax
// .text:10037534          nop
// char CDefPolicy_Query_eax_ecx[]

// termsrv.dll build 6.4.9841.0

// Original
// .text:1003B989          cmp     eax, [ecx+320h]
// .text:1003B98F          jz      loc_1005E809
//_______________
//
// Changed
// .text:1003B989          mov     eax, 100h
// .text:1003B98E          mov     [ecx+320h], eax
// .text:1003B994          nop
// char CDefPolicy_Query_eax_ecx[]

// termsrv.dll build 6.4.9860.0

// Original
// .text:1003BEC9          cmp     eax, [ecx+320h]
// .text:1003BECF          jz      loc_1005EE1A
//_______________
//
// Changed
// .text:1003BEC9          mov     eax, 100h
// .text:1003BECE          mov     [ecx+320h], eax
// .text:1003BED4          nop
// char CDefPolicy_Query_eax_ecx[]

#endif

FARJMP Old_SLGetWindowsInformationDWORD, Stub_SLGetWindowsInformationDWORD;
SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;

HMODULE hTermSrv;
HMODULE hSLC;
PLATFORM_DWORD TermSrvBase;
FILE_VERSION FV;
SERVICEMAIN _ServiceMain;
SVCHOSTPUSHSERVICEGLOBALS _SvchostPushServiceGlobals;
bool AlreadyHooked = false;

void WriteToLog(LPSTR Text)
{
	DWORD dwBytesOfWritten;

	HANDLE hFile = CreateFile(L"\\rdpwrap.txt", GENERIC_WRITE, FILE_SHARE_WRITE|FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hFile == INVALID_HANDLE_VALUE) return;

	SetFilePointer(hFile, 0, 0, FILE_END);
	WriteFile(hFile, Text, strlen(Text), &dwBytesOfWritten, NULL);
	CloseHandle(hFile);
}

PLATFORM_DWORD SearchAddressBySignature(char *StartPosition, PLATFORM_DWORD Size, char *Signature, int SignatureSize)
{
	PLATFORM_DWORD AddressReturn = -1;

	for (PLATFORM_DWORD i = 0; i < Size; i++)
	{
		for (int j = 0; StartPosition[i+j] == Signature[j] && j < SignatureSize; j++)
		{
			if (j == SignatureSize-1) AddressReturn = (PLATFORM_DWORD)&StartPosition[i];
		}
	}

	return AddressReturn;
}

bool GetModuleCodeSectionInfo(HMODULE hModule, PLATFORM_DWORD *BaseAddr, PLATFORM_DWORD *BaseSize)
{
	PIMAGE_DOS_HEADER		pDosHeader;
	PIMAGE_FILE_HEADER      pFileHeader;
	PIMAGE_OPTIONAL_HEADER  pOptionalHeader;

	if (hModule == NULL) return false;

	pDosHeader = (PIMAGE_DOS_HEADER)hModule;
	pFileHeader = (PIMAGE_FILE_HEADER)(((PBYTE)hModule)+pDosHeader->e_lfanew+4);
	pOptionalHeader = (PIMAGE_OPTIONAL_HEADER)(pFileHeader+1);

	*BaseAddr = (PLATFORM_DWORD)hModule;
	*BaseSize = (PLATFORM_DWORD)pOptionalHeader->SizeOfCode;

	if (*BaseAddr <= 0 || *BaseSize <= 0) return false;
	return true;
}

void SetThreadsState(bool Resume)
{
	HANDLE h, hThread;
	DWORD CurrTh, CurrPr;
	THREADENTRY32 Thread;

	CurrTh = GetCurrentThreadId();
	CurrPr = GetCurrentProcessId();
	
	h = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
	if (h != INVALID_HANDLE_VALUE)
	{
		Thread.dwSize = sizeof(THREADENTRY32);
		Thread32First(h, &Thread);
		do
		{
			if (Thread.th32ThreadID != CurrTh && Thread.th32OwnerProcessID == CurrPr)
			{
				hThread = OpenThread(THREAD_SUSPEND_RESUME, false, Thread.th32ThreadID);
				if (hThread != INVALID_HANDLE_VALUE)
				{
					if (Resume)		ResumeThread(hThread);
					else			SuspendThread(hThread);
					CloseHandle(hThread);
				}
			}
		} while (Thread32Next(h, &Thread));	
		CloseHandle(h);
	}
}

BOOL __stdcall GetModuleVersion(LPCWSTR lptstrModuleName, FILE_VERSION *FileVersion)
{
	typedef struct 
	{
		WORD             wLength;
		WORD             wValueLength;
		WORD             wType;
		WCHAR            szKey[16];
		WORD             Padding1;
		VS_FIXEDFILEINFO Value;
		WORD             Padding2;
		WORD             Children;
	} VS_VERSIONINFO;

	HMODULE hMod = GetModuleHandle(lptstrModuleName);
	if(!hMod)
	{
		return false;
	}
	
	HRSRC hResourceInfo = FindResourceW(hMod, (LPCWSTR)1, (LPCWSTR)0x10);	
	if(!hResourceInfo)
	{
		return false;
	}
	
	VS_VERSIONINFO *VersionInfo = (VS_VERSIONINFO*)LoadResource(hMod, hResourceInfo);
	if(!VersionInfo)
	{
		return false;
	}

	FileVersion->dwVersion = VersionInfo->Value.dwFileVersionMS;
	FileVersion->Release = (WORD)(VersionInfo->Value.dwFileVersionLS >> 16);
	FileVersion->Build = (WORD)VersionInfo->Value.dwFileVersionLS;

	return true;
}

BOOL __stdcall GetFileVersion(LPCWSTR lptstrFilename, FILE_VERSION *FileVersion)
{
	typedef struct 
	{
		WORD             wLength;
		WORD             wValueLength;
		WORD             wType;
		WCHAR            szKey[16];
		WORD             Padding1;
		VS_FIXEDFILEINFO Value;
		WORD             Padding2;
		WORD             Children;
	} VS_VERSIONINFO;

	HMODULE hFile = LoadLibraryExW(lptstrFilename, NULL, LOAD_LIBRARY_AS_DATAFILE);
	if(!hFile)
	{
		return false;
	}
	
	HRSRC hResourceInfo = FindResourceW(hFile, (LPCWSTR)1, (LPCWSTR)0x10);	
	if(!hResourceInfo)
	{
		return false;
	}
	
	VS_VERSIONINFO *VersionInfo = (VS_VERSIONINFO*)LoadResource(hFile, hResourceInfo);
	if(!VersionInfo)
	{
		return false;
	}

	FileVersion->dwVersion = VersionInfo->Value.dwFileVersionMS;
	FileVersion->Release = (WORD)(VersionInfo->Value.dwFileVersionLS >> 16);
	FileVersion->Build = (WORD)VersionInfo->Value.dwFileVersionLS;

	return true;
}

bool OverrideSL(LPWSTR ValueName, DWORD *Value)
{
	// Allow Remote Connections
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-AllowRemoteConnections") == 0)
	{
		*Value = 1;
		return true;
	}
	// Allow Multiple Sessions
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-AllowMultipleSessions") == 0)
	{
		*Value = 1;
		return true;
	}
	// Allow Multiple Sessions (Application Server Mode)
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-AllowAppServerMode") == 0)
	{
		*Value = 1;
		return true;
	}
	// Allow Multiple Monitors
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-AllowMultimon") == 0)
	{
		*Value = 1;
		return true;
	}
	// Max User Sessions (0 = unlimited)
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-MaxUserSessions") == 0)
	{
		*Value = 0;
		return true;
	}
	// Max Debug Sessions (Win 8, 0 = unlimited)
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-ce0ad219-4670-4988-98fb-89b14c2f072b-MaxSessions") == 0)
	{
		*Value = 0;
		return true;	
	}
	// Max Sessions
	// 0 - logon not possible even from console
	// 1 - only one active user (console or remote)
	// 2 - allow concurrent sessions
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-45344fe7-00e6-4ac6-9f01-d01fd4ffadfb-MaxSessions") == 0)
	{
		*Value = 2;
		return true;
	}
	// Allow Advanced Compression with RDP 7 Protocol
	if (wcscmp(ValueName, L"TerminalServices-RDP-7-Advanced-Compression-Allowed") == 0)
	{
		*Value = 1;
		return true;
	}
	// IsTerminalTypeLocalOnly = 0
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-45344fe7-00e6-4ac6-9f01-d01fd4ffadfb-LocalOnly") == 0)
	{
		*Value = 0;
		return true;
	}
	// Max Sessions (hard limit)
	if (wcscmp(ValueName, L"TerminalServices-RemoteConnectionManager-8dc86f1d-9969-4379-91c1-06fe1dc60575-MaxSessions") == 0)
	{
		*Value = 1000;
		return true;	
	}
	return false;
}

HRESULT WINAPI New_SLGetWindowsInformationDWORD(PWSTR pwszValueName, DWORD *pdwValue)
{
	// wrapped SLGetWindowsInformationDWORD function
	// termsrv.dll will call this function instead of original SLC.dll

	// Override SL Policy

	extern FARJMP Old_SLGetWindowsInformationDWORD, Stub_SLGetWindowsInformationDWORD;
	extern SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;

	char *Log;
	DWORD dw;
	SIZE_T bw;
	HRESULT Result;

	Log = new char[1024];
	wsprintfA(Log, "Policy query: %S\r\n", pwszValueName);
	WriteToLog(Log);
	delete[] Log;

	if (OverrideSL(pwszValueName, &dw))
	{
		*pdwValue = dw;

		Log = new char[1024];
		wsprintfA(Log, "Rewrite: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;

		return S_OK; 
	}

	WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Old_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
	Result = _SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
	if (Result == S_OK)
	{
		Log = new char[1024];
		wsprintfA(Log, "Result: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;
	} else {
		WriteToLog("Failed\r\n");
	}
	WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Stub_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);

	return Result;
}

HRESULT __fastcall New_Win8SL(PWSTR pwszValueName, DWORD *pdwValue)
{
	// wrapped unexported function SLGetWindowsInformationDWORDWrapper in termsrv.dll
	// for Windows 8 support

	// Override SL Policy

	extern SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;

	char *Log;
	DWORD dw;
	HRESULT Result;

	Log = new char[1024];
	wsprintfA(Log, "Policy query: %S\r\n", pwszValueName);
	WriteToLog(Log);
	delete[] Log;

	if (OverrideSL(pwszValueName, &dw))
	{
		*pdwValue = dw;

		Log = new char[1024];
		wsprintfA(Log, "Rewrite: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;

		return S_OK; 
	}

	Result = _SLGetWindowsInformationDWORD(pwszValueName, pdwValue);
	if (Result == S_OK)
	{
		Log = new char[1024];
		wsprintfA(Log, "Result: %i\r\n", dw);
		WriteToLog(Log);
		delete[] Log;
	} else {
		WriteToLog("Failed\r\n");
	}
	
	return Result;
}

#ifndef _WIN64
HRESULT __fastcall New_Win8SL_CP(DWORD arg1, DWORD *pdwValue, PWSTR pwszValueName, DWORD arg4)
{
	// wrapped unexported function SLGetWindowsInformationDWORDWrapper in termsrv.dll
	// for Windows 8 Consumer Preview support

	return New_Win8SL(pwszValueName, pdwValue);
}
#endif

HRESULT WINAPI New_CSLQuery_Initialize()
{
	extern PLATFORM_DWORD TermSrvBase;
	extern FILE_VERSION FV;

	char *Log;
	DWORD *bServerSku = NULL;
	DWORD *bRemoteConnAllowed = NULL;
	DWORD *bFUSEnabled = NULL;
	DWORD *bAppServerAllowed = NULL;
	DWORD *bMultimonAllowed = NULL;
	DWORD *lMaxUserSessions = NULL;
	DWORD *ulMaxDebugSessions = NULL;
	DWORD *bInitialized = NULL;

	WriteToLog("> CSLQuery::Initialize\r\n");

	if (FV.Release == 9431 && FV.Build == 0)
	{
		#ifdef _WIN64
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xC4490);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xC4494);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xC4498);
		bInitialized =			(DWORD*)(TermSrvBase + 0xC449C);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xC44A0);
		bServerSku =			(DWORD*)(TermSrvBase + 0xC44A4);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xC44A8);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xC44AC);
		#else
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xA22A8);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xA22AC);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xA22B0);
		bInitialized =			(DWORD*)(TermSrvBase + 0xA22B4);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xA22B8);
		bServerSku =			(DWORD*)(TermSrvBase + 0xA22BC);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xA22C0);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xA22C4);
		#endif
	}
	if (FV.Release == 9600 && FV.Build == 16384)
	{
		#ifdef _WIN64
		bServerSku =			(DWORD*)(TermSrvBase + 0xE6494);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xE6498);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xE649C);
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xE64A0);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xE64A4);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xE64A8);
		bInitialized =			(DWORD*)(TermSrvBase + 0xE64AC);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xE64B0);
		#else
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xC02A8);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xC02AC);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xC02B0);
		bInitialized =			(DWORD*)(TermSrvBase + 0xC02B4);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xC02B8);
		bServerSku =			(DWORD*)(TermSrvBase + 0xC02BC);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xC02C0);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xC02C4);
		#endif
		/* __ARM_ARCH_7
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0x?);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0x?);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0x?);
		bInitialized =			(DWORD*)(TermSrvBase + 0x?);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0x?);
		bServerSku =			(DWORD*)(TermSrvBase + 0x?);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0x?);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0x?);
		*/
	}
	if (FV.Release == 9600 && FV.Build == 17095)
	{
		#ifdef _WIN64
		bServerSku =			(DWORD*)(TermSrvBase + 0xE4494);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xE4498);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xE449C);
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xE44A0);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xE44A4);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xE44A8);
		bInitialized =			(DWORD*)(TermSrvBase + 0xE44AC);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xE44B0);
		#else
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xC12A8);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xC12AC);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xC12B0);
		bInitialized =			(DWORD*)(TermSrvBase + 0xC12B4);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xC12B8);
		bServerSku =			(DWORD*)(TermSrvBase + 0xC12BC);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xC12C0);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xC12C4);
		#endif
	}
	if (FV.Release == 9841 && FV.Build == 0)
	{
		#ifdef _WIN64
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xECFF8);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xECFFC);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xED000);
		bInitialized =			(DWORD*)(TermSrvBase + 0xED004);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xED008);
		bServerSku =			(DWORD*)(TermSrvBase + 0xED00C);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xED010);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xED014);
		#else
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xBF9F0);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xBF9F4);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xBF9F8);
		bInitialized =			(DWORD*)(TermSrvBase + 0xBF9FC);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xBFA00);
		bServerSku =			(DWORD*)(TermSrvBase + 0xBFA04);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xBFA08);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xBFA0C);
		#endif
	}
	if (FV.Release == 9860 && FV.Build == 0)
	{
		#ifdef _WIN64
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xECBD8);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xECBDC);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xECBE0);
		bInitialized =			(DWORD*)(TermSrvBase + 0xECBE4);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xECBE8);
		bServerSku =			(DWORD*)(TermSrvBase + 0xECBEC);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xECBF0);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xECBF4);
		#else
		bFUSEnabled =			(DWORD*)(TermSrvBase + 0xBF7E0);
		lMaxUserSessions =		(DWORD*)(TermSrvBase + 0xBF7E4);
		bAppServerAllowed =		(DWORD*)(TermSrvBase + 0xBF7E8);
		bInitialized =			(DWORD*)(TermSrvBase + 0xBF7EC);
		bMultimonAllowed =		(DWORD*)(TermSrvBase + 0xBF7F0);
		bServerSku =			(DWORD*)(TermSrvBase + 0xBF7F4);
		ulMaxDebugSessions =	(DWORD*)(TermSrvBase + 0xBF7F8);
		bRemoteConnAllowed =	(DWORD*)(TermSrvBase + 0xBF7FC);
		#endif
	}
	if (bServerSku)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] bServerSku = 1\r\n", bServerSku);
		WriteToLog(Log);
		delete[] Log;

		*bServerSku = 1;
	}
	if (bRemoteConnAllowed)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] bRemoteConnAllowed = 1\r\n", bRemoteConnAllowed);
		WriteToLog(Log);
		delete[] Log;

		*bRemoteConnAllowed = 1;
	}
	if (bFUSEnabled)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] bFUSEnabled = 1\r\n", bFUSEnabled);
		WriteToLog(Log);
		delete[] Log;

		*bFUSEnabled = 1;
	}
	if (bAppServerAllowed)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] bAppServerAllowed = 1\r\n", bAppServerAllowed);
		WriteToLog(Log);
		delete[] Log;

		*bAppServerAllowed = 1;
	}
	if (bMultimonAllowed)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] bMultimonAllowed = 1\r\n", bMultimonAllowed);
		WriteToLog(Log);
		delete[] Log;

		*bMultimonAllowed = 1;
	}
	if (lMaxUserSessions)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] lMaxUserSessions = 0\r\n", lMaxUserSessions);
		WriteToLog(Log);
		delete[] Log;

		*lMaxUserSessions = 0;
	}
	if (ulMaxDebugSessions)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] ulMaxDebugSessions = 0\r\n", ulMaxDebugSessions);
		WriteToLog(Log);
		delete[] Log;

		*ulMaxDebugSessions = 0;
	}
	if (bInitialized)
	{
		Log = new char[1024];
		wsprintfA(Log, "[0x%p] bInitialized = 1\r\n", bInitialized);
		WriteToLog(Log);
		delete[] Log;

		*bInitialized = 1;
	}
	return S_OK;
}

void Hook()
{
	extern FARJMP Old_SLGetWindowsInformationDWORD, Stub_SLGetWindowsInformationDWORD;
	extern SLGETWINDOWSINFORMATIONDWORD _SLGetWindowsInformationDWORD;
	extern HMODULE hTermSrv;
	extern HMODULE hSLC;
	extern PLATFORM_DWORD TermSrvBase;
	extern FILE_VERSION FV;

	AlreadyHooked = true;

	bool Result;
	char *Log;
	SIZE_T bw;
	WORD Ver = 0;
	PLATFORM_DWORD TermSrvSize, SignPtr;
	FARJMP Jump;
	BYTE b;

	WriteToLog("init\r\n");

	hTermSrv = LoadLibrary(L"termsrv.dll");
	if (hTermSrv == 0)
	{
		WriteToLog("Error: Failed to load Terminal Services library\r\n");
		return;
	}
	_ServiceMain = (SERVICEMAIN)GetProcAddress(hTermSrv, "ServiceMain");
	_SvchostPushServiceGlobals = (SVCHOSTPUSHSERVICEGLOBALS)GetProcAddress(hTermSrv, "SvchostPushServiceGlobals");

	Log = new char[1024];
	wsprintfA(Log, "Base addr:  0x%p\r\n", hTermSrv);
	WriteToLog(Log);
	delete[] Log;

	Log = new char[1024];
	wsprintfA(Log, "SvcMain:    termsrv.dll+0x%p\r\n", (PLATFORM_DWORD)_ServiceMain - (PLATFORM_DWORD)hTermSrv);
	WriteToLog(Log);
	delete[] Log;

	Log = new char[1024];
	wsprintfA(Log, "SvcGlobals: termsrv.dll+0x%p\r\n", (PLATFORM_DWORD)_SvchostPushServiceGlobals - (PLATFORM_DWORD)hTermSrv);
	WriteToLog(Log);
	delete[] Log;

	// check termsrv version
	if (GetModuleVersion(L"termsrv.dll", &FV))
	{
		Ver = (BYTE)FV.wVersion.Minor | ((BYTE)FV.wVersion.Major << 8);
	} else {
		// check NT version
		// Ver = GetVersion(); // deprecated
		// Ver = ((Ver & 0xFF) << 8) | ((Ver & 0xFF00) >> 8);
	}
	if (Ver == 0)
	{
		WriteToLog("Error: Failed to detect Terminal Services version\r\n");
		return;
	}

	Log = new char[1024];
	wsprintfA(Log, "Version: %d.%d\r\n", FV.wVersion.Major, FV.wVersion.Minor);
	WriteToLog(Log);
	delete[] Log;

	Log = new char[1024];
	wsprintfA(Log, "Release: %d\r\n", FV.Release);
	WriteToLog(Log);
	delete[] Log;

	Log = new char[1024];
	wsprintfA(Log, "Build:   %d\r\n", FV.Build);
	WriteToLog(Log);
	delete[] Log;

	// temporarily freeze threads
	WriteToLog("freeze\r\n");
	SetThreadsState(false);

	if (Ver == 0x0600)
	{
		// Windows Vista
		// uses SL Policy API (slc.dll)
		
		// load slc.dll and hook function
		hSLC = LoadLibrary(L"slc.dll");
		_SLGetWindowsInformationDWORD = (SLGETWINDOWSINFORMATIONDWORD)GetProcAddress(hSLC, "SLGetWindowsInformationDWORD");
		if (_SLGetWindowsInformationDWORD != INVALID_HANDLE_VALUE)
		{
			// rewrite original function to call our function (make hook)

			WriteToLog("Hook SLGetWindowsInformationDWORD\r\n");
			#ifdef _WIN64
			Stub_SLGetWindowsInformationDWORD.MovOp = 0x48;
			Stub_SLGetWindowsInformationDWORD.MovRegArg = 0xB8;
			Stub_SLGetWindowsInformationDWORD.MovArg =  (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.PushRaxOp = 0x50;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#else
			Stub_SLGetWindowsInformationDWORD.PushOp = 0x68;
			Stub_SLGetWindowsInformationDWORD.PushArg = (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#endif

			ReadProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Old_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
			WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Stub_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
		}

		if (GetModuleCodeSectionInfo(hTermSrv, &TermSrvBase, &TermSrvSize))
		{
			// Patch functions:
			// CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
			// CDefPolicy::Query

			if (FV.Release == 6000 && FV.Build == 16386)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// Imagebase: 7FF756E0000
				// .text:000007FF75745E38          lea     rcx, [rsp+198h+VersionInformation] ; lpVersionInformation
				// .text:000007FF75745E3D          mov     ebx, 1     <- 0
				// .text:000007FF75745E42          mov     [rsp+198h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000007FF75745E4A          mov     [rdi], ebx
				// .text:000007FF75745E4C          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x65E3E);
				b = 0;
				#else
				// Imagebase: 6F320000
				// .text:6F3360B9          lea     eax, [ebp+VersionInformation]
				// .text:6F3360BF          inc     ebx            <- nop
				// .text:6F3360C0          push    eax             ; lpVersionInformation
				// .text:6F3360C1          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:6F3360CB          mov     [esi], ebx
				// .text:6F3360CD          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x160BF);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x5C88F);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx_jmp, sizeof(CDefPolicy_Query_eax_rcx_jmp), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x15CD8);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_edx_ecx, sizeof(CDefPolicy_Query_edx_ecx), &bw);
				#endif
			}
			if (FV.Release == 6001 && FV.Build == 18000)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// Imagebase: 7FF76220000
				// .text:000007FF76290DB4          lea     rcx, [rsp+198h+VersionInformation] ; lpVersionInformation
				// .text:000007FF76290DB9          mov     ebx, 1     <- 0
				// .text:000007FF76290DBE          mov     [rsp+198h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000007FF76290DC6          mov     [rdi], ebx
				// .text:000007FF76290DC8          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x70DBA);
				b = 0;
				#else
				// Imagebase: 6E800000
				// .text:6E8185DE          lea     eax, [ebp+VersionInformation]
				// .text:6E8185E4          inc     ebx            <- nop
				// .text:6E8185E5          push    eax             ; lpVersionInformation
				// .text:6E8185E6          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:6E8185F0          mov     [esi], ebx
				// .text:6E8185F2          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x185E4);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x65BD7);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx_jmp, sizeof(CDefPolicy_Query_eax_rcx_jmp), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17FD8);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_edx_ecx, sizeof(CDefPolicy_Query_edx_ecx), &bw);
				#endif
			}
			if (FV.Release == 6002 && FV.Build == 18005)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// Imagebase: 7FF766C0000
				// .text:000007FF76730FF0          lea     rcx, [rsp+198h+VersionInformation] ; lpVersionInformation
				// .text:000007FF76730FF5          mov     ebx, 1     <- 0
				// .text:000007FF76730FFA          mov     [rsp+198h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000007FF76731002          mov     [rdi], ebx
				// .text:000007FF76731004          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x70FF6);
				b = 0;
				#else
				// Imagebase: 6F580000
				// .text:6F597FA2          lea     eax, [ebp+VersionInformation]
				// .text:6F597FA8          inc     ebx            <- nop
				// .text:6F597FA9          push    eax             ; lpVersionInformation
				// .text:6F597FAA          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:6F597FB4          mov     [esi], ebx
				// .text:6F597FB6          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17FA8);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x65E83);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx_jmp, sizeof(CDefPolicy_Query_eax_rcx_jmp), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x179C0);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_edx_ecx, sizeof(CDefPolicy_Query_edx_ecx), &bw);
				#endif
			}
		}
	}
	if (Ver == 0x0601)
	{
		// Windows 7
		// uses SL Policy API (slc.dll)
		
		// load slc.dll and hook function
		hSLC = LoadLibrary(L"slc.dll");
		_SLGetWindowsInformationDWORD = (SLGETWINDOWSINFORMATIONDWORD)GetProcAddress(hSLC, "SLGetWindowsInformationDWORD");
		if (_SLGetWindowsInformationDWORD != INVALID_HANDLE_VALUE)
		{
			// rewrite original function to call our function (make hook)

			WriteToLog("Hook SLGetWindowsInformationDWORD\r\n");
			#ifdef _WIN64
			Stub_SLGetWindowsInformationDWORD.MovOp = 0x48;
			Stub_SLGetWindowsInformationDWORD.MovRegArg = 0xB8;
			Stub_SLGetWindowsInformationDWORD.MovArg =  (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.PushRaxOp = 0x50;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#else
			Stub_SLGetWindowsInformationDWORD.PushOp = 0x68;
			Stub_SLGetWindowsInformationDWORD.PushArg = (PLATFORM_DWORD)New_SLGetWindowsInformationDWORD;
			Stub_SLGetWindowsInformationDWORD.RetOp = 0xC3;
			#endif

			ReadProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Old_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
			WriteProcessMemory(GetCurrentProcess(), _SLGetWindowsInformationDWORD, &Stub_SLGetWindowsInformationDWORD, sizeof(FARJMP), &bw);
		}

		if (GetModuleCodeSectionInfo(hTermSrv, &TermSrvBase, &TermSrvSize))
		{
			// Patch functions:
			// CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
			// CDefPolicy::Query

			if (FV.Release == 7600 && FV.Build == 16385)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// Imagebase: 7FF75A80000
				// .text:000007FF75A97D90          lea     rcx, [rsp+198h+VersionInformation] ; lpVersionInformation
				// .text:000007FF75A97D95          mov     ebx, 1     <- 0
				// .text:000007FF75A97D9A          mov     [rsp+198h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000007FF75A97DA2          mov     [rdi], ebx
				// .text:000007FF75A97DA4          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17D96);
				b = 0;
				#else
				// Imagebase: 6F2E0000
				// .text:6F2F9E1F          lea     eax, [ebp+VersionInformation]
				// .text:6F2F9E25          inc     ebx            <- nop
				// .text:6F2F9E26          push    eax             ; lpVersionInformation
				// .text:6F2F9E27          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:6F2F9E31          mov     [esi], ebx
				// .text:6F2F9E33          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x19E25);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17AD2);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x196F3);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif
			}
			if (FV.Release == 7601 && FV.Build == 17514)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// Imagebase: 7FF75A80000
				// .text:000007FF75A980DC          lea     rcx, [rsp+198h+VersionInformation] ; lpVersionInformation
				// .text:000007FF75A980E1          mov     ebx, 1     <- 0
				// .text:000007FF75A980E6          mov     [rsp+198h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000007FF75A980EE          mov     [rdi], ebx
				// .text:000007FF75A980F0          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x180E2);
				b = 0;
				#else
				// Imagebase: 6F2E0000
				// .text:6F2FA497          lea     eax, [ebp+VersionInformation]
				// .text:6F2FA49D          inc     ebx            <- nop
				// .text:6F2FA49E          push    eax             ; lpVersionInformation
				// .text:6F2FA49F          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:6F2FA4A9          mov     [esi], ebx
				// .text:6F2FA4AB          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1A49D);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17D8A);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x19D53);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif
			}
			if (FV.Release == 7601 && FV.Build == 18540)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// Imagebase: 7FF75A80000
				// .text:000007FF75A98000          lea     rcx, [rsp+198h+VersionInformation] ; lpVersionInformation
				// .text:000007FF75A98005          mov     ebx, 1     <- 0
				// .text:000007FF75A9800A          mov     [rsp+198h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000007FF75A98012          mov     [rdi], ebx
				// .text:000007FF75A98014          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x18006);
				b = 0;
				#else
				// Imagebase: 6F2E0000
				// .text:6F2FA4DF          lea     eax, [ebp+VersionInformation]
				// .text:6F2FA4E5          inc     ebx            <- nop
				// .text:6F2FA4E6          push    eax             ; lpVersionInformation
				// .text:6F2FA4E7          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:6F2FA4F1          mov     [esi], ebx
				// .text:6F2FA4F3          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1A4E5);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17C82);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x19D9F);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif
			}
			if (FV.Release == 7601 && FV.Build == 22750)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// Imagebase: 7FF75A80000
				// .text:000007FF75A97E88          lea     rcx, [rsp+198h+VersionInformation] ; lpVersionInformation
				// .text:000007FF75A97E8D          mov     ebx, 1     <- 0
				// .text:000007FF75A97E92          mov     [rsp+198h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000007FF75A97E9A          mov     [rdi], ebx
				// .text:000007FF75A97E9C          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17E8E);
				b = 0;
				#else
				// Imagebase: 6F2E0000
				// .text:6F2FA64F          lea     eax, [ebp+VersionInformation]
				// .text:6F2FA655          inc     ebx            <- nop
				// .text:6F2FA656          push    eax             ; lpVersionInformation
				// .text:6F2FA657          mov     [ebp+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:6F2FA661          mov     [esi], ebx
				// .text:6F2FA663          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1A655);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17C92);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x19E21);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif
			}
		}
	}
	if (Ver == 0x0602)
	{
		// Windows 8
		// uses SL Policy internal unexported function
		
		// load slc.dll and get function
		// (will be used on intercepting undefined values)
		hSLC = LoadLibrary(L"slc.dll");
		_SLGetWindowsInformationDWORD = (SLGETWINDOWSINFORMATIONDWORD)GetProcAddress(hSLC, "SLGetWindowsInformationDWORD");

		if (GetModuleCodeSectionInfo(hTermSrv, &TermSrvBase, &TermSrvSize))
		{
			// Patch functions:
			// CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
			// CDefPolicy::Query
			// Hook function:
			// SLGetWindowsInformationDWORDWrapper

			if (FV.Release == 8102 && FV.Build == 0)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:000000018000D83A          lea     rcx, [rsp+180h+VersionInformation] ; lpVersionInformation
				// .text:000000018000D83F          mov     ebx, 1     <- 0
				// .text:000000018000D844          mov     [rsp+180h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000000018000D84C          mov     [rdi], ebx
				// .text:000000018000D84E          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xD840);
				b = 0;
				#else
				// .text:1000F7E5          lea     eax, [esp+150h+VersionInformation]
				// .text:1000F7E9          inc     esi            <- nop
				// .text:1000F7EA          push    eax             ; lpVersionInformation
				// .text:1000F7EB          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:1000F7F3          mov     [edi], esi
				// .text:1000F7F5          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xF7E9);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xD3E6);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xE47C);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif

				WriteToLog("Hook SLGetWindowsInformationDWORDWrapper\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1A484);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1B909);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 8250 && FV.Build == 0)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:0000000180011E6E          lea     rcx, [rsp+180h+VersionInformation] ; lpVersionInformation
				// .text:0000000180011E73          mov     ebx, 1     <- 0
				// .text:0000000180011E78          mov     [rsp+180h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:0000000180011E80          mov     [rdi], ebx
				// .text:0000000180011E82          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x11E74);
				b = 0;
				#else
				// .text:100159C5          lea     eax, [esp+150h+VersionInformation]
				// .text:100159C9          inc     esi            <- nop
				// .text:100159CA          push    eax             ; lpVersionInformation
				// .text:100159CB          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:100159D3          mov     [edi], esi
				// .text:100159D5          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x159C9);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1187A);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x13520);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif

				WriteToLog("Hook SLGetWindowsInformationDWORDWrapper\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x18FAC);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1A0A9);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_Win8SL_CP;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 8400 && FV.Build == 0)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:000000018002081E          lea     rcx, [rsp+180h+VersionInformation] ; lpVersionInformation
				// .text:0000000180020823          mov     ebx, 1     <- 0
				// .text:0000000180020828          mov     [rsp+180h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:0000000180020830          mov     [rdi], ebx
				// .text:0000000180020832          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x20824);
				b = 0;
				#else
				// .text:1001547E          lea     eax, [esp+150h+VersionInformation]
				// .text:10015482          inc     esi            <- nop
				// .text:10015483          push    eax             ; lpVersionInformation
				// .text:10015484          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:1001548C          mov     [edi], esi
				// .text:1001548E          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x15482);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1F102);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x13E48);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif

				WriteToLog("Hook SLGetWindowsInformationDWORDWrapper\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x2492C);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x19629);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 9200 && FV.Build == 16384)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:000000018002BAA2          lea     rcx, [rsp+180h+VersionInformation] ; lpVersionInformation
				// .text:000000018002BAA7          mov     ebx, 1     <- 0
				// .text:000000018002BAAC          mov     [rsp+180h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000000018002BAB4          mov     [rdi], ebx
				// .text:000000018002BAB6          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x2BAA8);
				b = 0;
				#else
				// .text:1001554E          lea     eax, [esp+150h+VersionInformation]
				// .text:10015552          inc     esi            <- nop
				// .text:10015553          push    eax             ; lpVersionInformation
				// .text:10015554          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:1001555C          mov     [edi], esi
				// .text:1001555E          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x15552);
				b = 0x90;
				#endif
				/* __ARM_ARCH_7
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x?); // unknown
				*/
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x2A31A);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x13F08);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif
				/* __ARM_ARCH_7
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x?); // unknown
				*/

				WriteToLog("Hook SLGetWindowsInformationDWORDWrapper\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x21FA8);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x19559);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.RetOp = 0xC3;
				#endif
				/* __ARM_ARCH_7
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x5F934);
				// hook opcodes?
				Don't know how to make far jump on ARM platform
				*/
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 9200 && FV.Build == 17048)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:0000000180020942          lea     rcx, [rsp+180h+VersionInformation] ; lpVersionInformation
				// .text:0000000180020947          mov     ebx, 1     <- 0
				// .text:000000018002094C          mov     [rsp+180h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:0000000180020954          mov     [rdi], ebx
				// .text:0000000180020956          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x20948);
				b = 0;
				#else
				// .text:1002058E          lea     eax, [esp+150h+VersionInformation]
				// .text:10020592          inc     esi            <- nop
				// .text:10020593          push    eax             ; lpVersionInformation
				// .text:10020594          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:1002059C          mov     [edi], esi
				// .text:1002059E          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x20592);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1F206);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1F408);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif

				WriteToLog("Hook SLGetWindowsInformationDWORDWrapper\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x24570);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x17059);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 9200 && FV.Build == 21166)
			{
				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:000000018002BAF2          lea     rcx, [rsp+180h+VersionInformation] ; lpVersionInformation
				// .text:000000018002BAF7          mov     ebx, 1     <- 0
				// .text:000000018002BAFC          mov     [rsp+180h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000000018002BB04          mov     [rdi], ebx
				// .text:000000018002BB06          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x2BAF8);
				b = 0;
				#else
				// .text:10015576          lea     eax, [esp+150h+VersionInformation]
				// .text:1001557A          inc     esi            <- nop
				// .text:1001557B          push    eax             ; lpVersionInformation
				// .text:1001557C          mov     [esp+154h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:10015584          mov     [edi], esi
				// .text:10015586          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1557A);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x2A3B6);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rdi, sizeof(CDefPolicy_Query_eax_rdi), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x13F30);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_esi, sizeof(CDefPolicy_Query_eax_esi), &bw);
				#endif

				WriteToLog("Hook SLGetWindowsInformationDWORDWrapper\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x21FD0);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x19581);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_Win8SL;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
		}
	}
	if (Ver == 0x0603)
	{
		// Windows 8.1
		// uses SL Policy internal inline code

		if (GetModuleCodeSectionInfo(hTermSrv, &TermSrvBase, &TermSrvSize))
		{
			// Patch functions:
			// CEnforcementCore::GetInstanceOfTSLicense
			// CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
			// CDefPolicy::Query
			// Hook function:
			// CSLQuery::Initialize

			if (FV.Release == 9431 && FV.Build == 0)
			{
				WriteToLog("Patch CEnforcementCore::GetInstanceOfTSLicense\r\n");
				#ifdef _WIN64
				// .text:000000018009F713          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SAJAEAU_GUID@@PEAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
				// .text:000000018009F718          test    eax, eax
				// .text:000000018009F71A          js      short loc_18009F73B
				// .text:000000018009F71C          cmp     [rsp+48h+arg_18], 0
				// .text:000000018009F721          jz      short loc_18009F73B <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x9F721);
				#else
				// .text:1008A604          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
				// .text:1008A609          test    eax, eax
				// .text:1008A60B          js      short loc_1008A628
				// .text:1008A60D          cmp     [ebp+var_8], 0
				// .text:1008A611          jz      short loc_1008A628 <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x8A611);
				#endif
				b = 0xEB;
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:00000001800367F3          lea     rcx, [rsp+190h+VersionInformation] ; lpVersionInformation
				// .text:00000001800367F8          mov     ebx, 1     <- 0
				// .text:00000001800367FD          mov     [rsp+190h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:0000000180036805          mov     [rdi], ebx
				// .text:0000000180036807          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x367F9);
				b = 0;
				#else
				// .text:100306A4          lea     eax, [esp+150h+VersionInformation]
				// .text:100306A8          inc     ebx            <- nop
				// .text:100306A9          mov     [edi], ebx
				// .text:100306AB          push    eax             ; lpVersionInformation
				// .text:100306AC          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x306A8);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x350FD);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx, sizeof(CDefPolicy_Query_eax_rcx), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x2EA25);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_ecx, sizeof(CDefPolicy_Query_eax_ecx), &bw);
				#endif

				WriteToLog("Hook CSLQuery::Initialize\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x2F9C0);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x196B0);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 9600 && FV.Build == 16384)
			{
				WriteToLog("Patch CEnforcementCore::GetInstanceOfTSLicense\r\n");
				#ifdef _WIN64
				// .text:000000018008181F                 cmp     [rsp+48h+arg_18], 0
				// .text:0000000180081824                 jz      loc_180031DEF <- nop + jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x81824);
				b = 0x90;
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x81825);
				b = 0xE9;
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);
				#else
				// .text:100A271C          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
				// .text:100A2721          test    eax, eax
				// .text:100A2723          js      short loc_100A2740
				// .text:100A2725          cmp     [ebp+var_8], 0
				// .text:100A2729          jz      short loc_100A2740 <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xA2729);
				b = 0xEB;
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);
				#endif

				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:000000018002023B          lea     rcx, [rsp+190h+VersionInformation] ; lpVersionInformation
				// .text:0000000180020240          mov     ebx, 1     <- 0
				// .text:0000000180020245          mov     [rsp+190h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:000000018002024D          mov     [rdi], ebx
				// .text:000000018002024F          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x20241);
				b = 0;
				#else
				// .text:10018024          lea     eax, [esp+150h+VersionInformation]
				// .text:10018028          inc     ebx            <- nop
				// .text:10018029          mov     [edi], ebx
				// .text:1001802B          push    eax             ; lpVersionInformation
				// .text:1001802C          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x18028);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x57829);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx, sizeof(CDefPolicy_Query_eax_rcx), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x16115);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_ecx, sizeof(CDefPolicy_Query_eax_ecx), &bw);
				#endif

				WriteToLog("Hook CSLQuery::Initialize\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x554C0);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1CEB0);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 9600 && FV.Build == 17095)
			{
				WriteToLog("Patch CEnforcementCore::GetInstanceOfTSLicense\r\n");
				#ifdef _WIN64
				// .text:00000001800B914B          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SAJAEAU_GUID@@PEAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
				// .text:00000001800B9150          test    eax, eax
				// .text:00000001800B9152          js      short loc_1800B9173
				// .text:00000001800B9154          cmp     [rsp+48h+arg_18], 0
				// .text:00000001800B9159          jz      short loc_1800B9173 <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xB9159);
				#else
				// .text:100A36C4          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
				// .text:100A36C9          test    eax, eax
				// .text:100A36CB          js      short loc_100A36E8
				// .text:100A36CD          cmp     [ebp+var_8], 0
				// .text:100A36D1          jz      short loc_100A36E8 <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xA36D1);
				#endif
				b = 0xEB;
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:0000000180021823          lea     rcx, [rsp+190h+VersionInformation] ; lpVersionInformation
				// .text:0000000180021828          mov     ebx, 1     <- 0
				// .text:000000018002182D          mov     [rsp+190h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:0000000180021835          mov     [rdi], ebx
				// .text:0000000180021837          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x21829);
				b = 0;
				#else
				// .text:10036BA5          lea     eax, [esp+150h+VersionInformation]
				// .text:10036BA9          inc     ebx            <- nop
				// .text:10036BAA          mov     [edi], ebx
				// .text:10036BAC          push    eax             ; lpVersionInformation
				// .text:10036BAD          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x36BA9);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1F6A1);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx, sizeof(CDefPolicy_Query_eax_rcx), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x16115);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_ecx, sizeof(CDefPolicy_Query_eax_ecx), &bw);
				#endif

				WriteToLog("Hook CSLQuery::Initialize\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x3B110);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x117F1);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
		}
	}
	if (Ver == 0x0604)
	{
		// Windows 10
		// uses SL Policy internal inline code

		if (GetModuleCodeSectionInfo(hTermSrv, &TermSrvBase, &TermSrvSize))
		{
			// Patch functions:
			// CEnforcementCore::GetInstanceOfTSLicense
			// CSessionArbitrationHelper::IsSingleSessionPerUserEnabled
			// CDefPolicy::Query
			// Hook function:
			// CSLQuery::Initialize

			if (FV.Release == 9841 && FV.Build == 0)
			{
				WriteToLog("Patch CEnforcementCore::GetInstanceOfTSLicense\r\n");
				#ifdef _WIN64
				// .text:0000000180081133          call    sub_1800A9048
				// .text:0000000180081138          test    eax, eax
				// .text:000000018008113A          js      short loc_18008115B
				// .text:000000018008113C          cmp     [rsp+58h+arg_18], 0
				// .text:0000000180081141          jz      short loc_18008115B <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x81141);
				#else
				// .text:1009569B          call    sub_100B7EE5
				// .text:100956A0          test    eax, eax
				// .text:100956A2          js      short loc_100956BF
				// .text:100956A4          cmp     [ebp+var_C], 0
				// .text:100956A8          jz      short loc_100956BF <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x956A8);
				#endif
				b = 0xEB;
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:0000000180012153          lea     rcx, [rsp+190h+VersionInformation] ; lpVersionInformation
				// .text:0000000180012158          mov     ebx, 1     <- 0
				// .text:000000018001215D          mov     [rsp+190h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:0000000180012165          mov     [rdi], ebx
				// .text:0000000180012167          call    cs:GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x12159);
				b = 0;
				#else
				// .text:10030121          lea     eax, [esp+150h+VersionInformation]
				// .text:10030125          inc     ebx            <- nop
				// .text:10030126          mov     [edi], ebx
				// .text:10030128          push    eax             ; lpVersionInformation
				// .text:10030129          call    ds:GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x30125);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xC125);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx, sizeof(CDefPolicy_Query_eax_rcx), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x3B989);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_ecx, sizeof(CDefPolicy_Query_eax_ecx), &bw);
				#endif

				WriteToLog("Hook CSLQuery::Initialize\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1EA50);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x46A68);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
			if (FV.Release == 9860 && FV.Build == 0)
			{
				WriteToLog("Patch CEnforcementCore::GetInstanceOfTSLicense\r\n");
				#ifdef _WIN64
				// .text:0000000180081083          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SAJAEAU_GUID@@PEAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
				// .text:0000000180081088          test    eax, eax
				// .text:000000018008108A          js      short loc_1800810AB
				// .text:000000018008108C          cmp     [rsp+58h+arg_18], 0
				// .text:0000000180081091          jz      short loc_1800810AB <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x81091);
				#else
				// .text:100962BB          call    ?IsLicenseTypeLocalOnly@CSLQuery@@SGJAAU_GUID@@PAH@Z ; CSLQuery::IsLicenseTypeLocalOnly(_GUID &,int *)
				// .text:100962C0          test    eax, eax
				// .text:100962C2          js      short loc_100962DF
				// .text:100962C4          cmp     [ebp+var_C], 0
				// .text:100962C8          jz      short loc_100962DF <- jmp
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x962C8);
				#endif
				b = 0xEB;
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CSessionArbitrationHelper::IsSingleSessionPerUserEnabled\r\n");
				#ifdef _WIN64
				// .text:0000000180011AA3          lea     rcx, [rsp+190h+VersionInformation] ; lpVersionInformation
				// .text:0000000180011AA8          mov     ebx, 1     <- 0
				// .text:0000000180011AAD          mov     [rsp+190h+VersionInformation.dwOSVersionInfoSize], 11Ch
				// .text:0000000180011AB5          mov     [rdi], ebx
				// .text:0000000180011AB7          call    cs:__imp_GetVersionExW
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x11AA9);
				b = 0;
				#else
				// .text:10030841          lea     eax, [esp+150h+VersionInformation]
				// .text:10030845          inc     ebx            <- nop
				// .text:10030846          mov     [edi], ebx
				// .text:10030848          push    eax             ; lpVersionInformation
				// .text:10030849          call    ds:__imp__GetVersionExW@4 ; GetVersionExW(x)
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x30845);
				b = 0x90;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &b, sizeof(b), &bw);

				WriteToLog("Patch CDefPolicy::Query\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0xB9F5);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_rcx, sizeof(CDefPolicy_Query_eax_rcx), &bw);
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x3BEC9);
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &CDefPolicy_Query_eax_ecx, sizeof(CDefPolicy_Query_eax_ecx), &bw);
				#endif

				WriteToLog("Hook CSLQuery::Initialize\r\n");
				#ifdef _WIN64
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x1EB00);
				Jump.MovOp = 0x48;
				Jump.MovRegArg = 0xB8;
				Jump.MovArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.PushRaxOp = 0x50;
				Jump.RetOp = 0xC3;
				#else
				SignPtr = (PLATFORM_DWORD)(TermSrvBase + 0x46F18);
				Jump.PushOp = 0x68;
				Jump.PushArg = (PLATFORM_DWORD)New_CSLQuery_Initialize;
				Jump.RetOp = 0xC3;
				#endif
				WriteProcessMemory(GetCurrentProcess(), (LPVOID)SignPtr, &Jump, sizeof(FARJMP), &bw);
			}
		}
	}
	WriteToLog("resume\r\n");
	SetThreadsState(true);
	return;
}

void WINAPI ServiceMain(DWORD dwArgc, LPTSTR *lpszArgv)
{
	WriteToLog("> ServiceMain\r\n");
	if (!AlreadyHooked) Hook();

	if (_ServiceMain != NULL) _ServiceMain(dwArgc, lpszArgv);
}

void WINAPI SvchostPushServiceGlobals(void *lpGlobalData)
{
	WriteToLog("> SvchostPushServiceGlobals\r\n");
	if (!AlreadyHooked) Hook();

	if (_SvchostPushServiceGlobals != NULL) _SvchostPushServiceGlobals(lpGlobalData); 
}