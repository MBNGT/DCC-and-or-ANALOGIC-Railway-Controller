/**********************************************************************

  I2C_Command.h
  COPYRIGHT (c) 2022 EMA

  Part of Railway_Control Base Station for the Arduino

**********************************************************************/

#ifndef I2C_Command_h
#define I2C_Command_h

#include "Arduino.h"

struct I2C_CommandData {

};

struct I2C_Command {
  //static I2C_Command *i2c_Command;
  struct I2C_CommandData data;
  static void I2C_Scan(int);
  static void I2C_Throttle(char *);
  static void I2C_Current_sensor();
  static void I2C_SendData(int, int, byte[]) ;
  static void I2C_Request(int, int, byte[], int);
  static void I2C_Full_Power();
  static void I2C_Canton_Power();

}; // I2C_Command

#endif
