# App deployment

Brings up the **Spring Boot backend + MySQL** on the VM with Docker Compose,
behind nginx. cloud-init already installed Docker + the compose plugin.

Assumptions:
- Backend image is built & pushed to `ghcr.io/knup-project/backend:latest` by
  the **backend** repo's `Build & Push Backend Image` workflow.
- The stack is defined in [`vm/docker-compose.yml`](../vm/docker-compose.yml).
- nginx fronts the backend on `127.0.0.1:8080` (see [`vm/nginx/knup-app.conf`](../vm/nginx/knup-app.conf)).

## 1. Upload compose + env to the VM

From your PC (replace the IP with the current `instance_public_ip` output):

```bash
scp vm/docker-compose.yml ubuntu@144.24.92.17:/opt/knup/docker-compose.yml
scp vm/.env.example       ubuntu@144.24.92.17:/opt/knup/.env
```

On the VM, fill in real secrets and lock the file down:

```bash
nano /opt/knup/.env        # set DB_PASSWORD, DB_ROOT_PASSWORD
chmod 600 /opt/knup/.env
```

## 2. Authenticate to GitHub Container Registry

The image is private, so the VM needs a token with `read:packages`. Create a
GitHub PAT (classic, scope `read:packages`) and on the VM:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u <github-username> --password-stdin
```

(Alternatively, make the `backend` package public in the org's Packages settings
and skip this step.)

## 3. Bring up the stack

```bash
cd /opt/knup
docker compose pull
docker compose up -d
docker compose ps
```

Sanity check on the VM:

```bash
curl -sI http://127.0.0.1:8080/actuator/health 2>/dev/null || curl -sI http://127.0.0.1:8080 | head -3
docker compose logs --tail=50 backend
```

## 4. Front it with nginx

```bash
scp vm/nginx/knup-app.conf ubuntu@144.24.92.17:/tmp/
```

On the VM:

```bash
sudo cp /tmp/knup-app.conf /etc/nginx/sites-available/knup-app
# until a domain exists, answer requests sent directly to the IP
sudo sed -i 's/server_name yourdomain.com www.yourdomain.com;/server_name _;/' \
  /etc/nginx/sites-available/knup-app
sudo ln -sf /etc/nginx/sites-available/knup-app /etc/nginx/sites-enabled/knup-app
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

From your PC: `curl http://144.24.92.17` should now hit the backend.

When a domain is ready, follow [HTTPS.md](./HTTPS.md).

## 5. Deploying new versions

After the backend CI pushes a new image:

```bash
cd /opt/knup
docker compose pull
docker compose up -d        # recreates only changed containers
docker image prune -f
```
