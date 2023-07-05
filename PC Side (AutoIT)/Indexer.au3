#include <StringConstants.au3>
#include <WindowsConstants.au3>
#include <GUIConstants.au3>

#include <ComUDF.au3>
#include "AutoItSharedData.au3"

Global $ProgName="Indexer"
Global $AgentName

Global $Device

Global $ComPort = "COM5"
Global $MinPulseWidth = 0
Global $RunConfig = "Default"
Global $Reverse = 0
Global $Direction = 1
Global $StepsPerRev = 1600
Global $MaxSpeed = 1000
Global $Acceleration = 200
Global $Speed = 500
Global $Enabled = 0

Global $IndexDegrees = 1

Global $EOR = @TAB		; End Of Record = chr(0x09)
Global $EOM = @LF		; End of Message = chr(0x0A)

Global $DefaultTimeout = 2000
Global $MaxMoveTimeout = 20000

Global $SharedData

$SharedData = _AutoIt_SharedData_CreateOrAttach($ProgName)
$SharedData.Cmd = ""

; Ensure Master Script Directory is Set As Working Dir
FileChangeDir(@ScriptDir)

; Determine INI Config file name
$IniFile = StringTrimRight(@ScriptFullPath,4) & ".ini"

; Get INI Data
GetConfig($IniFile)
If $Reverse Then $Direction = -1

; Determine Mode
AutoITSetOption("WinTitleMatchMode", 3)
$AgentName = $ProgName & " (Agent)"
If WinExists($AgentName) Then
    If WinExists($ProgName) Then
		MsgBox(16,$ProgName,"ERROR: Another client already running!")
		Exit
	EndIf
	ClientMode()
Else
	AgentMode()
EndIf

Exit

; ---------------------------------------------------------------------------------------------------------------------------

Func AgentMode()

ConnectDevice($ComPort)

SendCmdToDevice("setMinPulseWidth" & $EOR & $MinPulseWidth)
SendCmdToDevice("setMaxSpeed" & $EOR & $MaxSpeed)
SendCmdToDevice("setAcceleration" & $EOR & $Acceleration)
SendCmdToDevice("setSpeed" & $EOR & $Speed)

SendCmdToDevice("setCurrentPosition" & $EOR & "0")

$hMainGUI = GUICreate($AgentName, 230, 215)

GUICtrlCreateLabel("CCW", 10,  25, 100, 20, $SS_CENTER)
GUICtrlCreateLabel("CW", 120,  25, 100, 20, $SS_CENTER)
Global $CCW_Move     = GUICtrlCreateButton("Move",               10,  50, 100, 20)
Global $CW_Move      = GUICtrlCreateButton("Move",              120,  50, 100, 20)
Global $CCW_Tweak    = GUICtrlCreateButton("Tweak",              10,  75, 100, 20)
Global $CW_Tweak     = GUICtrlCreateButton("Tweak",             120,  75, 100, 20)

Global $Enable       = GUICtrlCreateButton("Enable",             10, 125, 100, 20)
Global $Disable      = GUICtrlCreateButton("Disable",           120, 125, 100, 20)

Global $Quit_Button  = GUICtrlCreateButton("Quit",               65, 175, 100, 20)

GUISetState()

While 1
	$msg = GUIGetMsg()
	Switch $msg
		Case $GUI_EVENT_CLOSE
			ExitLoop
		Case $Quit_Button
			ExitLoop
		Case $CCW_Tweak
			Move(-1)
		Case $CW_Tweak
			Move(1)
		Case $CCW_Move
			Move(StepsFromDegrees($IndexDegrees, $StepsPerRev) * $Direction * -1)
		Case $CW_Move
			Move(StepsFromDegrees($IndexDegrees, $StepsPerRev) * $Direction)
		Case $Enable
			SendCmdToDevice("enableOutputs")
			$Enabled = 1
		Case $Disable
			SendCmdToDevice("disableOutputs")
			$Enabled = 0
	EndSwitch

	If $SharedData.Cmd <> "" Then
		Switch $SharedData.Cmd
			Case "CCW"
				AutoEnable()
				Move(StepsFromDegrees($IndexDegrees, $StepsPerRev) * $Direction * -1)
			Case "CW"
				AutoEnable()
				Move(StepsFromDegrees($IndexDegrees, $StepsPerRev) * $Direction)
		EndSwitch
		$SharedData.Cmd = ""
	EndIf

WEnd

GUIDelete()

SendCmdToDevice("disableOutputs")

Quit()

EndFunc

