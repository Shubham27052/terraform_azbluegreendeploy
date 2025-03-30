#!/bin/bash

# Update package lists
apt-get update -y

# Install nginx
apt-get install -y nginx

# Ensure web root directory exists
mkdir -p /var/www/html

# Create index.html displaying hostname
cat > /var/www/html/index.html <<EOF
<html>
<body>
    <h1>Hostname: Blue VM</h1>
    <h3>This is Blue VM</h3>
</body>
</html>
EOF

# Restart Nginx
systemctl enable nginx
systemctl start nginx