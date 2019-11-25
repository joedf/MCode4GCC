#NoEnv
#NoTrayIcon
#SingleInstance, Off
SetBatchLines,-1
SetKeyDelay, -1, 0
SetWorkingDir %A_ScriptDir%

MCode4GCC_settings =
(
[settings]
Compilerpath=gcc
StripDebugInfo=1
Optimize=3
MCodeStyle=Bentschi
)
/*
[INICONFIGDefaultEND]
*/
if !FileExist(settings_File:="MCode4GCC.ini")
	FileAppend,%MCode4GCC_settings%,%settings_File%

;=====================[ GLOBAL VARS ]=======================
EnvGet, @PATH_VAR, Path
@REVISION_DATE := "10:37 2019/11/25"
;===========================================================

Menu, FileMenu, Add, &Generate MCode, Generate
Menu, FileMenu, Add
Menu, FileMenu, Add, E&xit`tAlt+F4, GuiClose
Menu, MRefMenu, Add, Bentschi Style, SetMCodeStyle
Menu, MRefMenu, Add, Laszlo Style, SetMCodeStyle
Menu, HelpMenu, Add, Help`tF1, Help
Menu, HelpMenu, Add, MCode &Help (Forum Thread), MCodeHelp
Menu, HelpMenu, Add
Menu, HelpMenu, Add, &About, About
Menu, MenuBar, Add, &File, :FileMenu
Menu, MenuBar, Add, &Settings, :MRefMenu
Menu, MenuBar, Add, &Help, :HelpMenu
Gui, Menu, MenuBar


Gui +hwndhMainGUI
Gui, Font,s12,Arial
Gui, Add, Text, x11 y8,MCode Generator using GCC
Gui, Font
Gui, Add, Text, x11 w520 h2 +0x1007
Gui, Add, GroupBox, x11 w520 h86, Required Parameters
Gui, Add, Text, x24 yp+27, Source (script file)
Gui, Add, Edit, x144 yp-5 w247 h23 +Disabled vSourceFile, `%Clipboard`%
Gui, Add, Button, x398 yp w53 h23 gBrowseSrc, &Browse
Gui, Add, Button, x+4 yp w64 h23 gUseCBoard, Clipboard
Gui, Add, Text, x24 yp+34, GCC Compiler
Gui, Add, Edit, x144 yp-4 w315 h23 vExeFile, % Get_Compiler(settings_File)
Gui, Add, Button, x466 yp w53 h23 gBrowseExe, B&rowse
Gui, Add, GroupBox, x11 w520 h52, Optimizations
Gui, Add, Radio, x24 yp+22 vOptimize1, None
Gui, Add, Radio, x+10 yp vOptimize2, Size (-Os)
Gui, Add, Radio, x+10 yp vOptimize3, Speed (-Ofast)
Gui, Add, Radio, x+10 yp vOptimize4, Overall (-O3)
Gui, Add, Text, x+15 yp w20, and
Gui, Add, Checkbox, x+21 yp vStripDebugInfo, Strip Debug Info (-g0)
Gui, Add, GroupBox, x11 w520 h128, Compiler Log
Gui, Font,, Consolas
Gui, Add, Edit, x20 yp+18 w502 h100p  +BackgroundTrans +c0x1A1A1A +ReadOnly vCompilerLog hwndhCompilerLog,Ready.
Gui, Font
Gui, Add, Button, x11 w120 h28 gGenerate Default, > &Generate MCode <
Gui, Add, Button, x+3 wp hp gCopytoClipboard, Copy to Clipboard
Gui, Add, Edit, x+5 yp+3 w272 h23 +ReadOnly -Multi vResultEdit, [Empty]
Gui, Add, Statusbar,, Ready

GroupAdd, h_gSelf, ahk_id %hMainGUI%

Gui, Show, w542 h400, MCode4GCC -- C/C++ to MCode Generator

;Load settings
	IniRead,MCodeStyle,%settings_File%,settings,MCodeStyle,Bentschi
	Menu, MRefMenu, Check, %MCodeStyle% Style
	IniRead,x,%settings_File%,settings,Optimize,1
	GuiControl,,Optimize%x%,1
	IniRead,x,%settings_File%,settings,StripDebugInfo
	GuiControl,,StripDebugInfo, % !!(x)

