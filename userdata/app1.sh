#!/bin/bash
yum update -y
yum install -y python3
pip3 install requests

cat <<EOF > app1.py
from http.server import BaseHTTPRequestHandler, HTTPServer
import requests

APP2_URL = "http://${app2_ip}:8082/api/downstream"

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/api/hello"):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Hello from App1 (8081)")

        elif self.path.startswith("/api/fullchain"):
            try:
                r = requests.get(APP2_URL, timeout=2)
                response = "App1 -> " + r.text
            except Exception as e:
                response = "Error: " + str(e)

            self.send_response(200)
            self.end_headers()
            self.wfile.write(response.encode())

        else:
            self.send_response(404)
            self.end_headers()

server = HTTPServer(("0.0.0.0", 8081), Handler)
server.serve_forever()
EOF

nohup python3 app1.py &