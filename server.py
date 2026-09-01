import http.server
import socketserver
import os

PORT = 8082
DIRECTORY = os.getcwd()

class MyHttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

with socketserver.TCPServer(("", PORT), MyHttpRequestHandler) as httpd:
    print(f"Serving at port {PORT}")
    print(f"Serving directory: {DIRECTORY}")
    httpd.serve_forever()
