#!/usr/bin/env sh
# Rebuilds the web bundle and captures every variant into docs/.
# Needs Flutter and a Chrome on PATH. Run from the example's root.
set -eu

out=docs
port=8731

flutter build web --release -t tool/screenshots.dart

dart run tool/serve.dart build/web "$port" &
server=$!
trap 'kill $server 2>/dev/null || true' EXIT INT TERM
sleep 6

shoot() {
  google-chrome --headless=new --disable-gpu --hide-scrollbars \
    --virtual-time-budget=12000 --window-size="$3" \
    --screenshot="$out/$1.png" "http://127.0.0.1:$port/index.html?shot=$2"
  echo "wrote $out/$1.png"
}

mkdir -p "$out"
shoot after-light after-light 420,860
shoot after-dark  after-dark  420,860
shoot before      before      420,860
shoot tv          tv          1280,720
