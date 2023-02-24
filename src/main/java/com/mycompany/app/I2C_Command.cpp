/**********************************************************************

  I2C_Command.cpp
  COPYRIGHT (c) 2022 EMA

  Part of Railway_Control Base Station for the Arduino

**********************************************************************/
/**********************************************************************

  Railway_Control Base Station supports optional I2C control of Nano Arduino for custom purposes.
  The Nano supports specific Motor Drivers like L298N to control part of tracks. These tracks could be
  use by old cabs without DCC protocol.
  Nano can be activited or de-activated.

  Definitions and state of Nano are retained in EEPROM and restored on power-up.
  The default is to set each defined Nano to active or inactive according to its restored state.

  These Nano support parts of tracks with the following definition :
  - Nano identification :
  - 0 for the Mega, master of I2C communication.
  - 1 to 9 for Nano. These 1 to 9 are knowned also the address of each Nano.
      in my realisation I have 4 Nano for tracks management and 1 nano for accessories.
  - Track identification : 0 to 9. 
      In my realisation I have 6 independant tracks.
  - Part of track (canton) identification : 0 to 9. 
      In my realisation I have 4 cantons for each independant track.

With SerialCommand the followed comand are implemented :
  <t for throttle function
    The serial message structure from Processind to Mega is :
      <t REGISTER CAB SPEED DIRECTION CANTON>
      
    The I2C message structure from Mega to Nano is :
      dataToI2C[0] = '&';   //  Start of message key code = 38
      dataToI2C[1] = 0;   //  Nano address <=> cab
      dataToI2C[2] = '1';   //  Motor driver management = '1' key code = 49
      dataToI2C[3] = tSpeed * 2;   //  Speed (0 to 258)
      dataToI2C[4] = tDirection;   //  Direction (0 backward or 1 forward)
      dataToI2C[5] = 0;   //  Canton management : Track
      dataToI2C[6] = 0;   //  Canton management : Canton
      dataToI2C[7] = 0;   //  Canton management : Sub Canton
      dataToI2C[8] = '*';   //  End of message key code = 42

  <Q for current sensor function
    The serial message structure from Processing to Mega is :
      <Q>
      
    The I2C message structure from Mega to Nano is :
      dataToI2C[0] = '&';   //  Start of message key code = 38
      dataToI2C[1] = i + 1; //  Nano address <=> cab
      dataToI2C[2] = '2';   //  Current sensor request = '2' key code = 50
      dataToI2C[3] = '*';   //  End of message key code = 42

    The I2C message structure from Nano to Mega is :
      dataToI2C[0] = '#';   //  Start of message key code = 35
      dataToI2C[1] = addressI2CNano;
      dataToI2C[2] = '2';   //  Current sensor management = '2' key code = 50
      dataToI2C[3] = mA0;
      dataToI2C[4] = mA1;
      dataToI2C[5] = mA2;
      dataToI2C[6] = mA3;
  
      dataToI2C[19] = '*';   //  End of message key code = 42
    
    The serial message structure from Mega to Processing is :
      <Q> for current sensor value > 80 mA
      <q> for current sensor value < 80 mA

  Future commands
    Turnout

    Signal
    
**********************************************************************/

//////////////////////////////////////////////////////////////////////////
//  Library

#include "I2C_Command.h"
#include "SerialCommand.h"
#include "DCCpp_Mega.h"
#include "Comm.h"

//////////////////////////////////////////////////////////////////////////
// VARIABLES

int addressI2CNano1 = 1;
int addressI2CNano2 = 2;
int addressI2CNano3 = 3;
int addressI2CNano4 = 4;
int addressI2CNano5 = 5;
int addressI2CNano;
int addressI2C;
byte dataToI2C[20];
byte dataFromI2C[20];
byte dataCurrent[10];
byte I2CcurrentNano[5][4];  //  type arrayname [Line][Row] ;
int lenghtDataI2C;
int power_conf;   //  Define power configuration with or without canton restriction

///////////////////////////////////////////////////////////////////////////////

