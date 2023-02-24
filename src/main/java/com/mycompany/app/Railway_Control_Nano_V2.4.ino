//-------------------------------------------------------------------
//   Mega - Nano 2
//-------------------------------------------------------------------
//   Railway control project
//   Nano device management
//   Communication I2C with Mega
//   V.2.2.0.2022-11  EMA
//   This program has two communication ways :
//    one with Mega with I2C protocol to receive Mega request and send information
//    one with PC Processing with Serial protocol to debug the I2C communication
//
//    At init it sends an ASCII Y on serial startup and repeats that until it gets some data in.
//    Then it waits for a byte in the serial port, and execute the order from Processing
//-------------------------------------------------------------------

void(* resetFunc) (void) = 0; // RESET FUNCTION

//////////////////////////////////////////////////////////////////////////
//  Library
#include <SoftwareSerial.h>   //  Used during debug phase
#include <Wire.h>
#include "ACS712.h"

//////////////////////////////////////////////////////////////////////////
// PINS DEFINTION

// Motor Driver pins
#define L298_ENA 9     // MOTOR-DRIVER L298 A
#define L298_INA1 4
#define L298_INA2 2
#define L298_ENB 10    // MOTOR-DRIVER L298 B
#define L298_INB1 6
#define L298_INB2 5
#define L298_ENC 3     // MOTOR-DRIVER L298 C
#define L298_INC1 A1
#define L298_INC2 A0
#define L298_END 11    // MOTOR-DRIVER L298 D
#define L298_IND1 8
#define L298_IND2 7

// ACS712 Current sensors (Analog pin, Alimentation volt, Range, Resolution
//    Resolution
//      Sensor type 5A => mVperA = 185
//      Sensor type 20A => mVperA = 100
//
//    ACS712 DC CURRENT MEASUREMENT FORMULA
//      Current = (AcsOffset – (Arduino measured analog reading)) / Sensitivity
//        •  AcsOffset is normal voltage output at Viout pin when no current
//            is flowing through the circuit.
//        •  Arduino measured analog reading is the analog signal value read
//            and converted to actual voltage from the analog channel to which
//            ACS712 output is connected.
//        •  Sensitivity is Acs712 change in current representing 1 Ampere.
//
ACS712  ACS0(A2, 5.0, 1023, 185);     // MOTOR-DRIVER L298 A
ACS712  ACS1(A3, 5.0, 1023, 185);     // MOTOR-DRIVER L298 B
ACS712  ACS2(A6, 5.0, 1023, 185);     // MOTOR-DRIVER L298 C
ACS712  ACS3(A7, 5.0, 1023, 185);     // MOTOR-DRIVER L298 D
#define CurrentSamples 10     //Number of samples for current measure

// External led pins
#define EXT_LED 12

//////////////////////////////////////////////////////////////////////////
// VARIABLES

//  Motor Driver power
int periodMotor = 1000;

//  Init direction
int INA_Dir = 0;
int INB_Dir = 0;
int INC_Dir = 0;
int IND_Dir = 0;

//    Init speed
int INA_Cur = 0;
int INB_Cur = 0;
int INC_Cur = 0;
int IND_Cur = 0;

// Led Blink
int currentLed;
int timeLed = 10;
int periodLed = 1000;

//  Serial communication
int inByte;         // incoming serial byte

// I2C
int addressI2CMega = 0;
int addressI2CNano = 3;
byte dataToI2C[20];
byte dataFromI2C[20];
int lenghtDataI2C;

