//////////////////////////////////////////////////////////////////////////
//  PROCESSING RAILWAY CONTROLLER: Class for Track Button
//      Sheet : dTurnouts
//
//  TrackButton  -  creates a TURNOUT or CROSSOVER by grouping two sets of
//                  of pre-specified tracks
//               -  one set of tracks defines the state of the turnout
//                  or crossover in the "open" position
//               -  the other set of tracks defines the state of the turnout
//                  or crossover in the "closed" position
//               -  a clickable but otherwise invisible button (the Track Button)
//                  located near the center of the turnout or crossover
//                  toggles between the closed and open positions
//
//
//               -  when toggled, TrackButton will:
//  
//                    * reset the colors of each set of tracks to
//                      indicate whether the turnour or crossover
//                      is "open" or "closed"
//
//                    * reset the color of any route buttons that use this
//                      track button
//
//                    * send a DCC ACCESSORY COMMAND to the Base Station
//                      using the Accessory Address and Accessory Number
//                      specified for this Track Button
//
//                      In accordance with NMRA DCC Standards, accessory decoders
//                      are controlled using 12 bits messages.  The first 11 form
//                      a main address (9 bits) and a sub address (2 bits).  Depending
//                      on the specifics of a particular manufacturers decoder, these
//                      11 bits can be interpreted as a single address (0-2047) or
//                      as a main address (0-511) with 4 sub addresses (0-3).  Some decoders
//                      may respond to any address matching the first 9 bits; others may
//                      also consider the two sub address bits. In any case, Track Button
//                      can be used to send the correct combination of 11 bits to sucessfully
//                      communicate with the decoder.
//
//                      The 12th bit is generally considered to be the data bit that is used
//                      to toggle the accessory either on or off.  In the case of a decoder
//                      driving a turnout or crossover, this data bit is used to toggle between
//                      the open and closed positions.
//
//  Signal Button - Define the position of traffic lights 
//                - Take three color (red yellow, green) in function of cab traffic
//
//
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
//    Class TrackButton
//////////////////////////////////////////////////////////////////////////

class TrackButton extends DccComponent {
  int xPos, yPos;
  int kWidth, kHeight;
  int buttonStatus=0;
  int id;
  int tTime;
  boolean rEnabled=true;
  ArrayList<Track> aTracks = new ArrayList<Track>();
  ArrayList<Track> bTracks = new ArrayList<Track>();
  ArrayList<RouteButton> aRouteButtons = new ArrayList<RouteButton>();  //  Turnout right way
  ArrayList<RouteButton> bRouteButtons = new ArrayList<RouteButton>();  //  Turnout deviant way
  MessageBox msgBoxTurnout;

  TrackButton(int kWidth, int kHeight, int id) {
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.id=id;
    this.componentName="T"+id;    
    trackButtonsHM.put(id, this);
    msgBoxTurnout=new MessageBox(TurnWindow, 10, (id-100)*22+20, -1, 0, color(175), 18, "T-"+nf(id, 2)+":", color(50, 50, 250));
    dccComponents.add(this);
  } // TrackButton

  //////////////////////////////////////////////////////////////////////////

  void addTrack(Track track, int tPos) {
    int n=aTracks.size()+bTracks.size();
    this.xPos=int((this.xPos*n+(track.x[0]+track.x[1])/2.0*track.layout.sFactor+track.layout.xCorner)/(n+1.0));
    this.yPos=int((this.yPos*n+(track.y[0]+track.y[1])/2.0*track.layout.sFactor+track.layout.yCorner)/(n+1.0));

    if (tPos==0) {     // specifies that this track should be considered part of aTracks
      track.tStatus=1-buttonStatus;
      aTracks.add(track);
    } else if (tPos==1) {    // specifies that this track should be considered part of bTracks
      track.tStatus=buttonStatus;
      bTracks.add(track);
    }
  }  //  TrackButton addTrack

  //////////////////////////////////////////////////////////////////////////

  void display() {    
    if (buttonStatus==0) {
      for (Track track : bTracks)
        track.display();
      for (Track track : aTracks)
        track.display();
    } else {
      for (Track track : aTracks)
        track.display();
      for (Track track : bTracks)
        track.display();
    }
  }  //  TrackButton display

  //////////////////////////////////////////////////////////////////////////

  void check() {
    if (selectedComponent==null && (mouseX-xPos)*(mouseX-xPos)/(kWidth*kWidth/4.0)+(mouseY-yPos)*(mouseY-yPos)/(kHeight*kHeight/4.0)<=1) {
      cursorType=HAND;
      selectedComponent=this;
      //print("dTurnouts CHECK 1 ");
    }
  }  //  TrackButton check

  //////////////////////////////////////////////////////////////////////////

  void routeEnabled() {
    rEnabled=true;
  }  //  TrackButton routeEnabled

  //////////////////////////////////////////////////////////////////////////

  void routeDisabled() {
    rEnabled=false;
  }  //  TrackButton routeDisabled

