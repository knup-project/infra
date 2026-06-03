# App deployment

Brings up the Node.js app on the VM behind nginx, managed by PM2.

Assumptions (set by earlier choices):
- App lives in a **private GitHub repo**, accessed via a **deploy key**
- Start command is `npm start`
- App listens on `127.0.0.1:3000`

## 1. Generate a deploy key on the VM

On the VM:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/knup_deploy -C "knup-deploy" -N ""
cat ~/.ssh/knup_deploy.pub
```

Copy the public key output.

## 2. Register the deploy key in GitHub

In your **app** repo (not infra) on GitHub:
- Settings → Deploy keys → **Add deploy key**
- Title: `knup-vm`
- Key: paste the public key from step 1
- Allow write access: **leave unchecked** (read-only is enough for pull)

Tell SSH which key to use for github.com:

```bash
cat >> ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/knup_deploy
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config

# verify
ssh -T git@github.com
# expected: "Hi <user>/<repo>! You've successfully authenticated..."
```

## 3. Clone the app

```bash
sudo mkdir -p /opt/knup/app
sudo chown ubuntu:ubuntu /opt/knup/app
git clone git@github.com:YOUR_ORG/YOUR_APP.git /opt/knup/app
cd /opt/knup/app
npm ci
```

Put any environment variables in `/opt/knup/app/.env` (or wherever your app reads them). **Never commit `.env`.**

## 4. Bring up the process with PM2

From your PC, upload the PM2 ecosystem file:

```powershell
scp vm\pm2\ecosystem.config.cjs ubuntu@158.180.93.84:/opt/knup/
```

On the VM:

```bash
sudo mkdir -p /var/log/knup && sudo chown ubuntu:ubuntu /var/log/knup
cd /opt/knup
pm2 start ecosystem.config.cjs
pm2 save

# make PM2 survive reboot
pm2 startup systemd -u ubuntu --hp /home/ubuntu
# the previous command prints a `sudo env PATH=...` line — copy and run it
```

Sanity check on the VM:

```bash
pm2 status
curl -sI http://127.0.0.1:3000 | head -3
```

## 5. Front it with nginx

From your PC:

```powershell
scp vm\nginx\knup-app.conf ubuntu@158.180.93.84:/tmp/
```

On the VM:

```bash
sudo cp /tmp/knup-app.conf /etc/nginx/sites-available/knup-app

# until you have a domain: tell nginx this is the default vhost so it
# answers requests sent directly to the IP
sudo sed -i 's/server_name yourdomain.com www.yourdomain.com;/server_name _;/' \
  /etc/nginx/sites-available/knup-app

sudo ln -sf /etc/nginx/sites-available/knup-app /etc/nginx/sites-enabled/knup-app
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

From your PC PowerShell:

```powershell
curl.exe http://158.180.93.84
```

You should now see your app's response instead of the nginx welcome page.

When the domain is ready, follow [HTTPS.md](./HTTPS.md) — that swaps `server_name _` back to your real hostname and adds the certificate.

## 6. Deploying new versions

```bash
cd /opt/knup/app
git pull
npm ci --omit=dev
pm2 reload knup-app
```

`pm2 reload` is a zero-downtime restart.
