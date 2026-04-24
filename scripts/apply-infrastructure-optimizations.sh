#!/bin/bash
# ==========================================
# INFRASTRUCTURE OPTIMIZATION SCRIPT
# ==========================================
# Applies RAM optimizations to shared services (Poste.io, Homepage).

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ">>> Applying Infrastructure Optimizations..."

# 1. Restart Shared Stack to apply Docker Compose changes (Poste.io, etc)
cd "$BASE_DIR/shared"
echo "    Restarting shared stack..."
docker compose up -d --force-recreate

# 2. Optional: Tuning homepage refresh rate if needed
# (Already set to 3000ms, which is reasonable but could be 10000ms for more savings)
# sed -i 's/refresh: 3000/refresh: 10000/g' "$BASE_DIR/shared/homepage/settings.yaml"

echo ">>> Infrastructure optimizations applied!"
