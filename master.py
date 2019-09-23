import socket
import subprocess 
import sys 

host = "127.0.0.1"
port = int(sys.argv[1])

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    sock.connect((host, port))
except:
    print("[ERROR] Could not connect to server.") 
    exit(1)

id = "Edub07_m4st3r"
sock.send(id.encode())
passwordPrompt = sock.recv(1024).decode().rstrip()
print(passwordPrompt)
sock.send(input("> ").encode())

welcome = sock.recv(1024).decode()
print(welcome)

while True:
    command = input("> ")

    if command == '':
    	continue

    command = command.encode()

    try:
        sock.send(command)
        result = sock.recv(1024).decode()
        print(result)
    except Exception as err:
        print("[-] Something went wrong. Server exited.")
        break

sock.close()