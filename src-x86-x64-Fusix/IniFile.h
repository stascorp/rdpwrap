/*
  Copyright 2014 Stas'M Corp.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

#include "stdafx.h"
#include <Windows.h>

// Out values struсts
typedef struct _INI_VAR_STRING
{
	char Name[128];
	char Value[128];
} INI_VAR_STRING, PINI_VAR_STRING;

typedef struct _INI_VAR_DWORD
{
	char Name[128];
#ifndef _WIN64
	DWORD ValueDec;
	DWORD ValueHex;
#else
	DWORD64 ValueDec;
	DWORD64 ValueHex;
#endif

} INI_VAR_DWORD, PINI_VAR_DWORD;

typedef struct _INI_VAR_BOOL
{
	char Name[128];
	bool Value;
} INI_VAR_BOOL, PINI_VAR_BOOL;

typedef struct _INI_VAR_BYTEARRAY
{
	char Name[128];
	byte ArraySize;
	char Value[255];
} INI_VAR_BYTEARRAY, PINI_VAR_BYTEARRAY;

// end

typedef struct _INI_SECTION_VARIABLE
{
	char VariableName[128];
	char VariableValue[128];
} INI_SECTION_VARIABLE, PINI_SECTION_VARIABLE;


typedef struct _INI_SECTION
{
	char SectionName[128];
	DWORD VariablesCount;
	[length_is(SectionCount)]	INI_SECTION_VARIABLE *Variables;

} INI_SECTION, PINI_SECTION;

typedef struct _INI_DATA
{
	DWORD SectionCount;
	[length_is(SectionCount)] INI_SECTION *Section;
} INI_DATA, *PINI_DATA;

class INI_FILE
{
public:
	INI_FILE(wchar_t*);
	~INI_FILE();

	bool SectionExists(char *SectionName);
	bool GetVariableInSection(char *SectionName, char *VariableName, INI_VAR_STRING *Variable);
	bool GetVariableInSection(char *SectionName, char *VariableName, INI_VAR_DWORD *Variable);
	bool GetVariableInSection(char *SectionName, char *VariableName, INI_VAR_BOOL *Variable);
	bool GetVariableInSection(char *SectionName, char *VariableName, INI_VAR_BYTEARRAY *Variable);

private:
	DWORD FileSize;	// Ini file size
	char *FileRaw;	// Ini file raw dump
	DWORD FileStringsCount;	//	String-map length
	DWORD *FileStringsMap;	// String-map
	INI_DATA IniData;	// Parsed data

	// Common service functions
	int StrTrim(char* Str);

	// Class service functions
	bool CreateStringsMap(); // Create file string-map
	bool Parse();	// Parse file to class structures
	DWORD GetFileStringFromNum(DWORD StringNumber, char *RetString, DWORD Size);	// Get string from string-map
	bool IsVariable(char *Str, DWORD StrSize);
	bool FillVariable(INI_SECTION_VARIABLE *Variable, char *Str, DWORD StrSize);	// Fill INI_SECTION_VARIABLE struct (for Parse)
	bool GetVariableInSectionPrivate(char *SectionName, char *VariableName, INI_SECTION_VARIABLE *RetVariable);
};

