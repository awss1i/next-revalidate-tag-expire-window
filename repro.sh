#!/usr/bin/env bash
# Builds once, then for /static and /dynamic: revalidateTag('t1', { expire: 15 }),
# lets the next request regenerate the entry, and requests the page again after
# the 15 s window. Set EXPIRE to change the window.
set -u
cd "$(dirname "$0")"
PORT=${PORT:-3000}
EXPIRE=${EXPIRE:-15}
BASE="http://localhost:$PORT"
export NEXT_TELEMETRY_DISABLED=1

echo Old > data.txt
npx next build > build.log 2>&1 || { echo "next build failed, see build.log"; exit 1; }
rm -rf .next.build && cp -a .next .next.build

run() {
  local page=$1 log="server-$1.log"
  rm -rf .next && cp -a .next.build .next
  echo Old > data.txt
  npx next start -p "$PORT" > "$log" 2>&1 &
  local server=$!
  for _ in $(seq 1 120); do grep -q "Ready in" "$log" && break; sleep 0.25; done
  local t0; t0=$(date +%s%3N)
  get() {
    local out cache value
    out=$(curl -s -D - "$BASE/$page")
    cache=$(printf '%s' "$out" | tr -d '\r' | awk -F': ' 'tolower($1)=="x-nextjs-cache"{print $2}')
    value=$(printf '%s' "$out" | grep -o 'id="value">[^<]*' | head -1 | sed 's/id="value">//')
    printf '%6ss  /%-8s x-nextjs-cache=%-5s value=%-5s getValue runs=%s\n' \
      "$(awk -v a="$(date +%s%3N)" -v b="$t0" 'BEGIN { printf "%.1f", (a - b) / 1000 }')" \
      "$page" "${cache:--}" "${value:--}" "$(grep -c '\[repro\] getValue ran' "$log")"
  }
  echo "== /$page"
  get
  echo New > data.txt; echo "        data.txt -> New"
  curl -s -o /dev/null "$BASE/api/revalidate?expire=$EXPIRE"; echo "        revalidateTag('t1', { expire: $EXPIRE })"
  get
  sleep 2
  get
  echo Newer > data.txt; echo "        data.txt -> Newer (no revalidation)"
  sleep $((EXPIRE))
  get
  sleep 2
  get
  kill $server; wait $server 2>/dev/null
}

run static
run dynamic
echo Old > data.txt
