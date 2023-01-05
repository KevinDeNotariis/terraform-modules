#!/bin/bash

function setup() {
  yum update -y
  yum install -y wget ruby jq
}

# ------------------------------------------------------------------------------------
# Installations
# ------------------------------------------------------------------------------------
function install-codedeploy-agent() {
  # Configurations for getting the AWS CodeDeploy Agent in region: eu-west-1
  local bucket_name="aws-codedeploy-eu-west-1"
  local region_identifier="eu-west-1"

  wget https://$bucket_name.s3.$region_identifier.amazonaws.com/latest/install
  chmod +x ./install

  ./install auto

  systemctl start codedeploy-agent
  systemctl enable codedeploy-agent
  systemctl status codedeploy-agent

  rm -f install
}

function install-cloudwatch-agent() {
  yum install -y amazon-cloudwatch-agent

  systemctl start amazon-cloudwatch-agent
  systemctl enable amazon-cloudwatch-agent
  systemctl status amazon-cloudwatch-agent
}

function install-mongodb-shell() {
  echo -e "[mongodb-org-4.0] \nname=MongoDB Repository\nbaseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/\ngpgcheck=1 \nenabled=1 \ngpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc" | tee /etc/yum.repos.d/mongodb-org-4.0.repo
  yum install -y mongodb-org-shell
}

function install-nginx() {
  amazon-linux-extras install nginx1
}

function install-dependencies() {
  setup
  install-codedeploy-agent
  install-cloudwatch-agent
  install-mongodb-shell
  install-nginx
}

# ------------------------------------------------------------------------------------
# Configurations
# ------------------------------------------------------------------------------------
function configure-cloudwatch-agent() {
  mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
  cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json<<-EOF
${cloudwatch_agent_json}
EOF

  systemctl restart cloudwatch-agent
}

function configure-mongo-tls-ca() {
  wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem

  mv rds-combined-ca-bundle.pem /etc/ssl/rds-combined-ca-bundle.pem
}

function configure-nginx() {
  cat > /etc/nginx/nginx.conf<<-EOF
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }

        location = /status/health {
                access_log off;
                add_header 'Content-Type' 'application/json';
                return 200 '{"status": "UP"}';
        }
    }
}
EOF

  systemctl start nginx
  systemctl enable nginx
  systemctl status nginx
}

function configure() {
  configure-cloudwatch-agent
  configure-mongo-tls-ca
  configure-nginx
}


function main() {
  install-dependencies
  configure
}

main