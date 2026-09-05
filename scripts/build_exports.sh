#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" ]]; then
  GODOT_BIN="$(command -v godot4 || command -v godot || true)"
fi

if [[ -z "$GODOT_BIN" ]]; then
  echo "Erro: Godot 4 não encontrado. Defina GODOT_BIN=/caminho/para/godot." >&2
  exit 1
fi

mkdir -p build/windows build/linux build/web
"$GODOT_BIN" --headless --path . --export-release Windows build/windows/Cronicas-de-Lumen.exe
"$GODOT_BIN" --headless --path . --export-release Linux build/linux/Cronicas-de-Lumen.x86_64
"$GODOT_BIN" --headless --path . --export-release Web build/web/index.html
chmod +x build/linux/Cronicas-de-Lumen.x86_64

echo "Exportações criadas em $(pwd)/build"