  //////////////////////////////////////////////////////////////////////////

  void pressed() {
    pressed(1-buttonStatus);
  }  //  TrackButton pressed

  //////////////////////////////////////////////////////////////////////////

  void pressed(int buttonStatus) {
    aPort.write("<T"+id+" "+buttonStatus+">");    //***** CREATE/EDIT/REMOVE/SHOW & OPERATE A TURN-OUT  ****/    
    /*    case 'T':       // <T ID THROW>
     *   <T ID THROW>:                sets turnout ID to either the "thrown" or "unthrown" position
     *   ID: the numeric ID (0-32767) of the turnout to control
     *   THROW: 0 (unthrown) or 1 (thrown)
     *   returns: <H ID THROW> or <X> if turnout ID does not exist        
     *   <T ID ADDRESS SUBADDRESS>:   creates a new turnout ID, with specified ADDRESS and  SUBADDRESS      
     *       if turnout ID already exists, it is updated with specificed ADDRESS and SUBADDRESS      
     *       returns: <O> if successful and <X> if unsuccessful (e.g . out of memory)       
     *   <T ID>: deletes definition of turnout ID      
     *       returns: <O> if successful and <X> if unsuccessful (e.g. ID does not exist)      
     *   <T>: lists all defined turnouts      
     *         returns: <H ID ADDRESS SUBADDRESS THROW> for each defined turnout or <X> if no turnouts defined      
     *         where      
     *          ID: the numeric ID (0-32767) of the turnout to control      
     *          ADDRESS:  the primary address of the decoder controlling this turnout (0-511)      
     *          SUBADDRESS: the subaddress of the decoder controlling this turnout (0-3)      
     *         Once all turnouts have been properly defined, use the <E> command to store their definitions to EEPROM.      
     *         If you later make edits/additions/deletions to the turnout definitions, you must       
     *          invoke the <E> command if you want those new definitions updated in the EEPROM.        
     *         You can also clear everything stored in the EEPROM by invoking the <e> command.      
     *         To "throw" turnouts that have been defined use:      
     *   <T ID THROW>:   sets turnout ID to either the "thrown" or "unthrown" position      
     *       returns: <H ID THROW>, or <X> if turnout ID does not exist      
     *       where      
     *          ID: the numeric ID (0-32767) of the turnout to control      
     *          THROW: 0 (unthrown) or 1 (thrown)      
     */
    delay(150);
    if (buttonStatus==0) {
      msgBoxTurnout.setMessage("T-"+nf(id, 2)+": "+nf((millis()-tTime)/1000.0, 0, 1)+" sec"+" - Status: DIRECT");
    } else {
      msgBoxTurnout.setMessage("T-"+nf(id, 2)+": "+nf((millis()-tTime)/1000.0, 0, 1)+" sec"+" - Status: DEVIATE");
    }
    tTime=millis();
  }    //  TrackButton pressed

  //////////////////////////////////////////////////////////////////////////

  void update(int buttonStatus) {

    this.buttonStatus=buttonStatus;

    for (Track track : aTracks) {
      track.tStatus=1-buttonStatus;
      println("Update trackbutton 1 : buttonStatus:", buttonStatus, "tStatus:", track.tStatus, "aTracks:", aTracks, "bTracks:", bTracks);
    }   
    for (Track track : bTracks) {
      track.tStatus=buttonStatus;
      println("Update trackbutton 2 : buttonStatus:", buttonStatus, "tStatus:", track.tStatus, "aTracks:", aTracks, "bTracks:", bTracks);
    }

    if (buttonStatus==0) {  
      for (RouteButton routeButton : bRouteButtons)
        routeButton.routeOn=false;
      println("Update trackbutton 3 : buttonStatus:", buttonStatus, "aRouteButtons:", aRouteButtons, "bRouteButtons:", bRouteButtons);
    } else {
      for (RouteButton routeButton : aRouteButtons)
        routeButton.routeOn=false;
      println("Update trackbutton 4 : buttonStatus:", buttonStatus, "aRouteButtons:", aRouteButtons, "bRouteButtons:", bRouteButtons);
    }
  }  //  TrackButton update
} // TrackButton Class

//////////////////////////////////////////////////////////////////////////

int SizeClass_A_TrackButton() {
  int size_a_trackbutton = aTrackButtons.size();
  return size_a_trackbutton;
}

//////////////////////////////////////////////////////////////////////////

TrackButton getClass_A_TrackButton(int i) {
  TrackButton ref_a_trackbutton = aTrackButtons.get(i);
  return ref_a_trackbutton;
}

//////////////////////////////////////////////////////////////////////////

int SizeClass_B_TrackButton() {
  int size_b_trackbutton = bTrackButtons.size();
  return size_b_trackbutton;
}

//////////////////////////////////////////////////////////////////////////

TrackButton getClass_B_TrackButton(int i) {
  TrackButton ref_b_trackbutton = bTrackButtons.get(i);
  return ref_b_trackbutton;
}
//////////////////////////////////////////////////////////////////////////
