# Domain + HTTPS

Steps to attach a domain to the VM and issue a Let's Encrypt certificate.

Placeholder: replace `yourdomain.com` everywhere below with your real domain.

## 1. Point DNS at the VM

In your DNS provider (Cloudflare, Route53, Gabia, etc.) create one or two A records:

| Type | Name | Value |
| --- | --- | --- |
| A | `@` (apex) | `158.180.93.84` |
| A | `www` | `158.180.93.84` |

Wait for propagation (1–30 min usually). Verify from your PC:

```powershell
nslookup yourdomain.com
```

The answer must show `158.180.93.84`.

## 2. Reserve the public IP (recommended)

Right now the VM uses an ephemeral public IP. If the VM is stopped and started, the IP can change and break DNS.

OCI Console → Networking → Reserved IPs → **Reserve Public IP Address** → Compartment `knup` → Create. Then in the VM's VNIC, **Edit IP Address → Reserved Public IP** and pick the one you just created.

(This is a manual step. `compute.tf` ignores `create_vnic_details` changes for exactly this reason — Terraform will not undo it.)

## 3. Configure nginx with the domain

SSH into the VM and use the reverse-proxy template from this repo:

```bash
# from your PC, upload the template
scp vm/nginx/knup-app.conf ubuntu@158.180.93.84:/tmp/
```

On the VM:

```bash
sudo cp /tmp/knup-app.conf /etc/nginx/sites-available/knup-app
sudo sed -i 's/yourdomain.com/yourdomain.com/g' /etc/nginx/sites-available/knup-app
sudo ln -sf /etc/nginx/sites-available/knup-app /etc/nginx/sites-enabled/knup-app
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

Confirm HTTP still serves something on the new hostname:

```powershell
curl.exe -I http://yourdomain.com
```

## 4. Issue the certificate

On the VM:

```bash
sudo certbot --nginx \
  -d yourdomain.com -d www.yourdomain.com \
  --email you@example.com --agree-tos --no-eff-email --redirect
```

`--redirect` rewrites the nginx config to 301 from HTTP to HTTPS. Certbot installs a systemd timer that renews automatically every ~60 days.

Verify:

```powershell
curl.exe -I https://yourdomain.com
```

`HTTP/2 200` (or `301` if hitting apex without trailing slash) means done.

## 5. Renewal sanity check

```bash
sudo certbot renew --dry-run
```

If this succeeds, real renewals will succeed too.
