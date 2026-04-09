#!/bin/bash
set -e

BASE_URL="${BASE_URL:-http://localhost:8080}"
SEED_FILE="${1:-artists.seed.json}"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

if [[ ! -f "$SEED_FILE" ]]; then
  echo "Error: seed file not found: $SEED_FILE"
  exit 1
fi

TOTAL=$(jq 'length' "$SEED_FILE")
echo "Seeding $TOTAL artists from $SEED_FILE..."

for i in $(seq 0 $((TOTAL - 1))); do
  ARTIST=$(jq -c ".[$i]" "$SEED_FILE")
  NAME=$(echo "$ARTIST" | jq -r '.name')

  echo ""
  echo "[$((i+1))/$TOTAL] Creating: $NAME"
  RESPONSE=$(curl -sf -X POST "$BASE_URL/api/v1/artists" \
    -H "Content-Type: application/json" \
    -d "$ARTIST")

  ARTIST_ID=$(echo "$RESPONSE" | jq -r '.id')
  if [[ -z "$ARTIST_ID" || "$ARTIST_ID" == "null" ]]; then
    echo "  Error: failed to create artist. Response: $RESPONSE"
    continue
  fi

  echo "  Created with ID: $ARTIST_ID"
done

echo ""
echo "Seeding complete."
