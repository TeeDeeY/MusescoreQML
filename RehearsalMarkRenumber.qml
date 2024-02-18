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
// Alpha version.   
// 
// The process is 1) Backup your file  2) Run the plug-in. 3) The first Rehearsal Mark (per measure) found per measure will be changed.
// The changes is based on how MuseScore currently system of numbering measures, taking into account Measure Properties (Exclude from
// Measure Count) and Measure Properties (Add to Measure Number).
//
// Weaknesses: 1) No options. 2) It can only update Rehearsal Marks already placed. 3) The "first" Rehearsal Mark changed may not
// be your favored one.
//
// Figuring out which fields likely held Measure Properties was helped a TON 
// by REFcode_ExamineElement-andParents.qml (JeffRocchio on GibHub)
//
// + stuff on musescore.org (especially "Boilerpates, snippets, use cases and QML notes"
// at https://musescore.org/en/node320673
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
  menuPath: "Plugins.RehMReNum"
  description: "Rehearsal Mark Renumbering"
  version: "0.4"
  requiresScore: true
  id: plugin
    
  onRun:{
      var cursor = curScore.newCursor();
      cursor.rewind(0);
      var i = 0; // actual measure offset
      var m = 1; // "virtual count per MuseScore", including no counting or adjusting
      var bool1 = true;  // more measures to read
      var firstInMeasure=true; // first Rehearsal Mark in the annotations list will be used.
      
      while (bool1)  { // we are moving through the measures
        m += cursor.measure.noOffset; // add offset before the measure per MuseScore's measure counting method
        var seg = cursor.measure.firstSegment;  // segments within the current measure
        if (seg) { // an error checking step
         while (seg) {
            var al = seg.annotations.length;  // annotation structure can hold multiple types of items
            firstInMeasure=true;
            if (al) {
              for (var j = 0; j<al && firstInMeasure; j++) { // go through all the annotations
                 if (seg.annotations[j].type === Element.REHEARSAL_MARK) {
                   if (firstInMeasure) {  // first rehearsal mark in measure
                     curScore.startCmd();
                     seg.annotations[j].text = m; // change it to measure number
                     curScore.endCmd();
                     
                     firstInMeasure = false; // after change made, exit while loop
                   }                   
                 }  // end if rehearsal mark
              } // for j < al 
            } // end if al (there are annotations)
            seg = seg.nextInMeasure;
          } // while seg
        } else {
          console.log ("firstSegment for measure " + i + " is null "); // shouldn't happen...
        } // end if
        i++;
        if (!cursor.measure.irregular) m++;  // if the don't count check box isn't set...
        bool1 = cursor.nextMeasure(); 
        }  // end while - should be a do/while loop...
  }
   
  MessageDialog {
    id: infobox
    text: "You may have to save and reload to show the changes.\n Counts should be the same as MuseScore counts."
    onAccepted: {
      return;
    }
    Component.onCompleted: visible = true
   }
 } // end MuseScore
