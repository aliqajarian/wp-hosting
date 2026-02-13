# Monitoring: Graphs, Metrics, and Uptime

This document explains how to monitor the health of your servers and containers.

## 1. Quick Stats (The Dashboard)
The Central Dashboard (`https://panel.yourdomain.com`) provides key metrics at a glance:
*   **System Load**: CPU/RAM usage of the host server.
*   **Container Stats**: For critical services (Database, Gateway, File Manager), you will see live CPU/RAM bars directly on the dashboard.

## 2. Detailed Graphs (Netdata)
If you need to see historical graphs or deep metrics for **every container**:
1.  Click the **Netdata** icon on the Dashboard.
2.  Or go to `https://monitor.yourdomain.com`.

**What you can see:**
*   **CPU per Container**: Go to `Applications` -> `docker` or `cgroups` on the right sidebar.
*   **Memory Usage**: Detailed breakdown of RAM usage per container.
*   **Network**: Check bandwidth usage of specific containers.
*   **Disk I/O**: See which container is writing heavily to disk.

> **Tip:** Netdata stores history locally. You can zoom out to see the last hour or day.

## 3. Container Management (Portainer)
If a container is misbehaving, use Portainer to inspect it.
1.  Click **Portainer** on the Dashboard.
2.  Go to `Containers`.
3.  Click the specific container (e.g., `client1_wp`).
4.  Click the **Stats** icon (chart symbol).
    *   This opens a **Live Graph** specific to that container, showing CPU/Memory/Network in real-time.

## 4. Uptime Monitoring (Uptime Kuma)
To ensure your sites are actually online:
1.  Go to `https://status.yourdomain.com` (Uptime Kuma).
2.  Add a monitor for each site (e.g., `https://client1.com`).
3.  Set up notifications (Telegram, Slack, Email) to alert you if a site goes down.