//////////////////////////////////////////////////////////////////////////
void setup() {

  // Initialize I2C buffers
  for (int i = 0; i < 20; i = i + 1) { //  Init the buffers
    dataFromI2C[i] = 0;
    dataToI2C[i] = 0;
  }

  // Initialize serial communication for debug phase
  Serial.begin(19200);  // Start serial communication at BASE_BAUD bps
  establishContact();   //  Used during debug phase

  // Initialize I2C communication
  Wire.begin(addressI2CNano);    // join I2C bus as Nano address
  Wire.onReceive(receiveI2C);   // check for, and process, and new I2C commands
  Wire.onRequest(requestI2C);   // Nano synchronisation with Mega

  // Init Input / Output pins
  pinMode(LED_BUILTIN, OUTPUT);    // LED_BUILTIN is on digital pin 13
  pinMode(EXT_LED, OUTPUT);    // EXT_LED as PWM is on digital pin 12

  //  Initializing Current Sensor
  ACS0.autoMidPoint();
  ACS1.autoMidPoint();
  ACS2.autoMidPoint();
  ACS3.autoMidPoint();

  // Initializing Motor-Driver
  pinMode(L298_ENA, OUTPUT);
  pinMode(L298_INA1, OUTPUT);
  pinMode(L298_INA2, OUTPUT);
  pinMode(L298_ENB, OUTPUT);
  pinMode(L298_INB1, OUTPUT);
  pinMode(L298_INB2, OUTPUT);
  pinMode(L298_ENC, OUTPUT);
  pinMode(L298_INC1, OUTPUT);
  pinMode(L298_INC2, OUTPUT);
  pinMode(L298_END, OUTPUT);
  pinMode(L298_IND1, OUTPUT);
  pinMode(L298_IND2, OUTPUT);

  // Set default direction to FORWARD
  digitalWrite(L298_INA1, LOW);    //  INA_Dir = 0
  digitalWrite(L298_INA2, HIGH);
  digitalWrite(L298_INB1, LOW);    //  INB_Dir = 0
  digitalWrite(L298_INB2, HIGH);
  digitalWrite(L298_INC1, LOW);
  digitalWrite(L298_INC2, HIGH);
  digitalWrite(L298_IND1, LOW);
  digitalWrite(L298_IND2, HIGH);

  //  Set default led
  digitalWrite(LED_BUILTIN, LOW);
  digitalWrite(EXT_LED, LOW);

  //  Set default speed to 0
  //motorDown(L298_ENA, 10, 0);    //  The speed must decrease to 0 before change the direction
  //motorDown(L298_ENB, 10, 0);    //  The speed must decrease to 0 before change the direction
  //motorDown(L298_ENC, 10, 0);    //  The speed must decrease to 0 before change the direction
  //motorDown(L298_END, 10, 0);    //  The speed must decrease to 0 before change the direction

}

//////////////////////////////////////////////////////////////////////////
void loop() {
  Serial_Command();              // check for, and process, and new serial commands
  digitalWrite(LED_BUILTIN, LOW);
}