LogLn("<Running on: AHK Version " A_AhkVersion " - " (A_IsUnicode ? "Unicode" : "Ansi") " " (A_PtrSize == 4 ? "32" : "64") "bit>")
return


GuiClose:
	Gui,Submit
	IniWrite,%ExeFile%,%settings_File%,settings,Compilerpath
	IniWrite,%StripDebugInfo%,%settings_File%,settings,StripDebugInfo
	gosub,get_optimizations
	IniWrite,%Optimize%,%settings_File%,settings,Optimize
	IniWrite,%MCodeStyle%,%settings_File%,settings,MCodeStyle
ExitApp

SetMCodeStyle:
	Menu, MRefMenu, UnCheck, Bentschi Style
	Menu, MRefMenu, UnCheck, Laszlo Style
	Menu, MRefMenu, Check, %A_ThisMenuItem%
	MCodeStyle:=RegExReplace(A_ThisMenuItem,"\s.*")
return

get_optimizations:
	Gui, Submit, NoHide
	Optimize:=1
	Loop 4
		if (Optimize%A_index%) {
			Optimize:=A_Index
			break
		}
return

BrowseSrc:
	Gui, +OwnDialogs
	FileSelectFile, x, 1,, Open, C/C++ files (*.c; *.cpp)
	if ErrorLevel
		return
	GuiControl,, SourceFile, %x%
return

BrowseExe:
	Gui, +OwnDialogs
	FileSelectFile, x, 1,, Open, Executable files (*.exe)
	if ErrorLevel
		return
	GuiControl,, ExeFile, %x%
return

UseCBoard:
	GuiControl,,SourceFile, `%Clipboard`%
return

CopytoClipboard:
	GuiControlGet,x,,ResultEdit
	if x != [Empty]
	Clipboard:=x
return

#IfWinActive ahk_group h_gSelf
F1::
Help:
	run https://github.com/joedf/MCode4GCC/blob/master/README.md#help
return
#IfWinActive

MCodeHelp:
	if InStr(MCodeStyle,"Laszlo")
		run http://www.autohotkey.com/board/topic/19483-machine-code-functions-bit-wizardry
	else
		run http://ahkscript.org/boards/viewtopic.php?f=7&t=32
return

GuiDropFiles:
	if A_EventInfo > 1
		MsgBox, 48, MCode4GCC - Warning, You cannot drop more than one file into this window!
	SplitPath, A_GuiEvent,,, dropExt
	if dropExt = c
		GuiControl,, SourceFile, %A_GuiEvent%
	else if dropExt = exe
		GuiControl,, ExeFile, %A_GuiEvent%
return

Generate:
	Gui +Disabled
	Gui +OwnDialogs
	Gui, Submit,NoHide
	gosub,get_optimizations

	;get flags
	GuiControlGet,y,,Optimize%Optimize%,Text
	RegexMatch(y,"(\(.*\))",m)
	flags:= SubStr(m1,2,-1) " " ((StripDebugInfo)?"-g0":"")

	LogLn_Clear()
	LogLn("<Generating MCode...>")
	SB_SetText("Generating MCode...")
	QPC(1)
	if (SourceFile=="`%Clipboard`%") {
		y:=get_TempFile() ".c"
		FileAppend,%Clipboard%,%y%
		if ErrorLevel
		{
			LogLn("<ERROR : Could not write Clipboard contents to file!>")
			MsgBox, 16, MCode4GCC - ERROR, Could not write Clipboard contents to file!
			Gui -Disabled
			return
		}
		x:=MCode_Generate(y,ExeFile,flags)
		FileDelete,%y%
	} else {
		x:=MCode_Generate(SourceFile,ExeFile,flags)
	}
	RunTime:=QPC(0)
	if StrLen(x) {
		if InStr(MCodeStyle,"Bentschi") {
			LogLn("<Converting Hexadecimal to Base64...>")
			compiledCode := removeWhitespaceChars(Hex2Base64(x))
			x := "2,x" (Get_CompilerType(ExeFile)=="32"?"86":"64") ":" compiledCode
		}
		y:="Done. Run time: " RunTime " seconds"
		LogLn("<" y ">")
		SB_SetText(y)
		GuiControl,,ResultEdit,%x%
	} else {
		y:="<Failure. Errors occurred. Run time: " RunTime " seconds>"
		LogLn(y)
		SB_SetText(y)
		GuiControl,,ResultEdit,[Empty]
	}
	Gui -Disabled
