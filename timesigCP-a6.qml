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
//
// Alpha version. Revised version 0.61  - Revised to also copy "Actual Time Signature", not just Nominal Time Signature 
// + some code cleanup.
//
// It OVERWRITES measures until this can be updated to insert the required measures.  
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
  menuPath: "Plugins.timesigCPa6"
  description: "Time Signature range copy/paste-overwrite"
  version: "0.61"
  requiresScore: true
  id: plugin
  property int  margin: 10
  property real customwidth: Screen.desktopAvailableWidth*.3
  property real customheight: Screen.desktopAvailableHeight*.3
  property variant tsarray: []  // global variable to hold time signatures.  Space-wise wasteful but maybe I'll need more info later.
  property variant marray: [] // hold measures to pull timesigActual and future info???
  
  function copyselected() {  // This currently assumes a selected contiguous range.
           
          var endTick;  // needed to know when we are at the end of the selection
          var cursor = curScore.newCursor();
            
          cursor.rewind(1);
          if (!cursor.segment) { // no selection
                  infobox.text = "You must select a range before running this plugin";
                  return; // for now, selection required when starting plugin
          } else {
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
                var ts=newElement(Element.TIMESIG);  // later, can just store minimal info
                var ms=newElement(Element.MEASURE);
                
                ts.timesig=cursor.measure.timesigNominal; 
                ms.timesigActual = cursor.measure.timesigActual; 
                tsarray.push (ts);
                marray.push (ms);
                cursor.nextMeasure();
           }
           infobox.text = "Collected " + tsarray.length + " measures for OVERWRITE/PASTE!"
 } // end function 
 
  onRun:{
      copyselected();
      plugindialog.width =Math.min(customwidth  ,Screen.desktopAvailableWidth)
      plugindialog.height=Math.min(customheight ,Screen.desktopAvailableWidth)
  }
 
  Component { id: setTimeout ; Timer {  } }
  Dialog { id:plugindialog
    title: "Time Sig Copy-PASTE/OVERWRITE"
    visible:true
    contentItem:Page{ id:plugincontent
      header: ToolBar {  // ToolBar, TabBar, or DialogButtonBox 
        background: Rectangle { color: "skyblue"}
        RowLayout{
          anchors.fill: parent
          Label{
            Layout.fillWidth: true
            text: "Musescore 4+ Alpha-Test Ver: 0.61 "
            color: "red"
          }
 
          ToolButton {
            text: 'GO: Overwrite!'
            onClicked:  { 
               var cursor = curScore.newCursor();
               var loop = inputtext.text;
               
               cursor.rewind(1);  // go to where the cursor is, when the GO button is pressed
               if (!cursor.segment) {
                  infobox.text = "A selection start point is required, set loop count, then press the GO button";
                  // return;
               } else {
                 var staff = 0; // cursor.staffIdx;
                 var tl = tsarray.length;
                 cursor.voice = 0; //voice has to be set after goTo
                  cursor.staffIdx = staff;

               var prevsig = tsarray[0].timesig;
                 
               for (var l=0; l<loop; l++) {  // for paste x N times same section                  
                  var ctick = cursor.tick;
                  if (ctick === 0) {  // either at end or beginning of file -- can't paste here
                   infobox.text = "Can't paste in measure 1 or the last measure";
                   return;
                  } 
                 
                  for (var i=0; i<tl; i++) { // for number of items pushed
                      var ts=newElement(Element.TIMESIG);
                      
                      ts.timesig  = tsarray[i].timesig;  // after all time sigs are entered, then the program goes back and inserts the actual ts.
                      var b1 = i>0;
                      var b2 = (tsarray[i].timesig.numerator === prevsig.numerator) && (tsarray[i].timesig.denominator === prevsig.denominator); 
                      if (b1 && b2) {  
                        cursor.nextMeasure();  // just go to the next measure if the time sig is the same as the prior measure (excluding 1st measure)
                      } else {
                      curScore.startCmd();  
                      cursor.add(ts);
                      curScore.endCmd();
                      prevsig = tsarray[i].timesig;
                      if (cursor.prev()) {   // go to measure before it was changed and reworked
                         if (!cursor.nextMeasure() ) {
                           infobox.text = "error 1"; 
                           return;
                         } 
                       } else {
                         infobox.text = "error 2";
                         return;
                       } // end if .prev
 
                       if (!cursor.nextMeasure() ) {  // now next measure
                         infobox.text = "error 3";
                         return;
                       } // end if
                       
                       }
                  } // end for tl
                     // use ctick to go back to start of selection, now set the measure actual after all ts's were made
                     cursor.rewindToTick (ctick);
                     if (ctick === 0) return;
                     for (var i=0; i<tl; i++) { // for number of items pushed
                        curScore.startCmd();
                        cursor.measure.timesigActual = marray[i].timesigActual;
                        curScore.endCmd();
                        if (!cursor.nextMeasure()) return;  // exit if error in going to next measure
                     }
                  } // end for loop                     
                } // end else segment
            } // end on clicked
          } // end tool button
        }
      }


      contentItem:Rectangle{ id:pagecontent
        color: "white" 
        Flickable{ 
          anchors.fill:parent;
          contentWidth: grid.width; contentHeight: grid.height
          GridLayout{ id:grid
            columns: 1
            Column{ id:allcontent
              Layout.leftMargin : margin; Layout.rightMargin  : margin
              Layout.topMargin  : margin ; Layout.bottomMargin :margin
              Column{ id:innercontent
              //  width: parent.width
                
              Text {
                id: instru0
                anchors.top: innercontent.top
                text: "Backup your Score. This plugin DOES NOT INSERT MEASURES YET.\n *Insert twice as many as you think you will need*.\n"
              }
               Text {
                id: instru0a
                anchors.top: instru0.bottom
                text: "This Alpha Test Version is for developers to review!\n It can crash for various reasons AND if you\n don't have enough measures inserted beforehand!"
              }
 
              Text {
                id: instru1
                anchors.top: instru0a.bottom
                text: "1. Select range in Score; 2. Run plugin. 3. Enter REPEAT value. "
              }
              Text {
                id: instru2
                anchors.top: instru1.bottom
                text: "4. Click in Score destination for new measures. 5. Insert-after twice as\n many measures as youthink you will need.\n 5. Press GO button. 6. Close window.\n"
              }
         
              Text {
                id: infobox
                color: "red"
                anchors.top: instru2.bottom
                text: " "
              }

              Text {
                id: instru3
                anchors.top: infobox.bottom
                text: ""
              }
              Text {
                id: instru4
                anchors.top: instru3.bottom
                text: "Change Count Here to REPEAT paste N times: "
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
                anchors.top: instru4.bottom
                text: "May make sense to export to Music XML and reimport after\nthese drastic changes."
              }
       
             } // end column
             } // end column
             } // end grid
             } // end flickable
             } // end rectangle
 
    } // end contentitem
    } // end Dialog
} // end MuseScore
