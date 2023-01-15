# Install Vmess + WS + TLS (Ubuntu 18+)

This script was made to run vmess on ubuntu simply. since it needs HTTPS so you need a domain or subdomain.
first of all, you have to create an A record in your domain DNS zone to point to the ubuntu server IP.

for example, suppose your IP is `100.99.98.97` and your domain is `v2ray.test-domain.com`, so you should run command below on the ubuntu terminal to ensure your domain is set on the server:

`host v2ray.test-domain.com`

then you must see `100.99.98.97` to ensure all thing is okay.

---

**Lets start:**

just replace `v2ray.test-domain.com` with your real domain in the commands below and run them.

```
sudo su
```

```
sudo curl -s https://raw.githubusercontent.com/WLFM-CS/v2ray-mono/master/run.sh | bash -s -- -d v2ray.test-domain.com
```

by running the bash script above, it will download the required stuff and configure Nginx + SSL + v2ray.

after a while, if all things go ahead well it will show a vmess url that indicates VPN is ready to use.

finished. enjoy from your vmess url:)

---

#### You can leave this document now but if you want to know the advanced stuff you can read the continue

---

###### Additional notes:****

1. if you want to use your custom UUID while installation, you can pass it via the -u flag. for example:

```
sudo curl -s https://raw.githubusercontent.com/WLFM-CS/v2ray-mono/master/run.sh | bash -s -- -d v2ray.test-domain.com -u 7F0CDA5E-8698-43A8-AC3E-12EEEB4A28DF
```

2. Whenever you need to access to vmess link again, you can run the command below:

```
vmessgen
# OR
vmessgen -n MY-CUSTOM-VMESS
```

---

### V2ray Configuration:

v2ray config file is located on `/usr/local/etc/v2ray/config.json` and has content like:

```
{
  "inbounds": [
    {
      "tag": "inbound-s1",
      "protocol": "vmess",
      "port": 9010,
      "listen": "0.0.0.0",
      "settings": {
        "clients": [
          {
            "id": "7F0CDA5E-8698-43A8-AC3E-12EEEB4A28DF",
            "level": 1,
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "headers": {
            "Host": "v2ray.test-domain.com"
          },
          "path": "/"
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "outbound-s1",
      "protocol": "freedom"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "settings": {
      "rules": [
        {
          "inboundTag": [
            "inbound-s1"
          ],
          "outboundTag": "outbound-s1",
          "type": "field"
        }
      ]
    }
  },
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  }
}
```

as you can see there is a corresponding pattern between inbound and outbound. and you can create several inbounds and outbounds with custom tags and path and connect them by routing.settings.rules.

if you would like to know more about v2ray configuration you can see these links:

[https://www.v2ray.com/en/configuration/overview.html](https://www.v2ray.com/en/configuration/overview.html)

[https://www.v2fly.org/en_US/v5/config/overview.html](https://www.v2fly.org/en_US/v5/config/overview.html)

---

### V2ray Configuration in order to Tunnel between 2 servers:

if you want to connect 2 servers (aka Tunnel), you must install this script on both 2 servers. if all 2 v2rays work well separately, then finally you must edit the first(origin) server v2ray config to redirect the outbound to the second(destination) server.

**lets go:**

run command below on second(destination) server:

```
cat /usr/local/etc/v2ray/config.json
```

look inside `inbounds` and keep a copy of the id(UUID) and path(default path is "/") and Host(domain).

then go to first(origin) server and run command below:

```
nano /usr/local/etc/v2ray/config.json
```

find code below in `outbounds`:

```
    {
      "tag": "outbound-s1",
      "protocol": "freedom"
    }
```

and replace code above with code below and replace the id, address, path with id, host, path that you have coppied from another server:

```
    {
      "tag": "outbound-s1",
      "protocol": "vmess",
      "mux": {
        "enabled": true
      },
      "settings": {
        "vnext": [
          {
            "address": "destination.test-domain.com",
            "port": 443,
            "users": [
              {
                "id": "15fe440d-7866-49bf-a004-95e22084a000",
                "level": 1,
                "alterId": 0,
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": false
        },
        "wsSettings": {
          "path": "/"
        }
      }
    }
```

now after saving the file run the commands below to restart v2ray:

```
sudo systemctl restart v2ray
sudo systemctl status v2ray
```

finished. so when you use first server vmess, it redirects the outbounds to second server.

---

### Can I have 1 v2ray with 2 vmess urls to have a direct and tunneled connection?

yes, just you need to have 2 inbounds and 2 outbounds with different tags, paths, inbound ids. see the example:


```
{
  "inbounds": [
    {
      "tag": "inbound-direct",
      "protocol": "vmess",
      "port": 9010,
      "listen": "0.0.0.0",
      "settings": {
        "clients": [
          {
            "id": "b30e1ac5-1ca2-4fdd-97e2-48f848e0f2bb",
            "level": 1,
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "headers": {
            "Host": "v2ray.test-domain.com"
          },
          "path": "/direct"
        }
      }
    },
    {
      "tag": "inbound-tunnel",
      "protocol": "vmess",
      "port": 9010,
      "listen": "0.0.0.0",
      "settings": {
        "clients": [
          {
            "id": "f639c4c8-4705-46c7-a64d-618e1ee3982f",
            "level": 1,
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "headers": {
            "Host": "v2ray.test-domain.com"
          },
          "path": "/tunnel"
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "outbound-direct",
      "protocol": "freedom"
    },
    {
      "tag": "outbound-tunnel",
      "protocol": "vmess",
      "mux": {
        "enabled": true
      },
      "settings": {
        "vnext": [
          {
            "address": "destination.test-domain.com",
            "port": 443,
            "users": [
              {
                "id": "15fe440d-7866-49bf-a004-95e22084a000",
                "level": 1,
                "alterId": 0,
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": false
        },
        "wsSettings": {
          "path": "/"
        }
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "settings": {
      "rules": [
        {
          "inboundTag": [
            "inbound-direct"
          ],
          "outboundTag": "outbound-direct",
          "type": "field"
        },
        {
          "inboundTag": [
            "inbound-tunnel"
          ],
          "outboundTag": "outbound-tunnel",
          "type": "field"
        }
      ]
    }
  },
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  }
}
```
note: you can generate UUID with `uuidgen` command.
```
sudo systemctl restart v2ray
sudo systemctl status v2ray
vmessgen
```
---
This is a mono repo and gradually will be equipped with other OS and protocols. but as was said in the first the goal of this repo is to simplify the bootstrapping of a v2ray VPN. so if you are looking for an advanced and powerful script we suggest you use this:

[https://github.com/mack-a/v2ray-agent/blob/master/documents/en/README_EN.md](https://github.com/mack-a/v2ray-agent/blob/master/documents/en/README_EN.md)
