//////////////////////////////////////////////////////////////////////////
//  PROCESSING RAILWAY CONTROLLER: Programming Components
//      Sheet : progComponents
//
//  All classes and methods related to programming mobile decoder
//  configuration variables (CVs)
////                          
//  ProgWriteReadButton  -  sends a DCC PROGRAMMING COMMAND to the Base Station
//                          that either reads from, or writes to, a user-specified CV in a mobile
//                          decoder on the Programming Track
//                       -  Note: cab numbers (mobile decoder addresses) are not used on the Programming
//                          Track. Whatever locomotive is on the track will be programmed!
//                       -  users specify the CV to be written or read via an input box
//                       -  in the case of writing to a CV, three linked input boxes allow the user to
//                          specify the byte in either HEX, DECIMAL, or BINARY formats
//                       -  in the case of reading from a CV, these three linked input boxes are updated
//                          to display the results of the read in HEX, DECIMAL, and BINARY formats
//                       -  in the case of writing to a CV, the Base Station automatically performs an
//                          subsequent read to verify the byte was properly written
//
//  ProgAddReadButton    - sends a series of DCC PROGRAMMING COMMANDS to the Base Station
//                         that reads the following CVs from a mobile decoder on the Programming Track:
//
//                         * CV #1  - contains the short (single byte) cab address
//                         * CV #17 - contains the high byte of a long (two byte) cab address
//                         * CV #18 - contains the low byte of a long (two byte) cab address
//                         * CV #29 - bit 5 indicates whether mobile decoder is using long or short cab address
//
//                      -  CV #17 and CV #18 are combined into a single cab address
//                      -  three input boxes display the results of the short address, the long address,
//                      -  and whether of not the mobile decoder is using the long or short cab address
//
//  ProgShortAddWriteButton  -  sends a DCC PROGRAMMING COMMAND to the Base Station
//                              that writes the short cab address specified in the first input box described above
//                              to a mobile decoder on the Programming Track
//
//  ProgLongAddWriteButton   -  sends a DCC PROGRAMMING COMMAND to the Base Station
//                              that writes the long cab address specified in the second input box described above
//                              to a mobile decoder on the Programming Track
//
//  ProgLongShortButton      -  sends a DCC PROGRAMMING COMMAND to the Base Station
//                              that indicates whether the mobile decoder on the Programming Track should use its
//                              short cab address or long cab address
//
//  The default configuration of PROCESSING RAILWAY CONTROLLER defines a Programming Window that includes all of the above components
//
//
//  OpWriteButton  - sends a DCC PROGRAMMING COMMAND to the Base Station that writes a user-specified byte
//                   or sets/clears a user-specified bit in a user-specified CV of a mobile decoder with a
//                   user-specified cab address on the Main Operations Track
//                 - uses one input box for specifiying the cab address and one for the CV
//                 - when writing a full byte, uses 3 linked boxes for specifying the value in
//                   either HEX, DECIMAL, or BINARY format
//                 - when setting/clearing a bit, uses on input box to specify the bit number
//                 - the default configuration of PROCESSING RAILWAY CONTROLLER defines an Operation Programming Window that
//                   includes all of these components

//////////////////////////////////////////////////////////////////////////
//  Class ProgWriteReadButton
//////////////////////////////////////////////////////////////////////////

class ProgWriteReadButton extends EllipseButton implements CallBack {
  InputBox progCVInput, progValueInput;

  ProgWriteReadButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox progCVInput, InputBox progValueInput) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, progCVInput, progValueInput);
  }

  ProgWriteReadButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox progCVInput, InputBox progValueInput) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.progCVInput=progCVInput;
    this.progValueInput=progValueInput;
    callBacks.add(this);
  } // ProgrWriteReadButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();
    int cv=progCVInput.getIntValue();
    int val=progValueInput.getIntValue();
    if (cv<1 || cv>1024) {
      msgBoxMain.setMessage("Error - CV must be in range 1-1024", color(255, 30, 30));
    } else if (bText=="WRITE") {
      aPort.write("<W"+cv+" "+val+" "+callBacks.indexOf(this)+" 1>");    //***** WRITE CONFIGURATION VARIABLE BYTE TO ENGINE DECODER ON PROGRAMMING TRACK  ****/    
      /*    case 'W':      // <W CV VALUE CALLBACKNUM CALLBACKSUB>
       *    writes, and then verifies, a Configuration Variable to the decoder of an engine on the programming 
       track
       *    CV: the number of the Configuration Variable memory location in the decoder to write to (1-1024)
       *    VALUE: the value to be written to the Configuration Variable memory location (0-255) 
       *    CALLBACKNUM: an arbitrary integer (0-32767) that is ignored by the Base Station and is simply echoed 
       back in the output - useful for external programs that call this function
       *    CALLBACKSUB: a second arbitrary integer (0-32767) that is ignored by the Base Station and is simply 
       echoed back in the output - useful for external programs (e.g. DCC++ Interface) that call this 
       function
       *    returns: <r CALLBACKNUM|CALLBACKSUB|CV Value)
       *    where VALUE is a number from 0-255 as read from the requested CV, or -1 if verificaiton read fails
       */
    } else if (bText=="READ") {
      aPort.write("<R"+cv+" "+callBacks.indexOf(this)+" 0>");    //***** READ CONFIGURATION VARIABLE BYTE FROM ENGINE DECODER ON PROGRAMMING TRACK  ****/    
      /*    case 'R':     // <R CV CALLBACKNUM CALLBACKSUB>
       *    reads a Configuration Variable from the decoder of an engine on the programming track
       *    CV: the number of the Configuration Variable memory location in the decoder to read from (1-1024)
       *    CALLBACKNUM: an arbitrary integer (0-32767) that is ignored by the Base Station and is simply echoed 
       back in the output - useful for external programs that call this function
       *    CALLBACKSUB: a second arbitrary integer (0-32767) that is ignored by the Base Station and is simply 
       echoed back in the output - useful for external programs (e.g. DCC++ Interface) that call this 
       function
       *    returns: <r CALLBACKNUM|CALLBACKSUB|CV VALUE)
       *    where VALUE is a number from 0-255 as read from the requested CV, or -1 if read could not be verified
       */
    }
  }  //  ProgWriteReadButton pressed

  //////////////////////////////////////////////////////////////////////////

  void execute(int n, String c) {
    String[] cs = splitTokens(c);

    int cv=int(cs[0]);
    int val=int(cs[1]);

    progCVInput.setIntValue(cv);

    if (val<0) {
      msgBoxMain.setMessage(n==0?"Error - Read Failed":"Error - Write Failed", color(255, 30, 30));
      progHEXInput.resetValue();
      progBINInput.resetValue();
      progDECInput.resetValue();
    } else {
      msgBoxMain.setMessage(n==0?"Read Succeeded":"Write Succeeded", color(30, 150, 30));
      progHEXInput.setIntValue(val);
      progBINInput.setIntValue(val);
      progDECInput.setIntValue(val);
    }
  }  //  ProgWriteReadButton execute
} // progWriteReadButton Class

//////////////////////////////////////////////////////////////////////////
//  Class ProgAddReadButton
//////////////////////////////////////////////////////////////////////////

class ProgAddReadButton extends EllipseButton implements CallBack {
  InputBox shortAddInput, longAddInput;
  MessageBox activeAddBox;
  int longAdd;

  ProgAddReadButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox shortAddInput, InputBox longAddInput, MessageBox activeAddBox) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, shortAddInput, longAddInput, activeAddBox);
  }

  ProgAddReadButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox shortAddInput, InputBox longAddInput, MessageBox activeAddBox) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.shortAddInput=shortAddInput;
    this.longAddInput=longAddInput;
    this.activeAddBox=activeAddBox;
    callBacks.add(this);
  } // ProgAddReadButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();
    aPort.write("<R1 "+callBacks.indexOf(this)+" 0>");    //  ??????????????
  }  //  ProgAddReadButton pressed

  //////////////////////////////////////////////////////////////////////////

  void execute(int n, String c) {
    String[] cs = splitTokens(c);

    int cv=int(cs[0]);
    int val=int(cs[1]);

    switch(cv) {

    case 1:
      if (val<0) {
        msgBoxMain.setMessage("Error - Reading Short Address Failed", color(255, 30, 30));
        shortAddInput.resetValue();
      } else {
        shortAddInput.setIntValue(val);
        aPort.write("<R17 "+callBacks.indexOf(this)+" 0>");    //  ?????????
      }
      break;

    case 17:
      if (val<0) {
        msgBoxMain.setMessage("Error - Reading First Byte of Long Address Failed", color(255, 30, 30));
        longAddInput.resetValue();
      } else {
        longAdd=(val&0x3F)*256;
        aPort.write("<R18 "+callBacks.indexOf(this)+" 0>");
      }
      break;

    case 18:
      if (val<0) {
        msgBoxMain.setMessage("Error - Reading Second Byte of Long Address Failed", color(255, 30, 30));
        longAddInput.resetValue();
      } else {
        longAdd+=val;
        longAddInput.setIntValue(longAdd);
        aPort.write("<R29 "+callBacks.indexOf(this)+" 0>");
      }
      break;

    case 29:
      if (val<0) {
        msgBoxMain.setMessage("Error - Reading Second Byte of Long Address Failed", color(255, 30, 30));
        activeAddBox.setMessage("?", color(200, 50, 50));
      } else {
        if ((val&0x20)==0)
          activeAddBox.setMessage("SHORT", color(200, 50, 50));
        else
          activeAddBox.setMessage("LONG", color(200, 50, 50));
        msgBoxMain.setMessage("Reading Short and Long Addresses Succeeded", color(30, 150, 30));
      }
      break;
    }
  }  //  ProgAddReadButton execute
} // ProgAddReadButton Class

