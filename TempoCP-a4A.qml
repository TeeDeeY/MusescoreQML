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
// TempoCP "copy/paste" Alpha version, 0.3 First distribution
//        0.4A 0.3 only set tempo marks at the start of a measure.  In 0.4A, a tempo mark can be "offset".  Usually a tempo needs to be added
//        in relation to a note or rest.  This version allows tempo marks to be 
//        offset but needs a note or rest on the top instrument line that matches the tempo location.
//        Otherwise, it will be placed "nearby".  More work needs to be done...
// 
// The process is 1) Backup your file  2) Select a range of measures with a tempo 3) Run Plug-in 4) Click where you want to paste.
// 5) Press Paste button
//
// Weaknesses: 1) You can paste multiple tempo marks in a measure (as you can in Musescore).
//
// Figuring out which fields likely held Measure Properties was helped a TON 
// by REFcode_ExamineElement-andParents.qml (JeffRocchio on GibHub)
//
// + stuff on musescore.org (especially "Boilerpates, snippets, use cases and QML notes"
// at https://musescore.org/en/node320673 and https://musescore.org/en/print/book/export/html/76
// See License and credits at the bottom of the page.
//
// ALPHA-CODE. ONLY FOR CONCEPTUAL DISCUSSION AND FOR OTHERS TO GIVE ME FREE HELP ON IMPROVEMENTS/FIXES ;)
//

import MuseScore 3.0
import QtQuick 2.9  
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2

 MuseScore {
  menuPath: "Plugins.TempoCP"
  description: "TempoCP -a4A Alpha-test: Copy tempos from a range, paste in other measures"
  version: "0.4"
  requiresScore: true
  id: plugin
  property variant in_tick
  property variant in_length;
  
  property int  margin: 10
  property real sWidth: Screen.desktopAvailableWidth*.3
  property real sHeight: Screen.desktopAvailableHeight*.3
 
function copyPaste() {
      var cursor = curScore.newCursor(); // Start of original selection
      var cursor_in = curScore.newCursor(); // 
      var cursor_out = curScore.newCursor();   
         
      var start_out_tick = cursor.tick; // for future use (looping)
      
      cursor_in.rewindToTick(in_tick); // input is from the global variable

      cursor.rewind(Cursor.SELECTION_START);
      var out_tick = cursor.tick;
      cursor_out.rewindToTick(out_tick); // try to keep _in and _out independent...
 
      for (var i3=0; i3<in_length; i3++) { // for the number of measures
       var seg = cursor_in.measure.firstSegment; // for every new measure, reset this...
       if (seg) {
        while (seg)  {
         var al = seg.annotations.length; // tempo stored in annotations, along with other stuff
         if (al) { // annotation type items;        
          for (var j = 0; j<al ; j++) {  // copy all these items...
           if (seg.annotations[j].type === Element.TEMPO_TEXT) {
             var outTickLoc = (out_tick)+(seg.tick - in_tick); 
             cursor_out.rewindToTick( outTickLoc ); // move to same offset...            
             curScore.startCmd();
             cursor_out.add(seg.annotations[j].clone()); // insert a duplicate from cursor_in into cursor_out
             curScore.endCmd(); 
           } // end if .type is TEMPO_TEXT
          } // end for number of annotations
         }  else {  // al = 0 from the start
            // not an error but using this structure for other plugins.
         } // end else (al)
         seg = seg.nextInMeasure;
       } // end while seg is valid (until no more segments to be found in a measure)
       cursor_in.nextMeasure();
       cursor_out.nextMeasure();
       } else {
          // not sure if a measure can start with a no segment. Let's see.
       }
      } // end for i3 loop; // going through the number of measures
} // end function

function get_input() {
          in_length = 0; // fake it for now, later based on length of selection
          var endTick;  // needed to know when we are at the end of the selection
          var cursor = curScore.newCursor();
          var startIdx;
          var endIdx;                                  
          cursor.rewind(Cursor.SELECTION_START); // SCORE_START, SECTION_START, SELECTION_END
          startIdx = cursor.staffIdx;
          
          in_tick = cursor.tick; // get start of selection here.          
          if (!cursor.segment) { // no selection
                  infobox.text = "You must select a range before running this plugin";
                  return; // for now, selection required when starting plugin
          } else {
                  cursor.rewind(Cursor.SELECTION_END);
                  endIdx = cursor.staffIdx;
                  if (cursor.tick === 0) { // this may only happen when one measure selected???
                        endTick = curScore.lastSegment.tick+1;
                  } else {
                        endTick = cursor.tick;  //  
                  }
            } 
            cursor.rewind(Cursor.SELECTION_START); 
            cursor.voice = 0; 
            cursor.staffIdx = 0; // for our use, staffIdx can always be 0.
            while (cursor.segment && (cursor.tick < endTick)) {
                in_length++;
                if (!cursor.nextMeasure()) {   // primitive way to find out number of measures 
                }
           }    
           infobox.text = "found " + in_length + " measures; "
    goButton.visible = true;
    return;       
 } // end function
    
  onRun:{
    plugindialog.width =Math.min(sWidth  ,Screen.desktopAvailableWidth)
    plugindialog.height=Math.min(sHeight ,Screen.desktopAvailableWidth)
    goButton.visible = false;
    get_input();
    
  } // end onRun
  
  Component { id: setTimeout ; Timer {  } }
  Dialog { id:plugindialog
    title: "Tempo Copy-paste"
    visible:true
    contentItem:Page{ id:plugincontent
      header: ToolBar {  // ToolBar, TabBar, or DialogButtonBox 
        background: Rectangle { color: "gray"}
        RowLayout{
          anchors.fill: parent
          Label{
            Layout.fillWidth: true
            text: "Plugin for Musescore 4.2+ (Alpha-Test Ver: 0.4A)"
            color: "white"
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
                text: "Backup your Score before using.\n"
              }
 
              Text {
                id: instru1
                anchors.top: instru0.bottom // move this up
                text: ""
              }
  
              Text {
                id: infobox
                font.bold: true
                color: "red"
                anchors.top: instru1.bottom
                text: " "
              }
 
              Text {
                id: instru4
                anchors.top: infobox.bottom
              }
              Text {
                id: addl
                anchors.top: instru4.bottom
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
            id: goButton
            text: 'Go! Paste'
            visible: false
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
          }
          Button {
            text: 'Close'
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
          }
           onAccepted: { copyPaste(); }
          onRejected: { plugindialog.visible=false }
        }             
    } // end contentitem
    } // end Dialog
  } // end MuseScore