; ---------------------------------------------------------------------------------------------------------------------------

Func ClientMode()

	If StringLen($CmdLineRaw) > 0 Then
		$SharedData.Cmd = $CmdLineRaw
	Else
		MsgBox(16,$ProgName,"ERROR: Command Line Required for 2nd (Client) instance!")
	EndIf

EndFunc

;-------------------------------------------------------------------------------------------------------

Func AutoEnable()
	If $Enabled <> 1 Then
		SendCmdToDevice("enableOutputs")
		$Enabled = 1
	EndIf
EndFunc

Func Move($Steps)
	SetButtons($GUI_DISABLE)
	SendCmdToDevice("move" & $EOR & $Steps, $MaxMoveTimeout)
	SendCmdToDevice("runToPosition", $MaxMoveTimeout)
	SetButtons($GUI_ENABLE)
EndFunc

Func SetButtons($Mode)
	GUICtrlSetState($CCW_Tweak, $Mode)
	GUICtrlSetState($CW_Tweak,  $Mode)
	GUICtrlSetState($CCW_Move,  $Mode)
	GUICtrlSetState($CW_Move,   $Mode)
EndFunc

Func StepsFromDegrees($Deg, $SPR)
	Return ($Deg * ($SPR / 360))
EndFunc

Func GetConfig($IniFile)
	If FileExists($IniFile) then
		$ComPort =       IniRead($IniFile, "Config",   "ComPort",       $ComPort)
		$MinPulseWidth = IniRead($IniFile, "Config",   "MinPulseWidth", $MinPulseWidth)
		$RunConfig =     IniRead($IniFile, "Config",   "RunConfig",     $RunConfig)

		$Reverse =       IniRead($IniFile, $RunConfig, "Reverse",       $Reverse)
		$StepsPerRev =   IniRead($IniFile, $RunConfig, "StepsPerRev",   $StepsPerRev)
		$MaxSpeed =      IniRead($IniFile, $RunConfig, "MaxSpeed",      $MaxSpeed)
		$Acceleration =  IniRead($IniFile, $RunConfig, "Acceleration",  $Acceleration)
		$Speed =         IniRead($IniFile, $RunConfig, "Speed",         $Speed)

		$IndexDegrees = IniRead($IniFile, $RunConfig, "IndexDegrees", $IndexDegrees)
	EndIf
EndFunc

Func FatalError($ErrorMsg = "")
	If StringLen($errorMsg) > 0 Then
		MsgBox(16,$ProgName,$ErrorMsg)
	EndIf
	Quit()
EndFunc

Func Quit()
	_COM_ClosePort($Device)
	Exit
EndFunc

;-----------------------------------------------------------------------------------------------------------------------------------------

Func ConnectDevice($Port)
	$Device = _COM_OpenPort($Port & ": baud=9600")
	If @error Then FatalError("Failure Opening COM Port: " & $Port)
	Sleep(1000)
EndFunc

Func SendCmdToDeviceNoWait($Cmd)
	_COM_SendString($Device, $Cmd & $EOM)
	If @error Then FatalError("Device Send Error " & @error & " - Exiting!")
EndFunc

Func SendCmdToDevice($Cmd, $ReplyTimeout=$DefaultTimeout, $Expect="OK")
	_COM_SendString($Device, $Cmd & $EOM)
	If @error Then FatalError("Device Send Error " & @error & " - Exiting!")

	$sReturn=GetResponseFromDevice($ReplyTimeout)

	If($Expect <> "") Then
		If($sReturn <> $Expect) Then FatalError("Command: " & $Cmd & @CRLF & "Expected: " & $Expect & @CRLF & "Got: " & $sReturn)
	EndIf

	Return $sReturn
EndFunc

Func GetResponseFromDevice($ReplyTimeout=$DefaultTimeout)
Local $Buff = ""

	$RTimer=TimerInit()
	Do
		If(TimerDiff($RTimer) > $ReplyTimeout) Then
			FatalError("Device Unresponsive: Exiting!")
			; Return ""
		EndIf
	Until CheckMsgFromDevice($Buff) = 1

	Return $Buff
EndFunc

Func CheckMsgFromDevice(ByRef $Buff)

	If _COM_GetInputcount($Device) < 1 Then Return 0

	While 1
		$aChar = _COM_ReadChar($Device)
		If $aChar = -1 Then Return 0				; Timeout - Still waiting for <EOM>
		If $aChar = $EOM Then Return 1				; Found <EOM>
		$Buff &= $aChar								; Concatenate to Buffer
	WEnd

EndFunc


