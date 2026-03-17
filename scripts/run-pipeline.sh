#!/usr/bin/env bash
set -e
echo "=== Crossword Content Pipeline ==="
python3 scripts/fetch-wordlists.py
python3 scripts/build-wordbank.py
python3 scripts/build-clues.py
python3 scripts/generate-pack.py --all
python3 scripts/validate-outputs.py
echo "=== Copying to iOS resources ==="
cp outputs/packs-index.json SmartGames/Games/Crossword/Resources/crossword-packs-index.json
cp outputs/packs/*.json SmartGames/Games/Crossword/Resources/
echo "=== Done ==="
