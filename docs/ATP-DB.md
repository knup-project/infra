# Connecting the app to the Autonomous Database

ATP requires a "wallet" — a zip with the certs and connection profiles — instead of plain `host:port`. This guide downloads the wallet from OCI, ships it to the VM, and connects from Node.js.

## 1. Download the wallet

OCI Console → **Oracle Database → Autonomous Database** → `KNUP-ATP` → **Database connection** button → **Download Wallet**.

- Wallet type: **Instance Wallet** (single-db)
- Password: pick a strong wallet password — keep it, you'll need it to load the wallet
- Save the file (e.g. `Wallet_KNUPDB.zip`) to your PC

> "Wallet password" is **not** the ATP admin password. It just protects the keystore inside the zip.

## 2. Ship it to the VM

From your PC:

```powershell
scp Wallet_KNUPDB.zip ubuntu@158.180.93.84:/tmp/
```

On the VM:

```bash
sudo mkdir -p /opt/knup/wallet
sudo unzip /tmp/Wallet_KNUPDB.zip -d /opt/knup/wallet
sudo chown -R ubuntu:ubuntu /opt/knup/wallet
sudo chmod 600 /opt/knup/wallet/*
rm /tmp/Wallet_KNUPDB.zip
```

Inside the wallet, find the service names you can use:

```bash
grep -oE '^[a-zA-Z0-9_]+ ?=' /opt/knup/wallet/tnsnames.ora | sed 's/ ?=//'
```

Typical names: `knupdb_high`, `knupdb_medium`, `knupdb_low`, `knupdb_tp`, `knupdb_tpurgent`.

## 3. Node.js connection (oracledb)

In the app repo:

```bash
npm install oracledb
```

`db.js`:

```js
import oracledb from "oracledb";

await oracledb.createPool({
  user:               process.env.ATP_USER,            // "ADMIN" or an app user you created
  password:           process.env.ATP_PASSWORD,        // admin password from terraform.tfvars
  connectString:      process.env.ATP_CONNECT_STRING,  // e.g. "knupdb_low"
  configDir:          process.env.TNS_ADMIN,           // /opt/knup/wallet
  walletLocation:     process.env.TNS_ADMIN,           // same dir
  walletPassword:     process.env.WALLET_PASSWORD,     // the password from step 1
  poolMin: 1,
  poolMax: 4,
  poolIncrement: 1,
});

export async function query(sql, binds = []) {
  const conn = await oracledb.getConnection();
  try {
    const r = await conn.execute(sql, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    return r.rows;
  } finally {
    await conn.close();
  }
}
```

`/opt/knup/app/.env`:

```env
TNS_ADMIN=/opt/knup/wallet
ATP_USER=ADMIN
ATP_PASSWORD=<your atp_admin_password>
ATP_CONNECT_STRING=knupdb_low
WALLET_PASSWORD=<wallet password from step 1>
```

> Pool size on a 1 GB VM: keep `poolMax` small (≤ 4). Each oracle connection holds memory.

## 4. Verify

On the VM:

```bash
cd /opt/knup/app
node -e "
import('./db.js').then(async ({ query }) => {
  const r = await query('select 1 as ok from dual');
  console.log(r);
  process.exit(0);
}).catch(e => { console.error(e); process.exit(1); });
"
```

Expected output: `[ { OK: 1 } ]`.

If you get `ORA-12506` or TLS errors, double-check that the wallet files are present and readable, and that `TNS_ADMIN` points at the unzipped directory (not the zip).

## 5. Don't forget

- Add `WALLET_PASSWORD`, `ATP_PASSWORD` to your secret store / `.env` only — never commit
- For production, create a non-ADMIN user with only the privileges your app needs (`CREATE SESSION`, table grants), and put that into `ATP_USER` instead of `ADMIN`