//////////////////////////////////////////////////////////////////////////
//  Class ProgShortAddWriteButton
//////////////////////////////////////////////////////////////////////////

class ProgShortAddWriteButton extends EllipseButton implements CallBack {
  InputBox addInput;

  ProgShortAddWriteButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox addInput) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, addInput);
  }

  ProgShortAddWriteButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox addInput) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.addInput=addInput;
    callBacks.add(this);
  } // ProgShortAddWriteButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();

    int val=addInput.getIntValue();

    if (val<1 || val>127) {
      msgBoxMain.setMessage("Error - Short Address must be in range 1-127", color(255, 30, 30));
    } else {
      aPort.write("<W1"+" "+val+" "+callBacks.indexOf(this)+" 0>");    //  ?????????
    }
  }  //  ProgShortAddWriteButton pressed

  //////////////////////////////////////////////////////////////////////////

  void execute(int n, String c) {
    String[] cs = splitTokens(c);

    int cv=int(cs[0]);
    int val=int(cs[1]);

    if (val<0) {
      msgBoxMain.setMessage("Error - Write Short Address Failed", color(255, 30, 30));
      addInput.resetValue();
    } else {
      msgBoxMain.setMessage("Write Short Address Succeeded", color(30, 150, 30));
      addInput.setIntValue(val);
    }
  }  //  ProgShortAddWriteButton execute
} // ProgShortAddWriteButton Class

//////////////////////////////////////////////////////////////////////////
//  Class ProgLongAddWriteButton
//////////////////////////////////////////////////////////////////////////

class ProgLongAddWriteButton extends EllipseButton implements CallBack {
  InputBox addInput;
  int longAddIn, longAddOut;

  ProgLongAddWriteButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox addInput) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, addInput);
  }

  ProgLongAddWriteButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox addInput) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.addInput=addInput;
    callBacks.add(this);
  } // ProgLongAddWriteButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();

    longAddIn=addInput.getIntValue();

    if (longAddIn<0 || longAddIn>10239) {
      msgBoxMain.setMessage("Error - Long Address must be in range 0-10239", color(255, 30, 30));
    } else {
      aPort.write("<W17"+" "+(longAddIn/256+192)+" "+callBacks.indexOf(this)+" 0>");    //  ?????
    }
  }  //  ProgLongAddWriteButton pressed

  //////////////////////////////////////////////////////////////////////////

  void execute(int n, String c) {
    String[] cs = splitTokens(c);

    int cv=int(cs[0]);
    int val=int(cs[1]);

    switch(cv) {

    case 17:
      if (val<0) {
        msgBoxMain.setMessage("Error - Writing First Byte of Long Address Failed", color(255, 30, 30));
        addInput.resetValue();
      } else {
        longAddOut=(val&0x3F)*256;
        aPort.write("<W18"+" "+(longAddIn%256)+" "+callBacks.indexOf(this)+" 0>");
      }
      break;

    case 18:
      if (val<0) {
        msgBoxMain.setMessage("Error - Writing Second Byte of Long Address Failed", color(255, 30, 30));
        addInput.resetValue();
      } else {
        msgBoxMain.setMessage("Write Long Address Succeeded", color(30, 150, 30));
        longAddOut+=val;
        addInput.setIntValue(longAddOut);
      }
      break;
    }
  }  //  ProgLongAddWriteButton execute
} // ProgLongAddWriteButton Class

//////////////////////////////////////////////////////////////////////////
//  Class ProgLongShortButton
//////////////////////////////////////////////////////////////////////////

class ProgLongShortButton extends EllipseButton implements CallBack {
  MessageBox activeAddBox;

  ProgLongShortButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, MessageBox activeAddBox) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, activeAddBox);
  }

  ProgLongShortButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, MessageBox activeAddBox) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.activeAddBox=activeAddBox;
    callBacks.add(this);
  } // ProgLongShortButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();

    if (bText=="Long") {
      aPort.write("<B 29 5 1 "+callBacks.indexOf(this)+" 1>");    //***** WRITE CONFIGURATION VARIABLE BIT TO ENGINE DECODER ON PROGRAMMING TRACK  ****/    
      /*    case 'B':      // <B CV BIT VALUE CALLBACKNUM CALLBACKSUB>
       *    writes, and then verifies, a single bit within a Configuration Variable to the decoder of an engine 
       on the programming track
       *    CV: the number of the Configuration Variable memory location in the decoder to write to (1-1024)
       *    BIT: the bit number of the Configurarion Variable memory location to write (0-7)
       *    VALUE: the value of the bit to be written (0-1)
       *    CALLBACKNUM: an arbitrary integer (0-32767) that is ignored by the Base Station and is simply echoed 
       back in the output - useful for external programs that call this function
       *    CALLBACKSUB: a second arbitrary integer (0-32767) that is ignored by the Base Station and is simply 
       echoed back in the output - useful for external programs (e.g. DCC++ Interface) that call this 
       function
       *    returns: <r CALLBACKNUM|CALLBACKSUB|CV BIT VALUE)
       *    where VALUE is a number from 0-1 as read from the requested CV bit, or -1 if verificaiton read fails
       */
    } else if (bText=="Short") {
      aPort.write("<B 29 5 0 "+callBacks.indexOf(this)+" 0>");
    }
  }  //  ProgLongShortButton pressed

  //////////////////////////////////////////////////////////////////////////

  void execute(int n, String c) {
    String[] cs = splitTokens(c);

    int val=int(cs[2]);

    switch(val) {

    case -1:
      msgBoxMain.setMessage(n==1?"Error - Activating Long Address Failed":"Error - Activating Short Address Failed", color(255, 30, 30));
      activeAddBox.setMessage("?", color(200, 50, 50));
      break;

    case 0:
      msgBoxMain.setMessage("Activating Short Address Succeeded", color(30, 150, 30));
      activeAddBox.setMessage("SHORT", color(200, 50, 50));
      break;

    case 1:
      msgBoxMain.setMessage("Activating Long Address Succeeded", color(30, 150, 30));
      activeAddBox.setMessage("LONG", color(200, 50, 50));
      break;
    }
  }  //  ProgLongShortButton execute
} // ProgLongShortButton Class

//////////////////////////////////////////////////////////////////////////
//  Class OpWriteButton
//////////////////////////////////////////////////////////////////////////

class OpWriteButton extends EllipseButton {
  InputBox opCVInput, opValueInput;

  OpWriteButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox opCVInput, InputBox opValueInput) {
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, opCVInput, opValueInput);
  }

  OpWriteButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox opCVInput, InputBox opValueInput) {
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.opCVInput=opCVInput;
    this.opValueInput=opValueInput;
  } // OpWriteButton

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    super.pressed();
    int cab=opCabInput.getIntValue();
    int cv=opCVInput.getIntValue();
    int val=opValueInput.getIntValue();

    if (cab<1 || cab>10239) {
      msgBoxMain.setMessage("Error - Cab must be in range 1-10239", color(255, 30, 30));
      return;
    }
    if (cv<1 || cv>1024) {
      msgBoxMain.setMessage("Error - CV must be in range 1-1024", color(255, 30, 30));
      return;
    }

    if (bText=="WRITE") {
      aPort.write("<w"+cab+" "+cv+" "+val+" >");    //***** WRITE CONFIGURATION VARIABLE BYTE TO ENGINE DECODER ON MAIN OPERATIONS TRACK  ****/    
      /*    case 'w':      // <w CAB CV VALUE>
       *    writes, without any verification, a Configuration Variable to the decoder of an engine on the main 
       *        operations track
       *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder 
       *    CV: the number of the Configuration Variable memory location in the decoder to write to (1-1024)
       *    VALUE: the value to be written to the Configuration Variable memory location (0-255)
       *    returns: NONE
       */
      return;
    }

    if (val>7) {
      msgBoxMain.setMessage("Error - Bit must be in range 0-7", color(255, 30, 30));
      return;
    }


    if (bText=="SET") {
      aPort.write("<b"+cab+" "+cv+" "+val+" 1>");    //***** WRITE CONFIGURATION VARIABLE BIT TO ENGINE DECODER ON MAIN OPERATIONS TRACK  ****/    
      /*    case 'b':      // <b CAB CV BIT VALUE>
       *    writes, without any verification, a single bit within a Configuration Variable to the decoder of an 
       *        engine on the main operations track
       *    CAB:  the short (1-127) or long (128-10293) address of the engine decoder 
       *    CV: the number of the Configuration Variable memory location in the decoder to write to (1-1024)
       *    BIT: the bit number of the Configurarion Variable regsiter to write (0-7)
       *    VALUE: the value of the bit to be written (0-1)
       *    returns: NONE
       */
    } else if (bText=="CLEAR") {
      aPort.write("<b"+cab+" "+cv+" "+val+" 0>");
    }
  }  //  OpWriteButton pressed
} // OpWriteButton Class
//////////////////////////////////////////////////////////////////////////
