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
#include <stdlib.h>
#include "IniFile.h"

INI_FILE::INI_FILE(wchar_t *FilePath)
{
	DWORD Status = 0;
	DWORD NumberOfBytesRead = 0;

	HANDLE hFile = CreateFile(FilePath, GENERIC_READ, FILE_SHARE_WRITE|FILE_SHARE_READ,
		NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

	if (hFile == INVALID_HANDLE_VALUE)
	{
		return;
	}

	FileSize = GetFileSize(hFile, NULL);
	if (FileSize == INVALID_FILE_SIZE)
	{
		return;
	}

	FileRaw = new char[FileSize];
	Status = ReadFile(hFile, FileRaw, FileSize, &NumberOfBytesRead, NULL);
	if (!Status)
	{
		return;
	}

	CreateStringsMap();
	Parse();
}


INI_FILE::~INI_FILE()
{
	for (DWORD i = 0; i < IniData.SectionCount; i++)
	{
		delete[] IniData.Section[i].Variables;
	}
	delete[] IniData.Section;
	delete[] FileStringsMap;
	delete FileRaw;
}

bool INI_FILE::CreateStringsMap()
{
	DWORD StringsCount = 1;

	for (DWORD i = 0; i < FileSize; i++)
	{
		if (FileRaw[i] == '\r' && FileRaw[i + 1] == '\n') StringsCount++;
	}

	FileStringsCount = StringsCount;

	FileStringsMap = new DWORD[StringsCount];
	FileStringsMap[0] = 0;

	StringsCount = 1;

	for (DWORD i = 0; i < FileSize; i++)
	{
		if (FileRaw[i] == '\r' && FileRaw[i + 1] == '\n')
		{
			FileStringsMap[StringsCount] = i + 2;
			StringsCount++;
		}
	}

	return true;
}

int INI_FILE::StrTrim(char* Str)
{
	int i = 0, j;
	while ((Str[i] == ' ') || (Str[i] == '\t'))
	{
		i++;
	}
	if (i>0)
	{
		for (j = 0; j < strlen(Str); j++)
		{
			Str[j] = Str[j + i];
		}
		Str[j] = '\0';
	}

	i = strlen(Str) - 1;
	while ((Str[i] == ' ') || (Str[i] == '\t'))
	{
		i--;
	}
	if (i < (strlen(Str) - 1))
	{
		Str[i + 1] = '\0';
	}
	return 0;
}

DWORD INI_FILE::GetFileStringFromNum(DWORD StringNumber, char *RetString, DWORD Size)
{
	DWORD CurrentStringNum = 0;
	DWORD EndStringPos = 0;
	DWORD StringSize = 0;

	if (StringNumber > FileStringsCount) return 0;

	for (DWORD i = FileStringsMap[StringNumber]; i < FileSize; i++)
	{
		if (i == (FileSize - 1))
		{
			EndStringPos = FileSize;
			break;
		}
		if (FileRaw[i] == '\r' && FileRaw[i + 1] == '\n')
		{
			EndStringPos = i;
			break;
		}
	}

	StringSize = EndStringPos - FileStringsMap[StringNumber];

	if (Size < StringSize) return 0;

	memset(RetString, 0x00, Size);
	memcpy(RetString, &(FileRaw[FileStringsMap[StringNumber]]), StringSize);
	return StringSize;
}

bool INI_FILE::IsVariable(char *Str, DWORD StrSize)
{
	bool Quotes = false;

	for (DWORD i = 0; i < StrSize; i++)
	{
		if (Str[i] == '"' || Str[i] == '\'') Quotes = !Quotes;
		if (Str[i] == '=' && !Quotes) return true;
	}
	return false;
}

bool INI_FILE::FillVariable(INI_SECTION_VARIABLE *Variable, char *Str, DWORD StrSize)
{
	bool Quotes = false;

	for (DWORD i = 0; i < StrSize; i++)
	{
		if (Str[i] == '"' || Str[i] == '\'') Quotes = !Quotes;
		if (Str[i] == '=' && !Quotes)
		{
			memset(Variable->VariableName, 0, MAX_STRING_LEN);
			memset(Variable->VariableValue, 0, MAX_STRING_LEN);
			memcpy(Variable->VariableName, Str, i);
			memcpy(Variable->VariableValue, &(Str[i + 1]), StrSize - (i - 1));
			StrTrim(Variable->VariableName);
			StrTrim(Variable->VariableValue);
			break;
		}
	}
	return true;
}

bool INI_FILE::Parse()
{
	DWORD CurrentStringNum = 0;
	char CurrentString[512];
	DWORD CurrentStringSize = 0;

	DWORD SectionsCount = 0;
	DWORD VariablesCount = 0;

	DWORD CurrentSectionNum = -1;
	DWORD CurrentVariableNum = -1;

	// Calculate sections count
	for (DWORD CurrentStringNum = 0; CurrentStringNum < FileStringsCount; CurrentStringNum++)
	{
		CurrentStringSize = GetFileStringFromNum(CurrentStringNum, CurrentString, 512);

		if (CurrentString[0] == ';') continue; // It's a comment

		if (CurrentString[0] == '[' && CurrentString[CurrentStringSize - 1] == ']')	// It's section declaration
		{
			SectionsCount++;
			continue;
		}
	}

	DWORD *SectionVariableCount = new DWORD[SectionsCount];
	memset(SectionVariableCount, 0x00, sizeof(DWORD)*SectionsCount);

	for (DWORD CurrentStringNum = 0; CurrentStringNum < FileStringsCount; CurrentStringNum++)
	{
		CurrentStringSize = GetFileStringFromNum(CurrentStringNum, CurrentString, 512);

		if (CurrentString[0] == ';') continue; // It's a comment


		if (CurrentString[0] == '[' && CurrentString[CurrentStringSize - 1] == ']')	// It's section declaration
		{
			CurrentSectionNum++;
			continue;
		}
		if (IsVariable(CurrentString, CurrentStringSize))
		{
			VariablesCount++;
			SectionVariableCount[CurrentSectionNum]++;
			continue;
		}
	}

	IniData.SectionCount = SectionsCount;
	IniData.Section = new INI_SECTION[SectionsCount];
	memset(IniData.Section, 0x00, sizeof(PINI_SECTION)*SectionsCount);

	for (DWORD i = 0; i < SectionsCount; i++)
	{
		IniData.Section[i].VariablesCount = SectionVariableCount[i];
		IniData.Section[i].Variables = new INI_SECTION_VARIABLE[SectionVariableCount[i]];
		memset(IniData.Section[i].Variables, 0x00, sizeof(INI_SECTION_VARIABLE)*SectionVariableCount[i]);
	}

	delete[] SectionVariableCount;

	CurrentSectionNum = -1;
	CurrentVariableNum = -1;

	for (DWORD CurrentStringNum = 0; CurrentStringNum < FileStringsCount; CurrentStringNum++)
	{
		CurrentStringSize = GetFileStringFromNum(CurrentStringNum, CurrentString, 512);

		if (CurrentString[0] == ';') // It's a comment
		{
			continue;
		}

		if (CurrentString[0] == '[' && CurrentString[CurrentStringSize - 1] == ']')
		{
			CurrentSectionNum++;
			CurrentVariableNum = 0;
			memset(IniData.Section[CurrentSectionNum].SectionName, 0, MAX_STRING_LEN);
			memcpy(IniData.Section[CurrentSectionNum].SectionName, &(CurrentString[1]), (CurrentStringSize - 2));
			continue;
		}

		if (IsVariable(CurrentString, CurrentStringSize))
		{
			FillVariable(&(IniData.Section[CurrentSectionNum].Variables[CurrentVariableNum]), CurrentString, CurrentStringSize);
			CurrentVariableNum++;
			continue;
		}
	}

	return true;
}

PINI_SECTION INI_FILE::GetSection(char *SectionName)
{
	for (DWORD i = 0; i < IniData.SectionCount; i++)
	{
		if (
			(strlen(IniData.Section[i].SectionName) == strlen(SectionName)) &&
			(memcmp(IniData.Section[i].SectionName, SectionName, strlen(SectionName)) == 0)
		)
		{
			return &IniData.Section[i];
		}
	}
	return NULL;
}

bool INI_FILE::SectionExists(char *SectionName)
{
	if (GetSection(SectionName) == NULL)	return false;
	return true;
}

bool INI_FILE::VariableExists(char *SectionName, char *VariableName)
{
	INI_SECTION_VARIABLE Variable = { 0 };
	return GetVariableInSectionPrivate(SectionName, VariableName, &Variable);
}

bool INI_FILE::GetVariableInSectionPrivate(char *SectionName, char *VariableName, INI_SECTION_VARIABLE *RetVariable)
{
	INI_SECTION *Section = NULL;
	INI_SECTION_VARIABLE *Variable = NULL;

	// Find section
	Section = GetSection(SectionName);
	if (Section == NULL)
	{
		SetLastError(318); // This region is not found
		return false;
	}

	// Find variable
	for (DWORD i = 0; i < Section->VariablesCount; i++)
	{
		if (
			(strlen(Section->Variables[i].VariableName) == strlen(VariableName)) &&
			(memcmp(Section->Variables[i].VariableName, VariableName, strlen(VariableName)) == 0)
		)
		{
			Variable = &(Section->Variables[i]);
			break;
		}
	}
	if (Variable == NULL)
	{
		SetLastError(1898); // Member of the group is not found
		return false;
	}

	memset(RetVariable, 0x00, sizeof(*RetVariable));
	memcpy(RetVariable, Variable, sizeof(*Variable));

	return true;
}

bool INI_FILE::GetVariableInSection(char *SectionName, char *VariableName, INI_VAR_STRING *RetVariable)
{
	bool Status = false;
	INI_SECTION_VARIABLE Variable = {};

	Status = GetVariableInSectionPrivate(SectionName, VariableName, &Variable);
	if (!Status)	return Status;

	memset(RetVariable, 0x00, sizeof(*RetVariable));
	memcpy(RetVariable->Name, Variable.VariableName, strlen(Variable.VariableName));
	memcpy(RetVariable->Value, Variable.VariableValue, strlen(Variable.VariableValue));

	return true;
}

bool INI_FILE::GetVariableInSection(char *SectionName, char *VariableName, INI_VAR_DWORD *RetVariable)
{
	bool Status = false;
	INI_SECTION_VARIABLE Variable = {};

	Status = GetVariableInSectionPrivate(SectionName, VariableName, &Variable);
	if (!Status)	return Status;

	memset(RetVariable, 0x00, sizeof(*RetVariable));
	memcpy(RetVariable->Name, Variable.VariableName, strlen(Variable.VariableName));

#ifndef _WIN64
	RetVariable->ValueDec = strtol(Variable.VariableValue, NULL, 10);
	RetVariable->ValueHex = strtol(Variable.VariableValue, NULL, 16);
#else
	RetVariable->ValueDec = _strtoi64(Variable.VariableValue, NULL, 10);
	RetVariable->ValueHex = _strtoi64(Variable.VariableValue, NULL, 16);
#endif
	return true;
}

bool INI_FILE::GetVariableInSection(char *SectionName, char *VariableName, INI_VAR_BYTEARRAY *RetVariable)
{
	bool Status = false;
	INI_SECTION_VARIABLE Variable = {};

	Status = GetVariableInSectionPrivate(SectionName, VariableName, &Variable);
	if (!Status)	return Status;

	DWORD ValueLen = strlen(Variable.VariableValue);
	if ((ValueLen % 2) != 0) return false;

	// for security reasons not more than 16 bytes
	if (ValueLen > 32) ValueLen = 32;  // 32 hex digits

	memset(RetVariable, 0x00, sizeof(*RetVariable));
	memcpy(RetVariable->Name, Variable.VariableName, strlen(Variable.VariableName));

	for (DWORD i = 0; i <= ValueLen; i++)
	{
		if ((i % 2) != 0) continue;

		switch (Variable.VariableValue[i])
		{
		case '0': break;
		case '1': RetVariable->Value[(i / 2)] += (1 << 4); break;
		case '2': RetVariable->Value[(i / 2)] += (2 << 4); break;
		case '3': RetVariable->Value[(i / 2)] += (3 << 4); break;
		case '4': RetVariable->Value[(i / 2)] += (4 << 4); break;
		case '5': RetVariable->Value[(i / 2)] += (5 << 4); break;
		case '6': RetVariable->Value[(i / 2)] += (6 << 4); break;
		case '7': RetVariable->Value[(i / 2)] += (7 << 4); break;
		case '8': RetVariable->Value[(i / 2)] += (8 << 4); break;
		case '9': RetVariable->Value[(i / 2)] += (9 << 4); break;
		case 'A': RetVariable->Value[(i / 2)] += (10 << 4); break;
		case 'B': RetVariable->Value[(i / 2)] += (11 << 4); break;
		case 'C': RetVariable->Value[(i / 2)] += (12 << 4); break;
		case 'D': RetVariable->Value[(i / 2)] += (13 << 4); break;
		case 'E': RetVariable->Value[(i / 2)] += (14 << 4); break;
		case 'F': RetVariable->Value[(i / 2)] += (15 << 4); break;
		}

		switch (Variable.VariableValue[i + 1])
		{
		case '0': break;
		case '1': RetVariable->Value[(i / 2)] += 1; break;
		case '2': RetVariable->Value[(i / 2)] += 2; break;
		case '3': RetVariable->Value[(i / 2)] += 3; break;
		case '4': RetVariable->Value[(i / 2)] += 4; break;
		case '5': RetVariable->Value[(i / 2)] += 5; break;
		case '6': RetVariable->Value[(i / 2)] += 6; break;
		case '7': RetVariable->Value[(i / 2)] += 7; break;
		case '8': RetVariable->Value[(i / 2)] += 8; break;
		case '9': RetVariable->Value[(i / 2)] += 9; break;
		case 'A': RetVariable->Value[(i / 2)] += 10; break;
		case 'B': RetVariable->Value[(i / 2)] += 11; break;
		case 'C': RetVariable->Value[(i / 2)] += 12; break;
		case 'D': RetVariable->Value[(i / 2)] += 13; break;
		case 'E': RetVariable->Value[(i / 2)] += 14; break;
		case 'F': RetVariable->Value[(i / 2)] += 15; break;
		}
	}
	RetVariable->ArraySize = ValueLen / 2;
	return true;
}

bool INI_FILE::GetVariableInSection(char *SectionName, char *VariableName, bool *RetVariable)
{
	bool Status = false;
	INI_SECTION_VARIABLE Variable = {};

	Status = GetVariableInSectionPrivate(SectionName, VariableName, &Variable);
	if (!Status)	return Status;

	*RetVariable = (bool)strtol(Variable.VariableValue, NULL, 10);
	return true;
}

bool INI_FILE::GetSectionVariablesList(char *SectionName, INI_SECTION_VARLIST *VariablesList)
{
	INI_SECTION *Section = NULL;

	Section = GetSection(SectionName);
	if (Section == NULL)
	{
		SetLastError(318); // This region is not found
		return false;
	}

	VariablesList->EntriesCount = Section->VariablesCount;

	VariablesList->NamesEntries = new INI_SECTION_VARLIST_ENTRY[VariablesList->EntriesCount];
	memset(VariablesList->NamesEntries, 0x00, sizeof(INI_SECTION_VARLIST_ENTRY)*VariablesList->EntriesCount);

	VariablesList->ValuesEntries = new INI_SECTION_VARLIST_ENTRY[VariablesList->EntriesCount];
	memset(VariablesList->ValuesEntries, 0x00, sizeof(INI_SECTION_VARLIST_ENTRY)*VariablesList->EntriesCount);

	for (DWORD i = 0; i < Section->VariablesCount; i++)
	{
		memcpy(VariablesList->NamesEntries[i].String, Section->Variables[i].VariableName,
			strlen(Section->Variables[i].VariableName));

		memcpy(VariablesList->ValuesEntries[i].String, Section->Variables[i].VariableValue,
			strlen(Section->Variables[i].VariableValue));
	}

	return true;
}


// ---------------------------- WCHAR_T BLOCK ----------------------------------------------

bool INI_FILE::SectionExists(wchar_t *SectionName)
{
	char cSectionName[MAX_STRING_LEN] = { 0x00 };

	wcstombs(cSectionName, SectionName, MAX_STRING_LEN);

	return GetSection(cSectionName);
}

bool INI_FILE::VariableExists(wchar_t *SectionName, wchar_t *VariableName)
{
	INI_SECTION_VARIABLE Variable = { 0 };

	char cSectionName[MAX_STRING_LEN] = { 0x00 };
	char cVariableName[MAX_STRING_LEN] = { 0x00 };

	wcstombs(cSectionName, SectionName, MAX_STRING_LEN);
	wcstombs(cVariableName, VariableName, MAX_STRING_LEN);

	return GetVariableInSectionPrivate(cSectionName, cVariableName, &Variable);
}

bool INI_FILE::GetVariableInSection(wchar_t *SectionName, wchar_t *VariableName, INI_VAR_STRING *RetVariable)
{
	char cSectionName[MAX_STRING_LEN] = { 0x00 };
	char cVariableName[MAX_STRING_LEN] = { 0x00 };

	wcstombs(cSectionName, SectionName, MAX_STRING_LEN);
	wcstombs(cVariableName, VariableName, MAX_STRING_LEN);

	return GetVariableInSection(cSectionName, cVariableName, RetVariable);
}

bool INI_FILE::GetVariableInSection(wchar_t *SectionName, wchar_t *VariableName, INI_VAR_DWORD *RetVariable)
{
	char cSectionName[MAX_STRING_LEN] = { 0x00 };
	char cVariableName[MAX_STRING_LEN] = { 0x00 };

	wcstombs(cSectionName, SectionName, MAX_STRING_LEN);
	wcstombs(cVariableName, VariableName, MAX_STRING_LEN);

	return GetVariableInSection(cSectionName, cVariableName, RetVariable);
}

bool INI_FILE::GetVariableInSection(wchar_t *SectionName, wchar_t *VariableName, INI_VAR_BYTEARRAY *RetVariable)
{
	char cSectionName[MAX_STRING_LEN] = { 0x00 };
	char cVariableName[MAX_STRING_LEN] = { 0x00 };

	wcstombs(cSectionName, SectionName, MAX_STRING_LEN);
	wcstombs(cVariableName, VariableName, MAX_STRING_LEN);

	return GetVariableInSection(cSectionName, cVariableName, RetVariable);
}

bool INI_FILE::GetVariableInSection(wchar_t *SectionName, wchar_t *VariableName, bool *RetVariable)
{
	char cSectionName[MAX_STRING_LEN] = { 0x00 };
	char cVariableName[MAX_STRING_LEN] = { 0x00 };

	wcstombs(cSectionName, SectionName, MAX_STRING_LEN);
	wcstombs(cVariableName, VariableName, MAX_STRING_LEN);

	return GetVariableInSection(cSectionName, cVariableName, RetVariable);
}

bool INI_FILE::GetSectionVariablesList(wchar_t *SectionName, INI_SECTION_VARLIST *VariablesList)
{
	char cSectionName[MAX_STRING_LEN] = { 0x00 };

	wcstombs(cSectionName, SectionName, MAX_STRING_LEN);

	return GetSectionVariablesList(cSectionName, VariablesList);
}