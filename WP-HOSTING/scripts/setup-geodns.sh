#!/bin/bash
# ==========================================
# GEO-DNS SETUP SCRIPT (BIND9) - Per-Domain Routing
# ==========================================
# This script configures a BIND9 server to route traffic based on geolocation.
# It supports adding MULTIPLE domains, each with its own 'Main' and 'Replica' IP.
# Usage: ./setup-geodns.sh

# Directory Config
BIND_DIR="/opt/wp-hosting/shared/bind9"
CONFIG_DIR="$BIND_DIR/config"
RECORDS_DIR="$BIND_DIR/records"

# Check execution context
mkdir -p "$CONFIG_DIR" "$RECORDS_DIR"

echo ">>> GeoDNS Configuration Wizard"
echo "This server will act as the Authoritative DNS."
echo ""
echo "What would you like to do?"
echo "1. Initialize/Reset Server (Download IP Lists + Base Config)"
echo "2. Add/Update a Domain Zone"
echo "3. Restart DNS Service"
read -p "Select [1-3]: " CHOICE

# Function to generate Zone File
generate_zone() {
    local ZONE_FILE=$1
    local DOMAIN=$2
    local TARGET_IP=$3
    local NS_IP=$4
    local SERIAL=$(date +%Y%m%d01)
    
cat <<EOF > "$ZONE_FILE"
\$TTL 3600
@   IN  SOA ns1.$DOMAIN. admin.$DOMAIN. (
        $SERIAL ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400 )    ; Minimum TTL

; Nameservers
@       IN  NS      ns1.$DOMAIN.
@       IN  NS      ns2.$DOMAIN.

; A Records
@       IN  A       $TARGET_IP
www     IN  A       $TARGET_IP
*       IN  A       $TARGET_IP

; NS Records (Glue)
ns1     IN  A       $NS_IP
ns2     IN  A       $NS_IP
EOF
}

if [ "$CHOICE" == "1" ]; then
    # --- INITIALIZATION ---
    echo "--> Downloading Iran IP Ranges (CIDR)..."
    IRAN_CIDR_URL="https://raw.githubusercontent.com/herrbischoff/country-ip-blocks/master/ipv4/ir.cidr"
    
    echo "acl \"iran\" {" > "$CONFIG_DIR/named.conf.iran-acl"
    curl -s "$IRAN_CIDR_URL" | sed 's/$/;/' >> "$CONFIG_DIR/named.conf.iran-acl"
    echo "};" >> "$CONFIG_DIR/named.conf.iran-acl"
    
    if [ ! -s "$CONFIG_DIR/named.conf.iran-acl" ]; then
        echo "Error: Failed to download IP list."
        exit 1
    fi
    
    # Create Base Named Conf
    cat <<EOF > "$CONFIG_DIR/named.conf"
options {
    directory "/var/cache/bind";
    recursion no;
    allow-transfer { none; };
    listen-on { any; };
    listen-on-v6 { any; };
};

include "/etc/bind/named.conf.iran-acl";

# VIEW: IRAN (Domestic Traffic)
view "iran" {
    match-clients { iran; };
    recursion no;
    include "/etc/bind/named.conf.zones.iran";
};

# VIEW: WORLD (International Traffic)
view "world" {
    match-clients { any; };
    recursion no;
    include "/etc/bind/named.conf.zones.world";
};
EOF
    
    # Create empty zone lists
    touch "$CONFIG_DIR/named.conf.zones.iran"
    touch "$CONFIG_DIR/named.conf.zones.world"
    
    echo "Initialization Complete. Now add domains (Option 2)."

elif [ "$CHOICE" == "2" ]; then
    # --- ADD DOMAIN ---
    echo ""
    echo "--> Add New Domain Zone"
    read -p "Domain Name (e.g. client1.com): " DOMAIN
    read -p "International Server IP (Main): " WORLD_IP
    read -p "Iran Server IP (Replica/Local): " IRAN_IP
    # We need the NS IP (This Server) to be the glue record
    # Usually this server's public IP
    MY_IP=$(curl -s ifconfig.me) 
    read -p "Enter THIS Server's Public IP [$MY_IP]: " NS_IP
    NS_IP=${NS_IP:-$MY_IP}
    
    echo "Configuring $DOMAIN..."
    echo "  - World -> $WORLD_IP"
    echo "  - Iran  -> $IRAN_IP"
    
    # 1. Generate Zone Files
    generate_zone "$RECORDS_DIR/db.$DOMAIN.world" "$DOMAIN" "$WORLD_IP" "$NS_IP"
    generate_zone "$RECORDS_DIR/db.$DOMAIN.iran" "$DOMAIN" "$IRAN_IP" "$NS_IP"
    
    # 2. Append to Zone Configs (if not exists)
    # Check if domain already exists in config to avoid duplicates
    if ! grep -q "zone \"$DOMAIN\"" "$CONFIG_DIR/named.conf.zones.world"; then
        # Append to World Config
        cat <<EOF >> "$CONFIG_DIR/named.conf.zones.world"
zone "$DOMAIN" {
    type master;
    file "/var/lib/bind/db.$DOMAIN.world";
};
EOF
        # Append to Iran Config
        cat <<EOF >> "$CONFIG_DIR/named.conf.zones.iran"
zone "$DOMAIN" {
    type master;
    file "/var/lib/bind/db.$DOMAIN.iran";
};
EOF
        echo "  [SUCCESS] Zone added to configuration."
    else
        echo "  [INFO] Zone config exists, updated zone files only."
    fi
    
    # 3. Reload
    chmod -R 777 "$RECORDS_DIR" "$CONFIG_DIR"
    echo "  Reloading BIND..."
    cd "$BIND_DIR" && docker compose exec bind9 rndc reload >/dev/null 2>&1 || docker compose restart

    echo "Done. Don't forget to set Nameservers for $DOMAIN to ns1.$DOMAIN / ns2.$DOMAIN (IP: $NS_IP)"

elif [ "$CHOICE" == "3" ]; then
    echo "Restarting DNS Service..."
    cd "$BIND_DIR" && docker compose down && docker compose up -d
fi