void I2C_Command::I2C_Scan(int nDevice) {
  int NumNano[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  INTERFACE.print("<NI2C Scanning...>");

  for (byte address = 1; address < 127; ++address) {
    // The i2c_scanner uses the return value of
    // the Write.endTransmisstion to see if
    // a device did acknowledge to the address.
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission();

    if (error == 0) {
      NumNano[address] = address;
      ++nDevice;
    } else if (error == 4) {
      INTERFACE.print("<N");
      INTERFACE.print("Error 4 at : ");
      INTERFACE.print(address);
      INTERFACE.print(">");
    }
  }
  if (nDevice == 0) {
    INTERFACE.print("<N");
    INTERFACE.print("No I2C devices found");
    INTERFACE.print(">");
  } else {
    INTERFACE.print("<N");
    INTERFACE.print(nDevice);
    INTERFACE.print(" Nano found : ");
    for (int i = 0; i < 10; i++) {
      INTERFACE.print(NumNano[i]);
      INTERFACE.print(" ");
    }
    INTERFACE.print(">");
  }
  power_conf = 0;   //  Define power configuration with or without canton restriction

  //  Init received buffers for current measures
  for (int i = 1; i <= 5; i++) {
    for (int j = 0; j < 10; j++) {
      //I2CcurrentNano[i][j] = 0;
      dataFromI2C[j] = 0;
    }
  }
}

///////////////////////////////////////////////////////////////////////////////

void I2C_Command::I2C_Throttle(char *s) {
  byte b[5];                      // save space for checksum byte
  int nReg;
  int cab;        //  In Canton management, it is used to define track and Nano
  int tSpeed;
  int tDirection;
  int tCanton;
  byte nB = 0;

  //    Init I2C buffer
  for (int j = 0 ; j <= 18; j++) {
    dataToI2C[j] = 0;
  }
  dataToI2C[19] = '*';    // End of array key code = 42

  if (sscanf(s, "%d %d %d %d %d", &nReg, &cab, &tSpeed, &tDirection, &tCanton) != 5)
    return;

  if (cab > 127)
    b[nB++] = highByte(cab) | 0xC0;    // convert train number into a two-byte address

  b[nB++] = lowByte(cab);
  b[nB++] = 0x3F;                      // 128-step speed control byte
  if (tSpeed >= 0)
    b[nB++] = tSpeed + (tSpeed > 0) + tDirection * 128; // max speed is 126, but speed codes range from 2-127 (0=stop, 1=emergency stop)
  else {
    b[nB++] = 1;
    tSpeed = 0;
  }
  dataToI2C[0] = '&';   //  Start of message key code = 38
  dataToI2C[1] = 0;   //  Nano address <=> cab
  dataToI2C[2] = '1';   //  Motor driver management = '1' key code = 49
  dataToI2C[3] = tSpeed * 2;   //  Speed (0 to 258)
  dataToI2C[4] = tDirection;   //  Direction (0 backward or 1 forward)
  dataToI2C[5] = 0;   //  Canton management : Track
  dataToI2C[6] = 0;   //  Canton management : Canton
  dataToI2C[7] = 0;   //  Canton management : Sub Canton
  dataToI2C[8] = '*';   //  End of message key code = 42

  //  Emergency stop
  if (tSpeed == -1) {    //  All cab speed must be to 0
    dataToI2C[3] = 0;
    dataToI2C[5] = 0;
    I2C_SendData(addressI2CNano1, 10, dataToI2C); //Nanoaddress, Nb data to send, dataset
    I2C_SendData(addressI2CNano2, 10, dataToI2C); //Nanoaddress, Nb data to send, dataset
    I2C_SendData(addressI2CNano3, 10, dataToI2C); //Nanoaddress, Nb data to send, dataset
    I2C_SendData(addressI2CNano4, 10, dataToI2C); //Nanoaddress, Nb data to send, dataset
  } else {
    //    if (power_conf == 1) ==> Full power <==> without Canton management
    //      all cantons of a track are powered in same time
    //      independently of cab's position on Processing track
    //
    //    if (power_conf == 0) ==> with Canton Management
    //    in this case for a track
    //      the current and the next cantons are powered in function of cab's position on Processing
    //      the two others are not powered
    //
    if (tCanton > 100 && tCanton < 200) {   //  Track A - Nano 1
      addressI2CNano = addressI2CNano1;
      dataToI2C[1] = addressI2CNano1;
      dataToI2C[5] = 1;
      if (power_conf == 1) {    //    Power_conf = 1 ==> Full power configuration (without canton management by Nano
        dataToI2C[6] = 0;
      }
      else {    //    Power_conf = 0 ==> Canton power configuration (with canton management by Nano
        if (tCanton < 120) {                            //  Motor driver L298 A
          dataToI2C[6] = 1;
        } else if (tCanton >= 120 && tCanton < 130) {   //  Motor driver L298 B
          dataToI2C[6] = 2;
        } else if (tCanton >= 130 && tCanton < 140) {   //  Motor driver L298 C
          dataToI2C[6] = 3;
        } else if (tCanton >= 140) {                    //  Motor driver L298 D
          dataToI2C[6] = 4;
        }
      }
    }
    else if (tCanton > 200 && tCanton < 300) {   //  Voie B Nano 2
      addressI2CNano = addressI2CNano2;
      dataToI2C[1] = addressI2CNano2;
      dataToI2C[5] = 2;
      if (power_conf == 1) {    //    Power_conf = 1 ==> Full power configuration (without canton management by Nano
        dataToI2C[6] = 0;
      }
      else {    //    Power_conf = 0 ==> Canton power configuration (with canton management by Nano
        if (tCanton < 220) {                            //  Motor driver L298 A
          dataToI2C[6] = 1;
        } else if (tCanton >= 220 && tCanton < 230) {   //  Motor driver L298 B
          dataToI2C[6] = 2;
        } else if (tCanton >= 230 && tCanton < 240) {   //  Motor driver L298 C
          dataToI2C[6] = 3;
        } else if (tCanton >= 240) {                    //  Motor driver L298 D
          dataToI2C[6] = 4;
        }
      }
    }
    else if (tCanton > 300 && tCanton < 400) {   //  Voie C Nano 3
      addressI2CNano = addressI2CNano3;
      dataToI2C[1] = addressI2CNano3;
      dataToI2C[5] = 3;
      if (power_conf == 1) {    //    Power_conf = 1 ==> Full power configuration (without canton management by Nano
        dataToI2C[6] = 0;
      }
      else {    //    Power_conf = 0 ==> Canton power configuration (with canton management by Nano
        if (tCanton < 320) {                            //  Motor driver L298 A
          dataToI2C[6] = 1;
        } else if (tCanton >= 320 && tCanton < 330) {   //  Motor driver L298 B
          dataToI2C[6] = 2;
        } else if (tCanton >= 330 && tCanton < 340) {   //  Motor driver L298 C
          dataToI2C[6] = 3;
        } else if (tCanton >= 340) {                    //  Motor driver L298 D
          dataToI2C[6] = 4;
        }
      }
    }
    else if (tCanton > 400 && tCanton < 500) {   //  Track D et GH Nano 4
      addressI2CNano = addressI2CNano4;
      dataToI2C[1] = addressI2CNano4;
      dataToI2C[5] = 4;
      if (power_conf == 1) {    //    Power_conf = 1 ==> Full power configuration (without canton management by Nano
        dataToI2C[6] = 0;
      }
      else {    //    Power_conf = 0 ==> Canton power configuration (with canton management by Nano
        if (tCanton < 420) {   //  Motor driver L298 A - Track D and relays
          dataToI2C[6] = 1;
          dataToI2C[7] = tCanton - 410;
        } else {               //  Motor driver L298 B and GH relays
          dataToI2C[6] = 2;
          dataToI2C[7] = tCanton - 420;
        }
      }
    }
    else if (tCanton > 500 && tCanton < 600) {   //  Voie GB Nano 5
      addressI2CNano = addressI2CNano4;
      dataToI2C[1] = addressI2CNano4;
      dataToI2C[5] = 4;
      if (power_conf == 1) {    //    Power_conf = 1 ==> Full power configuration (without canton management by Nano
        dataToI2C[6] = 0;
      }
      else {    //    Power_conf = 0 ==> Canton power configuration (with canton management by Nano
        dataToI2C[6] = 3;
        dataToI2C[7] = tCanton - 510;   //  Motor driver L298 A and GB relays
      }
    }
    else {    //  Error => Emergency stop
      dataToI2C[3] = 0;
      dataToI2C[5] = 0;
    }
  }
  I2C_SendData(addressI2CNano, 10, dataToI2C); //Nanoaddress, Nb data to send, dataset

  INTERFACE.print("<NT");   //  Info for Processing
  for (int j = 0; j < 10; j++) {
    INTERFACE.print(dataToI2C[j]);
    INTERFACE.print(" ");
  }
  INTERFACE.print(">");

  delay(500);

  I2C_Current_sensor();   //  Waiting for current sensors feedback

} // I2C_Command::I2C_Throttle()

///////////////////////////////////////////////////////////////////////////////

void I2C_Command::I2C_Current_sensor() {
  int num;
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      I2CcurrentNano[i][j] = 0;
    }
  }

  //  Request sensor measures
  for (int i = 0; i < 5; i++) {
    dataToI2C[0] = '&';   //  Start of message key code = 38
    dataToI2C[1] = i + 1; //  Nano address <=> cab
    dataToI2C[2] = '2';   //  Current sensor request = '2' key code = 50
    dataToI2C[3] = '*';   //  End of message key code = 42
    I2C_SendData(addressI2CNano, 5, dataToI2C); //Nanoaddress, Nb data to send, dataset
  }
  //delay(100);
  //  Request current sensor results
  for (int i = 0; i < 4; i++) {
    //I2C_Command::I2C_Request(i, 10, dataFromI2C, lenghtDataI2C);   //  Nano address, nb bytes requested, data requested
    I2C_Request(i+1, 10, dataFromI2C, lenghtDataI2C);   //  Nano address, nb bytes requested, data requested
    for (int j = 0; j < 4; j++) {
      I2CcurrentNano[i][j] = dataFromI2C[j+3];
    }
  }
  /*
    INTERFACE.print("<NCu");
    for (int j = 0; j < 4; j++) {
      INTERFACE.print(I2CcurrentNano[1][j]);
      INTERFACE.print(" ");
    }
      INTERFACE.print(" > ");
  */
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      num = (j + 1) + (i * 4);
      if (I2CcurrentNano[i][j] < 80) {
        INTERFACE.print("<q");
        INTERFACE.print(num);
        INTERFACE.print(" ");
        INTERFACE.print(I2CcurrentNano[i][j]);
        INTERFACE.print(">");
      } else {
        INTERFACE.print("<Q");
        INTERFACE.print(num);
        INTERFACE.print(" ");
        INTERFACE.print(I2CcurrentNano[i][j]);
        INTERFACE.print(">");
      }
    }
  }
}

