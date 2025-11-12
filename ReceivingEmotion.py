# ReceivingEmotion.py
# -------------------------------------------------------------------------
# Emotion Recognition with EEG
# This scrips receives a label from MATLAB via TCP/IP. The label received 
# is representative of the predicted emotion of a 5-second EEG window
# captured and sent in real-time from the Aura software. The received  
# labels represent the following emotions:
#       1. Surprise. 
#       2. Relief.
#       3. Fear.
#       4. Disgust.
# -------------------------------------------------------------------------
# by: Diego Caro López, Mirai Innovation Research Institute, 
#     EMFUTECH Fall 2025, Osaka, Japan.     
#     10-Nov-2025.

from socket import * 
import struct

server = socket(AF_INET,SOCK_STREAM)
server.bind(('localhost',4000))
server.listen(1)
print(f"Server listening on LocalHost:4000")

s,addr = server.accept()
print(f"Connection established with: {addr}")

try:
    while True:
        data = s.recv(1024)
        data = struct.unpack('B',data)[0]
        
        match data:
            case 1:
                Emotion = "Surprise"
            case 2: 
                Emotion = "Relief"
            case 3: 
                Emotion = "Fear"
            case 4:
                Emotion = "Disgust"
            case _:
                Emotion = "Data not received properly."
        
        print('\nReceived emotion: ',Emotion)
finally:
    s.close()
    server.close()
    print('Connection closed')
