#!/bin/bash
yum update -y
yum install -y python3

cat <<EOF > app2.py
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/api/downstream"):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Hello from App2 (8082)")
        else:
            self.send_response(404)
            self.end_headers()

server = HTTPServer(("0.0.0.0", 8082), Handler)
server.serve_forever()
EOF

nohup python3 app2.py &