//////////////////////////////////////////////////////////////////////////
void Command_Switch() {

  switch (dataFromI2C[2]) {
    //  Motor driver management
    case '1':   //  dataFromI2C[2] = '1' key code = 49
      if (dataFromI2C[5] == 0) {    //  All speed cab must be to 0
        motorDown(L298_ENA, INA_Cur, 0);    //  The speed must decrease to 0 before change the direction
        motorDown(L298_ENB, INB_Cur, 0);    //  The speed must decrease to 0 before change the direction
        motorDown(L298_ENC, INC_Cur, 0);    //  The speed must decrease to 0 before change the direction
        motorDown(L298_END, IND_Cur, 0);    //  The speed must decrease to 0 before change the direction
        INA_Cur = 0;
        INB_Cur = 0;
        INC_Cur = 0;
        IND_Cur = 0;

      } else {    //  dataFromI2C[5] != 0
        switch (dataFromI2C[6]) {    //  Canton number
          //  Nota : when a canton has been selected, the direction must be checked.
          //    If direction is different, the motor must be down to speed 0 before change the
          //      direction. Then the motor could be up to the required speed.
          //    In add, the next canton must be update with the same speed in order to
          //      have the continuity when the loco change from canton selected to the next.
          //    And the previous canton speed must be down to 0
          //
          case 0:   //  dataFromI2C[6] = 0 Select all L298_INB Canton
            /*
              if (dataFromI2C[3] > INA_Cur || dataFromI2C[3] > INB_Cur || dataFromI2C[3] > INC_Cur || dataFromI2C[3] > IND_Cur) {   //  Required speed > current speed
              motorUp(L298_ENA, INA_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              motorUp(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              motorUp(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              motorUp(L298_END, IND_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
              motorDown(L298_ENA, INA_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              motorDown(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              motorDown(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              motorDown(L298_END, IND_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              INA_Cur = dataFromI2C[3];
              INB_Cur = dataFromI2C[3];
              INC_Cur = dataFromI2C[3];
              IND_Cur = dataFromI2C[3];
            */
            break;

          case 1:   //  dataFromI2C[6] = 1 Select L298_INB Canton 10 to 19
            //Serial.println(" 11B");         //  Used during debug phase
            if (dataFromI2C[4] != INB_Dir) {    //  the direction must be change, so the speed must be O
              if (INB_Cur != 0) {               //    and the current speed is different to 0
                motorDown(L298_ENB, INB_Cur, 0);    //  The speed must decrease to 0 before change the direction
              }
              //  Change the direction of selected canton
              switch (dataFromI2C[4]) {    //  Direction change
                case 0:   //  Forward
                  digitalWrite(L298_INB1, LOW);
                  digitalWrite(L298_INB2, HIGH);
                  INB_Dir = 0;
                  break;
                case 1:   //  Backward
                  digitalWrite(L298_INB1, HIGH);
                  digitalWrite(L298_INB2, LOW);
                  INB_Dir = 1;
                  break;
              }
            }
            if (dataFromI2C[3] > INB_Cur) {   //  Required speed > current speed
              motorUp(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
            } else {                         //  Required speed < current speed
              motorDown(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
            }
            INB_Cur = dataFromI2C[3];
            //Serial.println(" 11B end");     //  Used during debug phase
            //  Select the next canton in function of required direction
            if (dataFromI2C[4] == 1) {      //  the next canton is L298-A and the previous is L298-D
              //Serial.println(" 11A");         //  Used during debug phase
              if (dataFromI2C[4] != INA_Dir) {    //  the direction must be change, so the speed must be O
                if (INA_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_ENA, INA_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_INA1, LOW);
                    digitalWrite(L298_INA2, HIGH);
                    INA_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_INA1, HIGH);
                    digitalWrite(L298_INA2, LOW);
                    INA_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > INA_Cur) {   //  Required speed > current speed
                motorUp(L298_ENA, INA_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_ENA, INA_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              INA_Cur = dataFromI2C[3];
              //Serial.println(" 11A end");     //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_END, IND_Cur, 0);
              IND_Cur = 0;
              //Serial.println(" 11D to 0");    //  Used during debug phase
            } else {    //  the next canton is L298-D and the previous is L298-B
              //Serial.println(" 11D");         //  Used during debug phase
              if (dataFromI2C[4] != IND_Dir) {    //  the direction must be change, so the speed must be O
                if (IND_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_END, IND_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_IND1, LOW);
                    digitalWrite(L298_IND2, HIGH);
                    IND_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_IND1, HIGH);
                    digitalWrite(L298_IND2, LOW);
                    IND_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > IND_Cur) {   //  Required speed > current speed
                motorUp(L298_END, IND_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_END, IND_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              IND_Cur = dataFromI2C[3];
              //Serial.println(" 11D end");     //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_ENA, INA_Cur, 0);
              INA_Cur = 0;
              //Serial.println(" 11A to 0");    //  Used during debug phase
            }
            break;

          case 2:   //  dataFromI2C[6] = 2 L298_INA Canton 20 to 29
            //Serial.println(" 12A");         //  Used during debug phase
            if (dataFromI2C[4] != INA_Dir) {    //  the direction must be change, so the speed must be O
              if (INA_Cur != 0) {               //    and the current speed is different to 0
                motorDown(L298_ENA, INA_Cur, 0);    //  The speed must decrease to 0 before change the direction
              }
              //  Change the direction of selected canton
              switch (dataFromI2C[4]) {    //  Direction change
                case 0:   //  Forward
                  digitalWrite(L298_INA1, LOW);
                  digitalWrite(L298_INA2, HIGH);
                  INA_Dir = 0;
                  break;
                case 1:   //  Backward
                  digitalWrite(L298_INA1, HIGH);
                  digitalWrite(L298_INA2, LOW);
                  INA_Dir = 1;
                  break;
              }
            }
            if (dataFromI2C[3] > INA_Cur) {   //  Required speed > current speed
              motorUp(L298_ENA, INA_Cur, dataFromI2C[3]);    //  The range of Motor drive is [0 , 256]
            } else {                         //  Required speed < current speed
              motorDown(L298_ENA, INA_Cur, dataFromI2C[3]);    //  The range of Motor drive is [0 , 256]
            }
            INA_Cur = dataFromI2C[3];
            //Serial.println(" 12A end");     //  Used during debug phase
            //  Select the next canton in function of required direction
            if (dataFromI2C[4] == 1) {      //  the next canton is L298-C and the previous is L298-B
              //Serial.println(" 12C");         //  Used during debug phase
              if (dataFromI2C[4] != INC_Dir) {    //  the direction must be change, so the speed must be O
                if (INC_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_ENC, INC_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_INC1, LOW);
                    digitalWrite(L298_INC2, HIGH);
                    INC_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_INC1, HIGH);
                    digitalWrite(L298_INC2, LOW);
                    INC_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > INC_Cur) {   //  Required speed > current speed
                motorUp(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              INC_Cur = dataFromI2C[3];
              //Serial.println(" 12C end");     //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_ENB, INB_Cur, 0);
              INB_Cur = 0;
              //Serial.println(" 12B to 0");    //  Used during debug phase
            } else {    //  the next canton is L298-B and the previous is L298-C
              //Serial.println(" 12B");         //  Used during debug phase
              if (dataFromI2C[4] != INB_Dir) {    //  the direction must be change, so the speed must be O
                if (INB_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_ENB, INB_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_INB1, LOW);
                    digitalWrite(L298_INB2, HIGH);
                    INB_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_INB1, HIGH);
                    digitalWrite(L298_INB2, LOW);
                    INB_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > INB_Cur) {   //  Required speed > current speed
                motorUp(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              INB_Cur = dataFromI2C[3];
              //Serial.println(" 12B end");     //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_ENC, INC_Cur, 0);
              INC_Cur = 0;
              //Serial.println(" 12C to 0");    //  Used during debug phase
            }
            break;

          case 3:   //  dataFromI2C[6] = 3 L298_INC Canton 30 to 39
            //Serial.println(" 13C");         //  Used during debug phase
            if (dataFromI2C[4] != INC_Dir) {    //  the direction must be change, so the speed must be O
              if (INC_Cur != 0) {               //    and the current speed is different to 0
                motorDown(L298_ENC, INC_Cur, 0);    //  The speed must decrease to 0 before change the direction
              }
              switch (dataFromI2C[4]) {    //  Direction change
                case 0:   //  Forward
                  digitalWrite(L298_INC1, LOW);
                  digitalWrite(L298_INC2, HIGH);
                  INC_Dir = 0;
                  break;
                case 1:   //  Backward
                  digitalWrite(L298_INC1, HIGH);
                  digitalWrite(L298_INC2, LOW);
                  INC_Dir = 1;
                  break;
              }
            }
            if (dataFromI2C[3] > INC_Cur) { //  Required speed > current speed
              motorUp(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
            } else {                         //  Required speed < current speed
              motorDown(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
            }
            INC_Cur = dataFromI2C[3];
            //Serial.println(" 13C end");     //  Used during debug phase
            //  Select the next canton in function of required direction
            if (dataFromI2C[4] == 1) {    //  the next canton is L298-D and the previous is L298-A
              //Serial.println(" 13D");         //  Used during debug phase
              if (dataFromI2C[4] != IND_Dir) {    //  the direction must be change, so the speed must be O
                if (IND_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_END, IND_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_IND1, LOW);
                    digitalWrite(L298_IND2, HIGH);
                    IND_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_IND1, HIGH);
                    digitalWrite(L298_IND2, LOW);
                    IND_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > IND_Cur) {   //  Required speed > current speed
                motorUp(L298_END, IND_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_END, IND_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              IND_Cur = dataFromI2C[3];
              //Serial.println(" 13D end");    //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_ENA, INA_Cur, 0);
              INA_Cur = 0;
              //Serial.println(" 13A to 0");    //  Used during debug phase
            } else {    //  the next canton is L298-A and the previous is L298-D
              //Serial.println(" 13A");         //  Used during debug phase
              if (dataFromI2C[4] != INA_Dir) {    //  the direction must be change, so the speed must be O
                if (INA_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_ENA, INA_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_INA1, LOW);
                    digitalWrite(L298_INA2, HIGH);
                    INA_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_INA1, HIGH);
                    digitalWrite(L298_INA2, LOW);
                    INA_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > INA_Cur) {   //  Required speed > current speed
                motorUp(L298_ENA, INA_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_ENA, INA_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              INA_Cur = dataFromI2C[3];
              //Serial.println(" 13A end");     //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_END, IND_Cur, 0);
              IND_Cur = 0;
              //Serial.println(" 13D to 0");    //  Used during debug phase
            }
            break;

          case 4:   //  dataFromI2C[6] = 4 L298_IND Canton 40 to 49
            //Serial.println(" 14D");         //  Used during debug phase
            if (dataFromI2C[4] != IND_Dir) {    //  the direction must be change, so the speed must be O
              if (IND_Cur != 0) {               //    and the current speed is different to 0
                motorDown(L298_END, IND_Cur, 0);    //  The speed must decrease to 0 before change the direction
              }
              switch (dataFromI2C[4]) {    //  Direction change
                case 0:   //  Forward
                  digitalWrite(L298_IND1, LOW);
                  digitalWrite(L298_IND2, HIGH);
                  IND_Dir = 0;
                  break;
                case 1:   //  Backward
                  digitalWrite(L298_IND1, HIGH);
                  digitalWrite(L298_IND2, LOW);
                  IND_Dir = 1;
                  break;
              }
            }
            if (dataFromI2C[3] > IND_Cur) {   //  Required speed > current speed
              motorUp(L298_END, IND_Cur, dataFromI2C[3]);    //  The range of Motor drive is [0 , 256]
            } else {                         //  Required speed < current speed
              motorDown(L298_END, IND_Cur, dataFromI2C[3]);    //  The range of Motor drive is [0 , 256]
            }
            IND_Cur = dataFromI2C[3];
            //Serial.println(" 14D end");     //  Used during debug phase
            //  Select the next canton in function of required direction
            if (dataFromI2C[4] == 1) {    //  the next canton is L298-B and the previous is L298-C
              //Serial.println(" 14B");         //  Used during debug phase
              if (dataFromI2C[4] != INB_Dir) {    //  the direction must be change, so the speed must be O
                if (INB_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_ENB, INB_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_INB1, LOW);
                    digitalWrite(L298_INB2, HIGH);
                    INB_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_INB1, HIGH);
                    digitalWrite(L298_INB2, LOW);
                    INB_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > INB_Cur) {   //  Required speed > current speed
                motorUp(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_ENB, INB_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              INB_Cur = dataFromI2C[3];
              //Serial.println(" 14B end");     //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_ENC, INC_Cur, 0);
              INC_Cur = 0;
              //Serial.println(" 14C to 0");    //  Used during debug phase
            } else {    //  the next canton is L298-C and the previous is L298-B
              //Serial.println(" 14C");         //  Used during debug phase
              if (dataFromI2C[4] != INC_Dir) {    //  the direction must be change, so the speed must be O
                if (INC_Cur != 0) {               //    and the current speed is different to 0
                  motorDown(L298_ENC, INC_Cur, 0);    //  The speed must decrease to 0 before change the direction
                }
                //  Change the direction of next canton
                switch (dataFromI2C[4]) {    //  Direction change
                  case 0:   //  Forward
                    digitalWrite(L298_INC1, LOW);
                    digitalWrite(L298_INC2, HIGH);
                    INC_Dir = 0;
                    break;
                  case 1:   //  Backward
                    digitalWrite(L298_INC1, HIGH);
                    digitalWrite(L298_INC2, LOW);
                    INC_Dir = 1;
                    break;
                }
              }
              if (dataFromI2C[3] > INC_Cur) {   //  Required speed > current speed
                motorUp(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              } else {                         //  Required speed < current speed
                motorDown(L298_ENC, INC_Cur, dataFromI2C[3]);  //  The range of Motor drive is [0 , 256]
              }
              INC_Cur = dataFromI2C[3];
              //Serial.println(" 14C end");     //  Used during debug phase
              //  The previous canton speed must be down to 0
              motorDown(L298_ENB, INB_Cur, 0);
              INB_Cur = 0;
              //Serial.println(" 14B to 0");    //  Used during debug phase
            }
            break;

          default:   //  dataFromI2C[2]
            break;
        }
      }
      break;

    //  Current sensor request
    case '2':   //  dataFromI2C[2] = '2' key code = 50
      //led_blink(LED_BUILTIN, periodLed / 4, timeLed);
      Sensor_Reading();
      //Serial.println(" sensor");    //  Used during debug phase
      break;

    case '3':   //  dataFromI2C[2] = '3' key code = 51
      led_blink(LED_BUILTIN, periodLed / 6, timeLed);
      break;

    case '4':   //  dataFromI2C[2] = '4' key code = 52
      led_blink(LED_BUILTIN, periodLed, 2);
      break;

    case '5':   //  dataFromI2C[2] = '5' key code = 53
      break;

    default:   //  dataFromI2C[2]
      break;
  }
}

//////////////////////////////////////////////////////////////////////////
// FUNCTIONS
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
//  Used during debug phase
void establishContact() {     //  Needed to init serial communication
  if (Serial.available() <= 0) {
    Serial.println ('Y');   // send an ASCII Y to establish contact until Processing responds
    delay(300);
  }
}

//////////////////////////////////////////////////////////////////////////
void Serial_Command() {
  int data;
  lenghtDataI2C = 0;
  delay(100);
  while (Serial.available() > 0) { // while there is data on the serial line
    data = Serial.read();
    if (data == '&') {    // start of new command
      data = Serial.read();
      if (data == addressI2CNano) {   // Command for this Nano ?
        for (int i = 0; i < 20; ++i) {
          dataFromI2C[i] = 0;   // I2C Received buffer reinit
        }
        dataFromI2C[0] = '&';
        dataFromI2C[1] = addressI2CNano;
        lenghtDataI2C = 2;
      }
    } else {
      /*        if (data == '*') {           // end of new command
                Command_Switch();
              } else {
                dataFromI2C[lenghtDataI2C] = data;
                lenghtDataI2C = lenghtDataI2C + 1;
              }
      */
      while (data = !'*') {
        dataFromI2C[lenghtDataI2C] = data;
        lenghtDataI2C = lenghtDataI2C + 1;
      }
    }
  }
}  // Serial_Command

//////////////////////////////////////////////////////////////////////////
void receiveI2C(int howMany) {
  byte data;
  lenghtDataI2C = 0;
  while (Wire.available() > 0) {
    data = Wire.read();
    if (data == '&') {    // start of new command
      data = Wire.read();
      if (data == addressI2CNano) {   // Command for this Nano ?
        for (int i = 0; i < 20; ++i) {
          dataFromI2C[i] = 0;   // I2C Received buffer reinit
        }
        dataFromI2C[0] = '&';
        dataFromI2C[1] = addressI2CNano;
        lenghtDataI2C = 2;
      }
    } else {
      if (data == '*') {           // end of new command
        Command_Switch();
      } else {
        dataFromI2C[lenghtDataI2C] = data;
        lenghtDataI2C = lenghtDataI2C + 1;
      }
    }
  }
}  // receiveI2C

//////////////////////////////////////////////////////////////////////////
void requestI2C() {
  Wire.write(dataToI2C, 10); // respond with message of 10 bytes
  /*
    for (int i = 0; i < 10; i = i + 1) {
      Serial.print(dataToI2C[i]);
    }
    Serial.println();
  */
}

//////////////////////////////////////////////////////////////////////////
void led_blink(int currentLed, int currentPeriod, int currentTime) {
  for (int j = 0; j <= currentTime; j = j + 1) {
    digitalWrite(currentLed, HIGH);  // turn the LED on (HIGH is the voltage level)
    delay (currentPeriod);                    // wait for a 0.5 second
    digitalWrite(currentLed, LOW);   // turn the LED off by making the voltage LOW
    delay (currentPeriod);                    // wait for a 0.5 second
  }
}

//////////////////////////////////////////////////////////////////////////
void motorUp(int L298, int CurPower, int NewPower) {
  for (int j = CurPower; j <= NewPower; j = j + 10) {
    //analogWrite(EXT_LED, j);         //  Led
    analogWrite(L298, j);   //  Motor
    delay(periodMotor);
  }
}

//////////////////////////////////////////////////////////////////////////
void motorDown(int L298, int CurPower, int NewPower) {
  for (int j = CurPower; j >= NewPower; j = j - 10) {
    //analogWrite(EXT_LED, j);         //  Led
    analogWrite(L298, j);   //  Motor
    delay(periodMotor);
  }
}

//////////////////////////////////////////////////////////////////////////
void Sensor_Reading() {    //  Current sensors reading
  for (int i = 0; i < 19; i = i + 1) {
    dataToI2C[i] = 0;  // I2C sender buffer init
  }
  dataToI2C[19] = '*';   //  End of message key code = 42

  float mA0 = ACS0.mA_DC();
  float mA1 = ACS1.mA_DC();
  float mA2 = ACS2.mA_DC();
  float mA3 = ACS3.mA_DC();

  dataToI2C[0] = '#';   //  Start of message key code = 35
  dataToI2C[1] = addressI2CNano;
  dataToI2C[2] = '2';   //  Current sensor management = '2' key code = 50

  /*
    dataToI2C[3] = mA0;
    dataToI2C[4] = mA1;
    dataToI2C[5] = mA2;
    dataToI2C[6] = mA3;

    dataToI2C[3] = 98;
    dataToI2C[4] = 7.6;
    dataToI2C[5] = -54;
    dataToI2C[6] = -3.2;
  */
  dataToI2C[3] = 10;
  dataToI2C[4] = 20;
  dataToI2C[5] = 30;
  dataToI2C[6] = 40;

  dataToI2C[7] = '*';   //  End of message key code = 42
}

/*
  //////////////////////////////////////////////////////////////////////////
  void Sensor_Reading() {    //  Current sensors reading
  for (int i = 0; i < 19; i = i + 1) {
    dataToI2C[i] = 0;  // I2C sender buffer init
  }
  dataToI2C[19] = '*';   //  End of message key code = 42

  float AcsValue = 0.0;
  float Samples = 0.0;
  float AvgAcs = 0.0;
  //float AcsValueF = 0.0;
  float mA0 = 0.0;
  float mA1 = 0.0;
  float mA2 = 0.0;
  float mA3 = 0.0;

  for (int x = 0; x < 150; x++) { //Get 150 samples
    AcsValue = analogRead(A0);     //Read current sensor values
    Samples = Samples + AcsValue;  //Add samples together
    delay (3); // let ADC settle before next sample 3ms
  }
  AvgAcs = Samples / 150.0; //Taking Average of Samples

  //((AvgAcs * (5.0 / 1024.0)) is converitng the read voltage in 0-5 volts
  //2.5 is offset(I assumed that arduino is working on 5v so the viout at no current comes
  //out to be 2.5 which is out offset. If your arduino is working on different voltage than
  //you must change the offset according to the input voltage)
  //0.185v(185mV) is rise in output voltage when 1A current flows at input
  mA0 = (2.5 - (AvgAcs * (5.0 / 1024.0)) ) / 0.185;

  for (int x = 0; x < 150; x++) { //Get 150 samples
    AcsValue = analogRead(A0);     //Read current sensor values
    Samples = Samples + AcsValue;  //Add samples together
    delay (3); // let ADC settle before next sample 3ms
  }
  AvgAcs = Samples / 150.0; //Taking Average of Samples
  mA1 = (2.5 - (AvgAcs * (5.0 / 1024.0)) ) / 0.185;

  for (int x = 0; x < 150; x++) { //Get 150 samples
    AcsValue = analogRead(A0);     //Read current sensor values
    Samples = Samples + AcsValue;  //Add samples together
    delay (3); // let ADC settle before next sample 3ms
  }
  AvgAcs = Samples / 150.0; //Taking Average of Samples
  mA2 = (2.5 - (AvgAcs * (5.0 / 1024.0)) ) / 0.185;

  for (int x = 0; x < 150; x++) { //Get 150 samples
    AcsValue = analogRead(A0);     //Read current sensor values
    Samples = Samples + AcsValue;  //Add samples together
    delay (3); // let ADC settle before next sample 3ms
  }
  AvgAcs = Samples / 150.0; //Taking Average of Samples
  mA3 = (2.5 - (AvgAcs * (5.0 / 1024.0)) ) / 0.185;

  dataToI2C[0] = '#';   //  Start of message key code = 35
  dataToI2C[1] = addressI2CNano;
  dataToI2C[2] = '2';   //  Current sensor management = '2' key code = 50
  dataToI2C[3] = byte(mA0);
  dataToI2C[4] = byte(mA1);
  dataToI2C[5] = byte(mA2);
  dataToI2C[6] = byte(mA3);
  dataToI2C[7] = '*';   //  End of message key code = 42
  }
*/
