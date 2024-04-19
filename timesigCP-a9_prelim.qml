// Copyright (c) 2024 @TeeDeeY at Github.
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Versuib 0.9 test if "copy/paste" buffer works between Scores.
// Version 0.8 (Alpha version)
//   1) A very initial version 2) allows paste into 1st measure 3) Can't past into the last measure.  
//   4) auto-inserts measures needed + a few extra (1 extra per loop + 3 extra). 5) Save to data file timesigCP_V1.tmp
//   6) You can start another instance of MuseScore, load timesigCP_V1.tmp and the paste into a new instance.
//   7) Adds an "ending" time signature to protect prior notes.  Sometimes, the last copied time signature ruins prior work,
//      so an ending time signature protects the prior work.
//
//   Alpha versions are undergoing design changes
// Prior versions:
// version 0.7   - Testing various ideas, not released.
// version 0.61  - Revised to also copy "Actual Time Signature", not just Nominal Time Signature + some code cleanup.
// version 0.5   - First release for review
// Pre-v0.8, OVERWRITES measures until this can be updated to insert the required measures.  
// Therefore, insert a whole lot of measures just in case.
// 
// The process is 1A) Backup your file.
// 1B) Select a range in the score.  2) Run the plug-in.  3A) Insert an "ending" time-signature (same as current) to protect any
// notes that are currently following the insert point. 4) Insert twice as many measures as you think you will need before the the "ending"
// that you just entered.  This plugin overwrites measures already present. 4) Insert the loop count (loops the paste process)
// 5) Move back to the Score and click in the starting target measure. 6) Press the Paste/Overwrite button.
// 7) May be safest to export using Music XML, then reloading it as a new file in case weird settings aren't set.
//
// Features: Now adjusts for Actual time-sig (if modified). 
//
// Weaknesses: 1) Doesn't detect going past the end of measures ahead of time. Make sure there are enough empty measures.
// 3) Overwrites measures (saying it again!). 4) Interface needs work! 5) ---
// 6) No cleanup at the ending measures. 7) ---  8) Can't insert into measure #1 in a Score.
//
// As always, code copied from other plug-in writers on Git-Hub & musescore.org.  More credits will show up later.  
// Used Colornotes, Doubletime, Expand Chord Symbols, & JoJo's ColorVoices to figure out global variables, etc.
// This is without warranty, etc.  Use at your own risk.
// ExpandChordSymbols Copyright (c) 2020 Mark Shepherd
// Doubletime by HazardousPeach
// colornotes (c) 2021 Musescore BVBA and others (by heuchia and Jojo Schmitz
//  ColorVoices plugin
//  Copyright (C)2011 Charles 'ozcaveman' Cave (charlesweb@optusnet.com.au)
//  Copyright (C)2014 Jörn 'heuchi' Eichler (joerneichler@gmx.de)
//  Copyright (C)2019 Johan 'jeetee' Temmerman (musescore@jeetee.net)
//  Copyright (C)2012-2023 Joachim 'Jojo' Schmitz (jojo@schmitz-digital.de)
//
// + stuff on musescore.org (especially "Boilerpates, snippets, use cases and QML notes"
// at https://musescore.org/en/node/320673
// ALPHA-CODE. ONLY FOR CONCEPTUAL DISCUSSION AND FREE HELP ;)
//

