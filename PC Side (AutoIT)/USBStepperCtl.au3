#include <StringConstants.au3>
#include <ComUDF.au3>

Global $ProgName="USBStepperCtl"

Global $Device

Global $ComPort = "COM5"
Global $MinPulseWidth = 0
Global $RunConfig = "Default"
Global $StepsPerRev = 1600
Global $MaxSpeed = 1000
Global $Acceleration = 200
Global $Speed = 500

Global $EOR = @TAB		; End Of Record = chr(0x09)
Global $EOM = @LF		; End of Message = chr(0x0A)

Global $DefaultTimeout = 2000
Global $MaxMoveTimeout = 20000

Global $RunDemo = "Demo1"

; Ensure Master Script Directory is Set As Working Dir
FileChangeDir(@ScriptDir)

; Determine INI Config file name
$IniFile = StringTrimRight(@ScriptFullPath,4) & ".ini"

; Get INI Data
GetConfig($IniFile)

ConnectDevice($ComPort)

SendCmdToDevice("setMinPulseWidth" & $EOR & $MinPulseWidth)
SendCmdToDevice("setMaxSpeed" & $EOR & $MaxSpeed)
SendCmdToDevice("setAcceleration" & $EOR & $Acceleration)
SendCmdToDevice("setSpeed" & $EOR & $Speed)

SendCmdToDevice("enableOutputs")

SendCmdToDevice("setCurrentPosition" & $EOR & "0")

While (1)

	Switch $RunDemo
		Case "Demo1"
			Demo1()
		Case "Demo2"
			Demo2()
		Case "Demo3"
			Demo3()
	EndSwitch

WEnd

SendCmdToDevice("disableOutputs")

Quit()

;-------------------------------------------------------------------------------------------------------

Func Demo1()
	SendCmdToDevice("runToNewPosition" & $EOR & StepsFromDegrees(360, $StepsPerRev), $MaxMoveTimeout)
	sleep(2000)

	SendCmdToDevice("move" & $EOR & StepsFromDegrees(-360, $StepsPerRev))
	SendCmdToDevice("runToPosition", $MaxMoveTimeout)
	sleep(2000)
EndFunc

Func Demo2()
	SendCmdToDevice("move" & $EOR & StepsFromDegrees(18, $StepsPerRev))
	SendCmdToDevice("runToPosition", $MaxMoveTimeout)
	sleep(2000)
EndFunc

Func Demo3()
	SendCmdToDevice("runToNewPosition" & $EOR & StepsFromDegrees(Random(0, 19, 1)*18, $StepsPerRev), $MaxMoveTimeout)
	sleep(2000);
EndFunc

;-------------------------------------------------------------------------------------------------------

Func StepsFromDegrees($Deg, $SPR)
	Return ($Deg * ($SPR / 360))
EndFunc

Func GetConfig($IniFile)
	If FileExists($IniFile) then
		$ComPort =       IniRead($IniFile, "Config",   "ComPort",       $ComPort)
		$MinPulseWidth = IniRead($IniFile, "Config",   "MinPulseWidth", $MinPulseWidth)
		$RunConfig =     IniRead($IniFile, "Config",   "RunConfig",     $RunConfig)
		$RunDemo =       IniRead($IniFile, "Config",   "RunDemo",       $RunDemo)

		$StepsPerRev =   IniRead($IniFile, $RunConfig, "StepsPerRev",   $StepsPerRev)
		$MaxSpeed =      IniRead($IniFile, $RunConfig, "MaxSpeed",      $MaxSpeed)
		$Acceleration =  IniRead($IniFile, $RunConfig, "Acceleration",  $Acceleration)
		$Speed =         IniRead($IniFile, $RunConfig, "Speed",         $Speed)
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


