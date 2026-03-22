#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl enable nginx

# Notice the \$backend here! This stops Bash from evaluating the variable
# but allows Terraform to interpolate ${nlb_dns}.
cat <<EOF > /etc/nginx/conf.d/app.conf
# Use AWS Default VPC DNS Resolver
resolver 169.254.169.253 valid=10s;

server {
    listen 80;

    location /api/ {
        set \$backend "${nlb_dns}";
        proxy_pass http://\$backend:8081;
    }

    location / {
        return 200 "FE Server Running\n";
    }
}
EOF

systemctl start nginx