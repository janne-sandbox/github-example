#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
catalog_dir="$script_dir/catalog"

command -v node >/dev/null 2>&1 || {
  echo "Node.js 18 or newer is required." >&2
  exit 1
}
command -v npm >/dev/null 2>&1 || {
  echo "npm is required." >&2
  exit 1
}
command -v npx >/dev/null 2>&1 || {
  echo "npx is required." >&2
  exit 1
}

if [ ! -f "$catalog_dir/package.json" ]; then
  echo "Creating EventCatalog project in $catalog_dir"
  npx --yes @eventcatalog/create-eventcatalog@latest "$catalog_dir" --use-npm
fi

node "$script_dir/update-catalog-source.mjs"

cd "$catalog_dir"
echo "Installing EventCatalog dependencies..."
npm install

echo "Building EventCatalog from the current catalog source..."
npm run build