///////////////////////////////////////////////////////////////////////////////

void I2C_Command::I2C_SendData(int I2Cadr, int I2Clenght, byte I2Cdata[]) { //Nanoaddress, Nb data to considere, dataset
  Wire.beginTransmission(I2Cadr); // transmit to device #2
  Wire.write(I2Cdata, I2Clenght);  // sends one byte
  Wire.endTransmission();    // stop transmitting
  /*
    INTERFACE.print("<NBs");   //  Info for Processing
    for (int j = 0; j < I2Clenght; j++) {
      INTERFACE.print(I2Cdata[j]);
      INTERFACE.print(" ");
    }
    INTERFACE.print(">");
  */
}

///////////////////////////////////////////////////////////////////////////////

void I2C_Command::I2C_Request(int I2Cadr, int I2Clenght, byte I2Cdata[], int howMany) {   //  Nano address, nb bytes requested, data requested
  for (int i = 0; i < I2Clenght; ++i) {
    I2Cdata[i] = 0;
  }

  int i = 0;
  Wire.requestFrom(I2Cadr, I2Clenght);    // request data from Nano device
  while (Wire.available()) { // slave may send less than requested
    I2Cdata[i] = Wire.read();
    i = i + 1;
  }
}

///////////////////////////////////////////////////////////////////////////////
//  Define power configuration
//    Power_conf = 0 ==> Canton power configuration
//    Power_conf = 1 ==> Full power configuration (without canton management by Nano

void I2C_Command::I2C_Full_Power() {
  power_conf = 1;
}

///////////////////////////////////////////////////////////////////////////////

void I2C_Command::I2C_Canton_Power() {
  power_conf = 0;
}

///////////////////////////////////////////////////////////////////////////////