return

About:
GuiControlGet,ExeFile,,ExeFile
if (About_ExeFile!=ExeFile) {
	x:=Trim(Get_stdout(ExeFile " --version"))
	StringReplace,x,x,`n,,All
	StringReplace,x,x,NO`r,NO%A_Space%,All
	StringReplace,x,x,%A_Space%%A_Space%,`n,All
	ExeFile_a:=x
	ExeFile_t:=Get_CompilerType(ExeFile)
	About_ExeFile:=ExeFile
}
MsgBox, 64, About MCode4GCC,
(
MCode4GCC - C/C++ MCode Generator using GCC
Revision: %@REVISION_DATE%

Copyright ©2014-%A_Year% Joe DF (joedf@ahkscript.org)
Special thanks to IsNull, fincs, Laszlo, SKAN, Bentschi and kon

Compiler is %ExeFile_t%-bit.
Compiler Path : "%ExeFile%"
%ExeFile_a%
)
return

MCode_Generate(file,cp,flags:="") {
	global @PATH_VAR
	tmpf_a:=get_TempFile()
	tmpf_b:=tmpf_a "_b"
	tmpf_c:=tmpf_a "_c"
	SplitPath, cp,, cpDir
	if !FileExist(cp) {
		cpPath:=get_where_Path(cp)
		SplitPath, cpPath,, cpDir
	}
	EnvSet, Path, %cpDir% ;Update path environment var
	RunWait, %comspec% /c %cp% %flags% -Wa`,-aln="%tmpf_a%" "%file%" -o "%tmpf_b%" 2> "%tmpf_c%",, UseErrorLevel Hide
	cpRunEL:=ErrorLevel, ReturnVar:=""
	EnvSet, Path, %@PATH_VAR% ;Restore env var
	if cpRunEL = ERROR
	{
		LogLn("<Error : Could not launch GCC! @ " """" cp """")
	} else {
		FileRead,data,%tmpf_a%
		FileRead,out,%tmpf_c%
		if StrLen(out:=Trim(out)) {
			StringReplace,out,out,%file%,SOURCEFILE,All
			out:="`n<Stderr output>:`n============================================================`n" out
			LogLn(out "`r============================================================")
			if Instr(out,"WinMain") ;ignore error: "undefined reference to 'WinMain'" or similar
			{
				LogLn("<Error ignored: undefined reference to 'WinMain'>")
				ReturnVar := MCode_Parse(data)
			}
		} else {
			ReturnVar := MCode_Parse(data)
		}
	}
	FileDelete,%tmpf_a%
	FileDelete,%tmpf_b%
	FileDelete,%tmpf_c%
	return ReturnVar
}

MCode_Parse(data,clean:=1) {
	if (clean)
		data:=MCode_ParseClean(data)
	p := 1, m := "", Output := ""
	while p := RegexMatch(data, "`ami)^\s*\d+(\s[\dA-F]{4}\s|\s{6})([\dA-F]+)", m, p + StrLen(m))
		Output .= m2
	return Output
}

MCode_ParseClean(data) {
	ndata:=""
	Loop, Parse, data, `n, `r
	{
		if Instr(A_LoopField,".ident	" """" "GCC: (GNU)")
			return ndata
		ndata .= A_LoopField "`n"
	}
	return ndata
}

Get_Compiler(sfile:="") {
	if !FileExist(sfile)
		sfile:=A_scriptFullPath
	IniRead,x,%sfile%,settings,Compilerpath,!NULL
	if !FileExist(x) and !StrLen(get_where_Path(x))
		return get_where_Path("gcc")
	return x
}

;;;;;;;;;;;;;;;;;;;;; utility functions ;;;;;;;;;;;;;;;;;;;;;
;###########################################################
;{
LogLn(line){
	global
	CompilerLogData .= line "`n"
	GuiControl,,CompilerLog, % CompilerLogData
	CompilerLog_LogLn+=1
	ControlSend,,{PGDN %CompilerLog_LogLn%}{Down 8}{End},ahk_id %hCompilerLog%
}
LogLn_Clear(){
	global
	CompilerLogData := ""
	GuiControl,,CompilerLog, % CompilerLogData
	CompilerLog_LogLn:=0
	ControlSend,,{PGDN}{Down}{End},ahk_id %hCompilerLog%
}
QPC( R := 0 ) {    ; By SKAN,  http://goo.gl/nf7O4G,  CD:01/Sep/2014 | MD:01/Sep/2014
	Static P := 0,  F := 0,     Q := DllCall( "QueryPerformanceFrequency", "Int64P",F )
	Return ! DllCall( "QueryPerformanceCounter","Int64P",Q ) + ( R ? (P:=Q)/F : (Q-P)/F )
}
get_TempFile(d:="") {
	if ( !StrLen(d) || !FileExist(d) )
		d:=A_Temp
	Loop
		tempName := d "\~temp" A_TickCount ".tmp"
	until !FileExist(tempName)
	return tempName
}
Get_CompilerType(cp) {
	if !FileExist(cp)
		cp:=get_where_Path(cp)
	if Is64BitAssembly(cp)
		return "64"
	else
		return "32"
}
get_where_Path(item) {
	data:=Get_stdout("where " item)
	Loop, parse, data, `n, `r
		return A_loopField	
}
Get_stdout(command) {
	tmpf:=get_TempFile()
	RunWait, %comspec% /c %command% > "%tmpf%",,Hide
	FileRead,data,%tmpf%
	FileDelete,%tmpf%
	return data
}
Is64BitAssembly(appName){
	static GetBinaryType := "GetBinaryType" (A_IsUnicode ? "W" : "A")
	static SCS_32BIT_BINARY := 0
	static SCS_64BIT_BINARY := 6
	ret := DllCall(GetBinaryType
		,"Str", appName
		,"int*", binaryType)
	return binaryType == SCS_64BIT_BINARY
}
Hex2Base64(hex) {
	sz:=StringToBinary(b,hex)
	Base64enc(out,b,sz)
	VarSetCapacity(out,-1) ; Strip everything after first null byte
	;return SubStr(out,1,sz) ; Strip garbage at the end
	return out
}
;http://www.autohotkey.com/board/topic/85709-base64enc-base64dec-base64-encoder-decoder/
Base64enc( ByRef OutData, ByRef InData, InDataLen ) { ; by SKAN
	DllCall("Crypt32.dll\CryptBinaryToString" (A_IsUnicode?"W":"A")
		,UInt,&InData,UInt,InDataLen,UInt,(0x40000000|0x01),UInt,0,UIntP,TChars,"CDECL Int")
	VarSetCapacity(OutData,Req:=TChars*(A_IsUnicode?2:1))
	DllCall("Crypt32.dll\CryptBinaryToString" (A_IsUnicode?"W":"A")
		,UInt,&InData,UInt,InDataLen,UInt,(0x40000000|0x01),Str,OutData,UIntP,Req,"CDECL Int")
	Return TChars
}
; BinaryToString() / StringToBinary() from laszlo, updated by joedf
; http://ahkscript.org/forum/viewtopic.php?p=304556#304556
; fmt = 1:base64, 4:hex-table, 5:hex+ASCII, 10:offs+hex, 11:offs+hex+ASCII, 12:raw-hex
StringToBinary(ByRef bin, hex, fmt=12) {    ; return length, result in bin
	DllCall("Crypt32.dll\CryptStringToBinary","Str",hex,"UInt",StrLen(hex),"UInt",fmt,"UInt",0,"UInt*",cp,"UInt",0,"UInt",0,"CDECL UInt") ; get size
	VarSetCapacity(bin,cp)
	DllCall("Crypt32.dll\CryptStringToBinary","Str",hex,"UInt",StrLen(hex),"UInt",fmt,"UInt",&bin,"UInt*",cp,"UInt",0,"UInt",0,"CDECL UInt")
	Return cp
}
removeWhitespaceChars(str) {
	if InStr(str, "`r")
		str := StrReplace(str, "`r", "")
	if InStr(str, "`n")
		str := StrReplace(str, "`n", "")
	if InStr(str, "`t")
		str := StrReplace(str, "`t", "")
	if InStr(str, " ")
		str := StrReplace(str, " ", "")
	return str
}
;}

;SCRIPT END
