#!/usr/bin/env python3
"""
A REAL web server that Railway can serve to the internet
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
import os


class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Hello from Railway</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }
                .container {
                    background: white;
                    padding: 50px;
                    border-radius: 20px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    text-align: center;
                }
                h1 { color: #667eea; margin: 0; }
                p { color: #666; margin-top: 20px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚀 Hello World from Railway!</h1>
                <p>This is a REAL web server running on Railway</p>
                <p>Anyone with the URL can see this!</p>
            </div>
        </body>
        </html>
        """
        self.wfile.write(html.encode())


def run_server():
    port = int(os.environ.get('PORT', 8080))
    server = HTTPServer(('0.0.0.0', port), HelloHandler)
    print(f"🌐 Web server running on port {port}")
    print(f"This CAN be accessed from the internet!")
    server.serve_forever()


if __name__ == "__main__":
    run_server()