import MuseScore 3.0
import QtQuick 2.9  
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2

 MuseScore {
   menuPath: "Plugins.timesigCP Buffer" 
 
  description: "Time Sig copy/paste-overwrite 0.9"
  version: "0.9"
  requiresScore: false
  id: plugin
  property int  margin: 10
  property real sWidth: Screen.desktopAvailableWidth*.3
  property real sHeight: Screen.desktopAvailableHeight*.4
  property variant tsarray: []  // global variable to hold time signatures.  Space-wise wasteful but maybe I'll need more info later.
  property variant marray: [] // hold measures to pull timesigActual and future info???
  property variant tsarrayN: []   // numerator
  property variant tsarrayD: []   // denominator
  property variant marrayN: [] 
  property variant marrayD: []   
  property variant tBuffer; 
  
  TextEdit {
    id: cP;
    visible: false;
    text: "default";
  }    
  function copyselected() {  // This currently assumes a selected contiguous range.
           
          var endTick;  // needed to know when we are at the end of the selection
          var cursor = curScore.newCursor();
            
          cursor.rewind(1);
          if (!cursor.segment) { // no selection
              infobox.text = "You must select a range before running this plugin";
              return; // for now, selection required when starting plugin
          } else {
              saveTS.visible = true;  
              goPaste.visible = true;          
              cursor.rewind(2);
              if (cursor.tick === 0) {
                  endTick = curScore.lastSegment.tick + 1;
              } else {
                  endTick = cursor.tick;
              }
          } 
          cursor.rewind(1); 
          cursor.voice = 0; 
          cursor.staffIdx = 0; // for our use, staffIdx can always be 0.

          while (cursor.segment && (cursor.tick < endTick)) {
              var ts=newElement(Element.TIMESIG);  // later, try to clone into the array
              var ms=newElement(Element.MEASURE);  // then later clone into the "add" parameter
                
              ts.timesig=cursor.measure.timesigNominal; 
// timesig.numerator              
              ms.timesigActual = cursor.measure.timesigActual; 
              tsarray.push (ts);
              marray.push (ms);
              tsarrayN.push (ts.timesig.numerator);
              tsarrayD.push (ts.timesig.denominator);
              marrayN.push (ms.timesigActual.numerator);
              marrayD.push (ms.timesigActual.denominator);
              
              cursor.nextMeasure();

           }
           infobox.text = "Collected " + tsarray.length + " measures for Paste!"
 } // end function
 
 function go() {
         var cursor = curScore.newCursor();
         cursor.InputStateMode = Cursor.INPUT_STATE_SYNC_WITH_SCORE;  // INPUT_STATE_INDEPENDENT; //  
         var loop = inputtext.text;

         cursor.voice = 0; 
         cursor.staffIdx = 0;
         cursor.rewind(1);  // go to where the cursor is, when the GO button is pressed
         var ct = cursor.tick;
         cursor.voice = 0; 
         cursor.staffIdx = 0;

         
         if (!cursor.segment) {
// may need to make sure not trying to add into the last measure...         
               infobox.text = "A selection start point is required, set loop count, then press the GO button";
               // return;
         } else {
               infobox.text = "Go started";

               var timeSigWeight = 0.0;  // calculate how much empty space is needed...
               for (var tw=0; tw<tsarrayN.length; tw++) {
                 timeSigWeight += tsarrayN[tw] / tsarrayD[tw]; // (floating pt math)
               }
               console.log ("timeSigWeight is " + timeSigWeight);

               var measuresAdded = (timeSigWeight*cursor.measure.timesigNominal.denominator)/(cursor.measure.timesigNominal.numerator);
               console.log ("measures needed is " + measuresAdded);
               if (loop < 1 || loop > 2001) { 
                 loop = 1;
               }
               measuresAdded = measuresAdded * loop;
                                        
               // at the entry point of the copy/paste, write the TS into the measure
               // shouldn't change it, just remind it what is there...

// This should work... but causes the cmd("insert-measures") to not work... ????
                var tl = tsarrayN.length;
                console.log ("tl is : " + tl);
                                     console.log ("prevsig");
               var prevsig = fraction(tsarrayN[0], tsarrayD[0]);
               console.log ("Num" + tsarrayN[0]);
               console.log ("Denom" + tsarrayD[0]);
               console.log ("prevsig Num " + prevsig.numerator);
               console.log ("prevsig Denom " + prevsig.denominator);
               cursor.voice = 0; 
               cursor.staffIdx = 0;
 
               for (var i=0; i<(measuresAdded); i++) {  
                 cmd ("insert-measure");
               }
                 

               cmd ("insert-measure"); // plus three extra of the "current" TS for padding.
//              cmd ("insert-measure"); // actually, we should add three extra of the final TS...
//               cmd ("insert-measure"); // use this for this early testing.
               
               // if this is done before the cmd ("insert-measures"), they don't work...
               // probably a reason, but for now, don't add the ts for the ending until after all
               // the new measures are inserted.
               var ts1=newElement(Element.TIMESIG);
               ts1.timesig=cursor.measure.timesigNominal; 
               // need to see if this messes up any measure.timesigActual that was previously there
               //
               curScore.startCmd();  
               cursor.add(ts1);
// hopefully the prev and nextMeasures can be deleted before release               
               cursor.prev();       // going to previous segment helps with nextMeasure().
//               cursor.nextMeasure();
//               cursor.nextMeasure();               
               curScore.endCmd();
               
// see if this escape can be removed before release
 //              cmd ("escape");     

               cursor.rewindToTick (ct); // refresh to the initial input at rewind(1)
// should be able to remove this, redundant.
                cursor.rewindToTick (ct); 
               
               for (var l=0; l<loop; l++) { // makes sure a reasonable number of measures inserted.
                 for (var i=0; i<tl; i++) { // this causes the last measure to be excluded.
                   if (!cursor.nextMeasure()) {
                     infobox.text += "Error, not enough measures inserted.";
                     return;
                   }
                 }
               }
//               cursor.rewind(1);  // after verifying enough measures allocated (more or less), go back to selection start
               cursor.rewindToTick (ct);              

               cursor.voice = 0; 
               cursor.staffIdx = 0;
               console.log ("loop is " + loop);
               for (var l=0; l<loop; l++) {  // for paste x N times same section                  
                  var ctick = cursor.tick;
// using new method, it could be OK to paste into measure 1.                  
//                  if (ctick === 0) {  // either at end or beginning of file -- can't paste here
//                   infobox.text += "Can't paste in measure 1 or the last measure";
//                   return;
//                  }
 
                  
                    for (var i=0; i<tl; i++) { // for number of items pushed
                      var ts=newElement(Element.TIMESIG);
                      
                      ts.timesig  = fraction(tsarrayN[i],tsarrayD[i]);  // after all time sigs are entered, then the program goes back and inserts the actual ts.
                      var b1 = i>0;
                      var b2 = (tsarrayN[i]  == prevsig.numerator) && (tsarrayD[i] == prevsig.denominator); 
                      console.log ("in loop: tsarrayN " + tsarrayN[i]);
                      console.log ("prevsig.num " + prevsig.numerator);
                      console.log ("tsarrayD " + tsarrayD[i]);
                      console.log ("previsg.denom" + prevsig.denominator);
                      console.log ("test " + b2);
                      if (b1 && b2) {  
                        if (!cursor.nextMeasure()) { 
                          infobox.text += "No next measure 1";
                          return;
                        }
                      } else {
                        var ct3 = cursor.tick;
                        curScore.startCmd();  
                        cursor.add(ts);
                        console.log ("*** actually add ts ");
                        curScore.endCmd();
   
                  
                        prevsig = fraction(tsarrayN[i],tsarrayD[i]);
                        cursor.rewindToTick (ct3);
                        if (!cursor.nextMeasure() ) {
                           infobox.text += "error 1"; 
                           return;
                        }
                     } // end if-else b1 && b2
                  } // end for tl loop, inserting the time signatures (one time)
                     // use ctick to go back to start of selection, now set the measure actual after all ts's were made
                  cursor.rewindToTick (ctick);
                  if (ctick === 0) return; // needed?
                  for (var i=0; i<tl; i++) { // for number of items pushed
                      curScore.startCmd();
                      cursor.measure.timesigActual = fraction(marrayN[i],marrayD[i]);
                      // measureNumberMode, timeStretch, breakMmr, repeatCount, userStretch, noOffset, timesigGlobal, timesigType, irregular
                      
                      // cursor.meassure.
                      curScore.endCmd();
                      if (!cursor.nextMeasure()) { 
                          infobox.text += "No next measure for timesigActual";
                          return;
                      }

                  }                  
                } // end for paste "N" times loop
           } // end else segment
 } 
 
 
  onRun:{
      saveTS.visible = false;  
      goPaste.visible = false;
 //     if (mscoreMajorVersion < 4) {      
 //       var hP = tempFile.homePath();
 //       var fileName = hP + hP[0] + "timeSigCP_V1.tmp";
 //       console.log ("changed filename is ",fileName);
 //       tempFile.source = fileName;
 //      }
  //     console.log ("filename is: ", tempFile.source);
  //     console.log ("Home is: ", tempFile.homePath());
  //     console.log ("Temp is: ", tempFile.tempPath());
//      var startW = tempFile.write (startS);
//      console.log ("startW is: ", startW);
      copyselected();
      plugindialog.width =Math.min(sWidth  ,Screen.desktopAvailableWidth)
      plugindialog.height=Math.min(sHeight ,Screen.desktopAvailableWidth)
  
  }
 
  Component { id: setTimeout ; Timer {  } }
  Dialog { id:plugindialog
    title: "Time Sig Copy-Paste"
    visible:true
    contentItem:Page{ id:plugincontent
      header: ToolBar {  // ToolBar, TabBar, or DialogButtonBox 
        background: Rectangle { color: "gray"}
        RowLayout{
          anchors.fill: parent
          Label{
            Layout.fillWidth: true
            text: "Plugin for Musescore 4.2+ (Alpha-Test Ver: 0.9)"
            color: "lightgray"
          }
        }
      }

      contentItem:Rectangle{ id:pagecontent
        color: "lightgray" 
          anchors.fill:parent;
          GridLayout{ id:grid
            columns: 1
            Column{ id:allcontent
              Layout.leftMargin : margin; Layout.rightMargin  : margin
              Layout.topMargin  : margin ; Layout.bottomMargin :margin
              Column{ id:innercontent
              Text {
                id: pad
                anchors.top: innercontent.top
                text: " \n "
              }                  
              Text {
                id: instru0
                anchors.top: pad.bottom
                text: "Backup your Score. This plugin inserts measures plus a few extra.\n The current TS at the insert point is added.\n"
              }
              Text {
                id: instru0a
                anchors.top: instru0.bottom
                text: " "
              }
              Text {
                id: instru1
                anchors.top: instru0.bottom // move this up
                text: "1. Select range in Score; 2. Run plugin. 3. Enter REPEAT value. "
              }
              Text {
                id: instru2
                anchors.top: instru1.bottom
                text: "4. Click in same Score the destination for new measures.\n5. Press [Go! Paste] button. 6. Press [Close] button.\n"
              }
              Text {
                id: infobox
                color: "red"
                anchors.top: instru2.bottom
                text: " "
              }
              Text {
                id: instru3
                font.bold: true                
                anchors.top: infobox.bottom
                text: ""
              }
              Text {
                id: instru4
                anchors.top: instru3.bottom
                text: "REPEAT paste N times: "
              }
              
              Text {
                id: instru5
                anchors.top: instru4.bottom
                text: "\nExternal File timesigCP_V1.tmp Save/Load\n(TS + Measure Actual only in V1)"
              }
              
              Button {
                id: saveTS
                text: 'Save TS'
                anchors.top: instru5.bottom
                onClicked: { 
                  infobox.text =  infobox.text+ "+2";
                  
//              ts.timesig=cursor.measure.timesigNominal; 
//              ms.timesigActual = cursor.measure.timesigActual; 
                var outstr = "";
                outstr += tsarrayN.length + ";";
                for (var os=0; os<tsarrayN.length; os++) {
                      outstr += tsarrayN[os] + ";" +
                      tsarrayD[os] + ";" +
                      marrayN[os] + ";" +
                      marrayD[os] + ";";
 
                }
//                var testw = tempFile.write (outstr);
// ver a9:  
                  cP.clear();
                  cP.text = outstr;
                  cP.selectAll();
                  cP.copy();

                  console.log ("cP.text to buffer is " + cP.text);

                 // should check error code... and have error handler    
                }           
                
              }              
              
              
              
              
              
              Button {
                id: loadTS
                text: 'Load TS'
                anchors.top: saveTS.bottom

                onClicked: { 
 
                  
                  goPaste.visible = true;  
                  infobox.text =  infobox.text+ "+load";
 //                 console.log (" start length " + tsarrayN.length);  
 //                 console.log ("********** load phase 1");
                  if (false) {  // not sure why .clear() doesn't clear stack
                      tsarrayN.clear();
                      tsarrayD.clear();
                      marrayN.clear();
                      marrayD.clear();
                  
                  } else { // pop them to clear them.                                 
                      var x2;
                      while (tsarrayN.length > 0) {
                          console.log (" .length is " + tsarrayN.length);
                          tsarrayN.pop(x2);
                          tsarrayD.pop(x2);
                          marrayN.pop(x2);
                          marrayD.pop(x2);
                      }
                  }
 //                 console.log ("load phase 2");
                  if (false) { // early testing
                      tsarrayN.push (3);
                      tsarrayD.push (4);
                      marrayN.push (3);
                      marrayD.push (4);     
                  } else {            
 //                 var testr = tempFile.read();   // read the file 

                  var testr="";
                  cP.text = "";
                  cP.selectAll();
                  cP.paste();
                  infobox.text =  cP.text;                 
                  console.log ("cP.text from paste is : " + cP.text);

                  testr = cP.text;               
                 console.log ("testr is :" + testr);
                 console.log ("*** tempfile is " + testr);   
                  var loc=0;
                  var total = 0;
                  var str="";
                  var tot1 = 0;
                  while (testr[tot1] !== ';') {
                       str += testr[tot1];
                       tot1++;
                     }
                     console.log ("str " + str);
                     total = str;
                     tot1++;
                     str="";
                  // main loop;
                    for (var l1=0; l1<total; l1++) {
                     while (testr[tot1] !== ';') {
                       str += testr[tot1];
                       tot1++;
                     }
                     tot1++;
                     tsarrayN.push (str);
                     console.log ("found " + str);
                     str="";
                     

                     while (testr[tot1] !== ';') {
                       str += testr[tot1];
                       tot1++;
                     }
                     tot1++;
                     tsarrayD.push (str);
                     console.log ("found " + str);                     
                     str="";


                     while (testr[tot1] !== ';') {
                       str += testr[tot1];
                       tot1++;
                     }
                     tot1++;
                     marrayN.push (str);
                     console.log ("found " + str);                     
                     str="";

                     while (testr[tot1] !== ';') {
                       str += testr[tot1];
                       tot1++;
                     }
                     tot1++;
                     marrayD.push (str);
                     console.log ("found " + str);                     
                     str="";

                  }  // end for loop
                  // grab the count then cycle through 
                  
                  }
                  console.log (" end length " + tsarrayN.length);
                  
//              ts.timesig=cursor.measure.timesigNominal; 
//              ms.timesigActual = cursor.measure.timesigActual; 
// ts.timesig  = tsarray[i].timesig
// cursor.measure.timesigActual = marray[i].timesigActual;
                // if successful load
                goPaste.visible = true;                  
                }           

              }
       
              TextInput {
                id: inputtext
                color: "red"
                anchors.left: instru4.right
                anchors.bottom: instru4.bottom;
                text: "1"
              }   
              Text {
                id: addl
                anchors.top: loadTS.bottom
                text: "\nAn export to Music XML then reimport recommended."
              }
             } // end column
             } // end column
             } // end grid
             } // end rectangle
             
        footer: 
        DialogButtonBox {
          background: Rectangle { color: "white"}
          Button { 
            id: goPaste
            text: 'Go! Paste'
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
          }
          Button {
            text: 'Close'
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
          }
        
          onAccepted: { console.log("Go!") ; go(); }
          onRejected: { console.log("Close"); plugindialog.visible=false }
        }             
    } // end contentitem
    } // end Dialog
} // end MuseScore
