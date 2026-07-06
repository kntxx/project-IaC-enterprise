#!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
 cat <<'EOF' > /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head><title>HR Portal Infra</title></head>
    <body>
    <h1>-----Secure Enterprise Infrastructure-----</h1>
    <p>Deployed via Azure IaC pipeline — ${environment} environment.</p>
    </body>
    </html>
EOF