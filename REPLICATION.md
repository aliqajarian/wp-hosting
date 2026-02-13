# Replication & Backups

This document explains how to secure your data and set up replication between servers.
We use **Syncthing** for continuous file synchronization and standard tools for Database Dumps.

## 1. Automated Local Backups
The system includes a script (`scripts/rotate-backups.sh`) that:
1.  Exports every WordPress Database to `.sql`.
2.  Compresses the `sites/` folder.
3.  Keeps the last 7 days of backups in `backups/`.

**To enable:**
Run `./manage.sh -> Option 7 -> Setup Daily Cron Job`.
This will run the backup every day at 3 AM.

---

## 2. Server-to-Server Replication (Disaster Recovery)
You can sync your `sites/` folder (including backups) to a second VPS (Replica).

### Step 1: Pair the Servers
1.  Log in to **Server A** (Manager) and **Server B** (Replica).
2.  Run `./manage.sh -> Option 7 -> Replication Setup` on **BOTH**.
3.  Copy the **Device ID** from Server A.
4.  On Server B, select **Add Remote Peer** and paste Server A's ID.
5.  Repeat the process (Copy Server B's ID to Server A).

### Step 2: Share the 'sites' Folder
Once paired:
1.  Go to the Syncthing GUI on **Server A**: `http://server-a-ip:8384`.
2.  Edit the `sites` folder.
3.  Check the box for **Server B** in the "Sharing" tab.
4.  Save.
5.  Go to **Server B's GUI**.
6.  You will see a prompt to accept the folder. Accept it.

### Step 3: Handle User Permissions (Crucial!)
When files arrive on Server B, the system users (e.g. `client1`) might not exist yet.
1.  On **Server B**, run `./manage.sh`.
2.  Select **Option 7 -> Import Synced Users**.
3.  This script creates the missing Linux users and fixes file permissions automatically.
