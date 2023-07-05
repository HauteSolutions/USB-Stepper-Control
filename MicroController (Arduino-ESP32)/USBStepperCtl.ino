#include <AccelStepper.h>

#define DIR_PIN 12
#define STEP_PIN 14
#define ENABLE_PIN 13

char *CmdArray[] = {
  "setMinPulseWidth", 
  "setMaxSpeed",
  "setAcceleration",
  "setPinsInverted",
  "enableOutputs",
  "disableOutputs",
  "setEnablePin",
  "setSpeed",
  "setCurrentPosition",
  "stop",
  "maxSpeed",
  "speed",
  "targetPosition",
  "currentPosition",
  "distanceToGo",
  "isRunning",
  "move",
  "moveTo",
  "runToNewPosition",
  "runToPosition"
};
int NumCmds;

#define BUFFSIZE 512
char TxBuff[BUFFSIZE];
char RxBuff[BUFFSIZE];

char EOR = 0x09;  // End of Record = TAB
char EOM = 0x0A;  // Eond of Message = LF

int Position = 0;

AccelStepper stepper(AccelStepper::DRIVER, STEP_PIN, DIR_PIN);

void setup() {

  Serial.begin(9600);
  while (!Serial);
	
  RxBuff[0]='\0';
  TxBuff[0]='\0';

  NumCmds = sizeof(CmdArray) / sizeof(CmdArray[0]);

  stepper.setEnablePin(ENABLE_PIN);
  stepper.setPinsInverted(false, false, true);

  stepper.disableOutputs();
}

void loop() {
    if(CheckSerial(RxBuff, BUFFSIZE)) ProcessSerial(RxBuff);

    stepper.run();
}

int CheckSerial(char *buff, int buffmax) {
int c;
int i;

  while (Serial.available()) {
    c = Serial.read();
    i = strlen(buff); 
    if (i < (buffmax - 1)) {
      buff[i] = c;  
      buff[i+1] = '\0';
    }
    if (c == EOM) return strlen(buff);
  }

  return 0;
}

void ProcessSerial(char *Buff) {
long int PLong;

  PLong = GetLongParam(Buff, 1);
  strcpy(TxBuff, "OK");
  switch (GetCommandID(Buff, CmdArray, NumCmds)) {

    case 1:     // setMinPulseWidth
      stepper.setMinPulseWidth(PLong);
      break;

    case 2:     // setMaxSpeed
      stepper.setMaxSpeed(PLong);
      break;

    case 3:     // setAcceleration
      stepper.setAcceleration(PLong);
      break;

    case 4:     // setPinsInverted
      SetPinsInvertedHandler(Buff);
      break;

    case 5:     // enableOutputs
      stepper.enableOutputs();
      break;

    case 6:     // disableOutputs
      stepper.disableOutputs();
      break;

    case 7:     // setEnablePin
      stepper.setEnablePin(PLong);
      break;

    case 8:     // setSpeed
      stepper.setSpeed(PLong);
      break;

    case 9:     // setCurrentPosition
      stepper.setCurrentPosition(PLong);
      break;

    case 10:     // stop
      stepper.stop();
      break;

    case 11:     // maxSpeed
      dtostrf(stepper.maxSpeed(),1,2,TxBuff);
      break;

    case 12:     // speed
      dtostrf(stepper.speed(),1,2,TxBuff);
      break;

    case 13:     // targetPosition
      sprintf(TxBuff, "%ld", stepper.targetPosition());
      break;

    case 14:     // currentPosition
      sprintf(TxBuff, "%ld", stepper.currentPosition());
      break;

    case 15:     // distanceToGo
      sprintf(TxBuff, "%ld", stepper.distanceToGo());
      break;

    case 16:     // isRunning
      sprintf(TxBuff, "%s", stepper.isRunning() ? "true" : "false");
      break;

    case 17:     // move
      stepper.move(PLong);
      break;

    case 18:     // moveTo
      stepper.moveTo(PLong);
      break;

    case 19:    // runToNewPosition
      stepper.runToNewPosition(PLong);
      break;

    case 20:    // runToPosition
      stepper.runToPosition();
      break;

    default:
      sprintf(TxBuff, "Error%c%d", EOR, 1);
  }

  SendMessage(TxBuff);

  Buff[0] = '\0';
  return;
}

void SetPinsInvertedHandler(char *CmdBuff) {
int NumParams;
char Param[5][10];

  NumParams = CountDelims(CmdBuff, EOR);
  if(NumParams > 5) NumParams=0;
  
  for(int i=0; i<NumParams; i++) StrGetSlice(CmdBuff, EOR, i+1, Param[i], 10);

  switch (NumParams) {
    case 0:
      stepper.setPinsInverted();
      break;
    case 1:
      stepper.setPinsInverted(Param[1]);
      break;
    case 2:
      stepper.setPinsInverted(Param[1],Param[2]);
      break;
    case 3:
      stepper.setPinsInverted(Param[1],Param[2],Param[3]);
      break;
    case 5:
      stepper.setPinsInverted(Param[1],Param[2],Param[3],Param[4],Param[5]);
      break;
  }
}

void SendMessage(char *msg) {
  Serial.print(msg);
  Serial.write(EOM);
  Serial.flush();
}

long int GetLongParam(char *Buffer, int PNo) {
char Param[80];

  if(StrGetSlice(Buffer, EOR, PNo, Param, 80) == 0) return 0;
  return atol(Param);
}

int GetCommandID(char *astring, char *Array[], int NumCmds) {
int i;

  for (i=0; i<NumCmds; i++) {
    if(!strncasecmp(astring,Array[i],strlen(Array[i]))) return i+1;
  }
  return 0;
}

int CountDelims(char *astring, char delim) {
int i;
int len;
int count = 0;

  len = strlen(astring);
  for(i=0; i++; i<len) if(astring[i] == delim) count++;
  return count;
}

int StrGetSlice(char *Source, char Delim, int Pos, char *Slice, int MaxLen) {
int i;
int Len;
int SafeLen;
char *pStart;
char *pEnd;

  i = 0;
  pStart = Source;
  while (true) {
    pEnd=strchr(pStart, Delim);
    if(pEnd == NULL) {
      if(i < Pos) {
        if (Slice != NULL) strcpy(Slice, "");
        return 0;
      }
      pEnd=pStart+strlen(pStart);
    }
    
    if(i == Pos) {
      Len = (pEnd-pStart);
      if((Slice == NULL)  || (MaxLen == 0)) return Len;

      if(Len + 1 > MaxLen) SafeLen = MaxLen-1;
      else SafeLen=Len;

      strncpy(Slice, pStart, SafeLen);
      Slice[SafeLen] = '\0';
      return Len;
    }

    pStart = pEnd + 1;
    i++;
  }

  return 0;
}


