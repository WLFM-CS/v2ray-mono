#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "please run as root user: sudo su"
  exit 0
fi

prepare_variables() {
  while getopts d:u: flag; do
    case "${flag}" in
    d) domain=${OPTARG} ;;
    u) uuid=${OPTARG} ;;
    *) ;;
    esac
  done
  if [ -z "$domain" ]; then
    echo "please enter a domain or subdomain by -d flag. ie: -d test-domain.com or -d test.test-domain.com"
    exit 0
  else
    domain="${domain//http:\/\//}"
    domain="${domain//https:\/\//}"
  fi
  if [ -z "$uuid" ]; then
    uuid=$(uuidgen)
  fi
  echo "domain: $domain"
  echo "uuid: $uuid"
}

prepare_v2ray() {
  rm -rf /var/log/v2ray/ && mkdir -p /var/log/v2ray/
  rm -rf /usr/local/share/v2ray/ && mkdir -p /usr/local/share/v2ray/
  rm -rf /usr/local/etc/v2ray/ && mkdir -p /usr/local/etc/v2ray/
  cp -rf ./v2ray/systemd/system/v2ray.service /etc/systemd/system/
  cp -rf ./v2ray/systemd/system/v2ray@.service /etc/systemd/system/
  ##create log files
  touch /var/log/v2ray/access.log
  touch /var/log/v2ray/error.log
  ##copy binaries
  cp -rf ./v2ray/v2ray /usr/local/bin/v2ray
  cp -rf ./v2ray/v2ctl /usr/local/bin/v2ctl
  chmod +x /usr/local/bin/v2ray
  chmod +x /usr/local/bin/v2ctl
  ##copy dat files
  cp -rf ./v2ray/geosite.dat /usr/local/share/v2ray/geosite.dat
  cp -rf ./v2ray/geoip.dat /usr/local/share/v2ray/geoip.dat
  cp -rf ./v2ray/iran.dat /usr/local/share/v2ray/iran.dat
  ##chown
  chown -R nobody /usr/local/share/v2ray/
  chown -R nobody /var/log/v2ray

  ##prepare config
  v2ray_config="$(cat ./v2ray/config.json)"
  v2ray_config="${v2ray_config//DOMAIN_PLACEHOLDER/$domain}"
  v2ray_config="${v2ray_config//UUID_PLACEHOLDER/$uuid}"
  v2ray_config_path="/usr/local/etc/v2ray/config.json"
  touch "${v2ray_config_path}"
  echo "$v2ray_config" >"${v2ray_config_path}"

  ##systemctl
  systemctl daemon-reload
  systemctl enable v2ray
  systemctl restart v2ray
}

prepare_nginx() {
  apt update
  apt install nginx -y
  ufw allow 'Nginx Full'

  ##prepare config
  nginx_config_path="/etc/nginx/sites-available/${domain}"

  nginx_config="$(cat ./nginx/80.conf)"
  nginx_config="${nginx_config//DOMAIN_PLACEHOLDER/$domain}"
  touch "${nginx_config_path}"
  echo "$nginx_config" >"${nginx_config_path}"
  ln -nsf "${nginx_config_path}" /etc/nginx/sites-enabled/
  ##restart
  systemctl reload nginx
  systemctl restart nginx

  #ssl
  ssl_content="$(cat ./nginx/ssl/certbot.conf)"
  snap install --classic certbot
  ln -nsf /snap/bin/certbot /usr/bin/certbot
  certbot certonly --nginx -d "${domain}" --non-interactive --agree-tos --register-unsafely-without-email
  nginx_config="$(cat ./nginx/443.conf)"
  nginx_config="${nginx_config//SSL_PLACEHOLDER/$ssl_content}"
  nginx_config="${nginx_config//DOMAIN_PLACEHOLDER/$domain}"
  echo -en "\n$nginx_config" >>"${nginx_config_path}"

  ##restart
  systemctl reload nginx
  systemctl restart nginx
}

prepare_vmessgen() {
  cp -rfa ./vmess/. /usr/local/bin/
  chmod +x /usr/local/bin/json2vmess.py
  chmod +x /usr/local/bin/vmessgen
  vmessgen
}

prepare_variables "$@" &&
  prepare_v2ray &&
  prepare_nginx &&
  prepare_vmessgen
