# VR-Based Psychological Phobia Therapy
This apps deploys a Graphical User Interface that is able to receive data
from the Aura software LSL Stream in two formats: 

      1. Streamed signal (Cap on participant).
      2. Recorded signal (File loaded).
------------------------------------------------------------------------
The received signal is treated accordingly:
  - If streamed, it goes directly into a preprocessing pipeline.
  - If recorded, the signal is first "fixed", by trimming its fft and
    applying ifft to recontruct the original signal (for more details,
    contact: dgcarolp@hotmail.com). After that, it goes into the
    preprocessing pipeline.
------------------------------------------------------------------------
The preprocessing steps are:
  1. Bandpass filter (1-50 Hz).
  2. Common Average Reference.
  3. Stopband filter (60 Hz).
  4. WAAF. 
------------------------------------------------------------------------
Once the data is clean, a Neural Network (CNN + LSTM) assigns one of
these four labels to the window:

      1. Surprise.
      2. Relief.
      3. Fear. 
      4. Disgust. 
------------------------------------------------------------------------
The data is received in 6-second chunks. After cleaning, only
5-second windows are preserved due to window edge artifacts, fixed by
removing 0.5 seconds from the start and end of each original window.

------------------------------------------------------------------------
This app avoids using a "while true [...]" statement by implementing a
timer function ('dcaro_timer') and executing it every 5 seconds, for the 
following reason:
  The LSL stream provides the latest N samples (specified by the argument 
  'chunksize', when calling the inlet constructor) and for this app, N is 
  equivalent to 6 seconds. This doesn't cause any error, or overlap 
  between windows, since we are only keeping 5 seconds due to edge 
  artifacts. In the case that we were not rejecting these edges, we would 
  have an overlap of 1 second, and I didn't want overlap.  
  
------------------------------------------------------------------------
Finally, this app establishes a connection to a TCP/IP server with
the IP and port provided (defaults: 'localhost:4000') to stream out the
emotion label to any third party software.

------------------------------------------------------------------------
Requirements:
  - dcaro_aura_fix.m
  - dcaro_WAAF.m
  - dcaro_stacked.m
  - Models/1_5-Nov-2025.mat
  - liblsl-Matlab/

Please refer any query to: dgcarolp@hotmail.com or
                           A00833057@exatec.tec.mx
_________________________________________________________________________
by: Diego Caro López, Mirai Innovation Research Institute,
    EMFUTECH Fall 2025, Osaka, Japan. 
    12-Nov-2025.
