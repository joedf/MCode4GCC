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
Optimize=2
)

if !FileExist(settings_File:="MCode4GCC.ini")
	FileAppend,%MCode4GCC_settings%,%settings_File%

Gui Main:Default
Gui, +hwndhMainGUI

Menu, FileMenu, Add, &Generate MCode, Generate
Menu, FileMenu, Add
Menu, FileMenu, Add, E&xit`tAlt+F4, GuiClose
Menu, HelpMenu, Add, &Help (Forum Thread), Help
Menu, HelpMenu, Add
Menu, HelpMenu, Add, &About, About
Menu, MenuBar, Add, &File, :FileMenu
Menu, MenuBar, Add, &Help, :HelpMenu
Gui, Menu, MenuBar

Gui, Font,s12,Arial
Gui, Add, Text, ,MCode Generator using GCC
Gui, Font
Gui, Add, Text, x11 w520 h2 +0x1007
Gui, Add, GroupBox, x11 w520 h86, Required Parameters
Gui, Add, Text, x24 yp+27, Source (script file)
Gui, Add, Edit, x144 yp-5 w247 h23 +Disabled vSourceFile, `%Clipboard`%
Gui, Add, Button, x398 yp w53 h23 gBrowseSrc, &Browse
Gui, Add, Button, x+4 yp w64 h23 gCBoard, Clipboard
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
Gui, Add, Button, x213 w120 h28 gGenerate Default , > &Generate MCode <
Gui, Add, Statusbar,, Ready

Gui, Show, w542 h400, MCode4GCC -- C/C++ to MCode Generator

IniRead,x,%settings_File%,settings,Optimize,1
GuiControl,,Optimize%x%,1
IniRead,x,%settings_File%,settings,StripDebugInfo
GuiControl,,StripDebugInfo, % !!(x)

LogLn("<Running on: AHK Version "A_AhkVersion " - " (A_IsUnicode ? "Unicode" : "Ansi") " " (A_PtrSize == 4 ? "32" : "64") "bit>")
return


MainGuiClose:
GuiClose:
Gui,Main:Submit
IniWrite,%ExeFile%,%settings_File%,settings,Compilerpath
IniWrite,%StripDebugInfo%,%settings_File%,settings,StripDebugInfo
gosub,get_optimizations
IniWrite,%Optimize%,%settings_File%,settings,Optimize
ExitApp

get_optimizations:
Gui, Main:Submit, NoHide
Optimize:=1
Loop 4
{
	if (Optimize%A_index%) {
		Optimize:=A_Index
		break
	}
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

CBoard:
GuiControl,,SourceFile, `%Clipboard`%
return

Help:
run http://ahkscript.org/boards/viewtopic.php?f=7&t=32
return

MainGuiDropFiles:
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
Gui, Main:Submit,NoHide
gosub,get_optimizations

;get flags
GuiControlGet,y,Main:,Optimize%Optimize%,Text
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
	y:="<Done. Run time: " RunTime " seconds>"
	LogLn(y)
	SB_SetText(y)
	z:=ExeFile
	if !FileExist(ExeFile)
		z:=get_where_Path(ExeFile)
	if Is64BitAssembly(z)
		x := "1,x64:" x
	else
		x := "1,x86:" x
	Display(x)
} else {
	y:="<Failure. Errors occurred. Run time: " RunTime " seconds>"
	LogLn(y)
	SB_SetText(y)
	Gui -Disabled
}
return

About:
GuiControlGet,ExeFile,,ExeFile
if (About_ExeFile!=ExeFile) {
	x:=Trim(Get_stdout(ExeFile " --version"))
	StringReplace,x,x,`n,,All
	StringReplace,x,x,NO`r,NO%A_Space%,All
	StringReplace,x,x,%A_Space%%A_Space%,`n,All
	ExeFile_a:=x
	About_ExeFile:=ExeFile
}
MsgBox, 64, About MCode4GCC,
(
MCode4GCC - C/C++ MCode Generator using GCC

Copyright ©2014-%A_Year% Joe DF (joedf@ahkscript.org)
Special thanks to IsNull, fincs and kon

Compiler Path : "%ExeFile%"
%ExeFile_a%
)
return

MCode_Generate(file,cp,flags:="") {
	tmpf_a:=get_TempFile()
	tmpf_b:=tmpf_a "_b"
	tmpf_c:=tmpf_a "_c"
	RunWait, %comspec% /c %cp% %flags% -Wa`,-aln="%tmpf_a%" "%file%" -o "%tmpf_b%" 2> "%tmpf_c%",, UseErrorLevel Hide
	if ErrorLevel = ERROR
	{
		LogLn("<Error : Could not launch GCC! @ " """" cp """")
		FileDelete,%tmpf_b%
		FileDelete,%tmpf_a%
		FileDelete,%tmpf_c%
		return
	} else {
		FileRead,data,%tmpf_a%
		FileRead,out,%tmpf_c%
		FileDelete,%tmpf_b%
		FileDelete,%tmpf_a%
		FileDelete,%tmpf_c%
		
		if StrLen(out:=Trim(out)) {
			StringReplace,out,out,%file%,SOURCEFILE,All
			out:="`n<Stderr output>:`n============================================================`n" out
			LogLn(out "`r============================================================")
			if Instr(out,"WinMain") ;ignore error: "undefined reference to 'WinMain'" or similar
			{
				LogLn("<Error ignored: undefined reference to 'WinMain'>")
				return MCode_Parse(data)
			}
		} else {
			return MCode_Parse(data)
		}
	}
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
		return get_GCC_Path()
	return x
}

Display(data) {
	Gui Main:+Disabled
	Gui Main:+OwnDialogs
	global DisplayData
	global hMainGUI
	DisplayData := data
	Gui Display:Destroy
	Gui Display:Add, Edit, w300 h100 +ReadOnly, % data
	Gui Display:Add, Button, gDisplayCopy, Copy to Clipboard
	Gui Display:Add, Button, gDisplayGuiclose yp x+3, Close
	Gui Display:Show
	return
	
	DisplayCopy:
	Clipboard := DisplayData
	DisplayGuiclose:
	Gui Display:Destroy
	Gui Main:-Disabled
	Gui Main:Default
	WinActivate,ahk_id %hMainGUI%
	return
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
get_GCC_Path() {
	return get_where_Path("gcc")
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
;}

;SCRIPT END
