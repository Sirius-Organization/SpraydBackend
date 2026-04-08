#!/bin/bash
set -e

BASE_URL="${BASE_URL:-http://localhost:8080}"
EMAIL="${EMAIL:-test@example.com}"
PASSWORD="${PASSWORD:-Password1}"
SEED_FILE="${1:-seed.json}"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

if [[ ! -f "$SEED_FILE" ]]; then
  echo "Error: seed file not found: $SEED_FILE"
  exit 1
fi

# Login
echo "Logging in as $EMAIL..."
TOKEN=$(curl -sf -X POST "$BASE_URL/auth/login" \
  -u "$EMAIL:$PASSWORD" | jq -r '.token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "Error: login failed"
  exit 1
fi
echo "Authenticated."

# Seed items
TOTAL=$(jq 'length' "$SEED_FILE")
echo "Seeding $TOTAL art items from $SEED_FILE..."

for i in $(seq 0 $((TOTAL - 1))); do
  ITEM=$(jq -c ".[$i]" "$SEED_FILE")
  NAME=$(echo "$ITEM" | jq -r '.name')
  IMAGE_URLS=$(echo "$ITEM" | jq -c '[.imageUrls // [] | .[]]')
  PAYLOAD=$(echo "$ITEM" | jq -c 'del(.imageUrls)')

  echo ""
  echo "[$((i+1))/$TOTAL] Creating: $NAME"
  RESPONSE=$(curl -sf -X POST "$BASE_URL/art-items" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

  ITEM_ID=$(echo "$RESPONSE" | jq -r '.id')
  if [[ -z "$ITEM_ID" || "$ITEM_ID" == "null" ]]; then
    echo "  Error: failed to create item. Response: $RESPONSE"
    continue
  fi
  echo "  Created with ID: $ITEM_ID"

  # Upload image URLs
  URL_COUNT=$(echo "$IMAGE_URLS" | jq 'length')
  for j in $(seq 0 $((URL_COUNT - 1))); do
    IMG_URL=$(echo "$IMAGE_URLS" | jq -r ".[$j]")
    echo "  Adding image URL: $IMG_URL"
    curl -sf -X POST "$BASE_URL/art-items/$ITEM_ID/image-url" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"url\": \"$IMG_URL\"}" >/dev/null
    echo "  Done."
  done
done

echo ""
echo "Seeding complete."
