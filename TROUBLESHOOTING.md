# Crossword Pipeline — Troubleshooting

## "Word bank is empty for theme X"

The word bank JSON at `outputs/wordbanks/<theme>.json` contains no entries.

- Check `pipeline/themes-config.json`: verify the theme's `sources` paths exist and are not empty.
- Re-run `python3 scripts/build-wordbank.py --theme <theme>` and inspect console output for skipped words.
- If using a custom source file, confirm it has one word per line and the encoding is UTF-8.

## "Generator returns None"

The generator could not place enough words to meet `min_words` for the board size.

- The word bank is too small. Add more words to `data/allowlist.txt` for the theme.
- Alternatively, lower `min_words` in `pipeline/generator.py` `BOARD_SIZE_CONFIG` (not recommended for production packs).
- Run `python3 scripts/preview-puzzle.py` with `--verbose` to see placement attempts.

## "Validation fails: answer mismatch"

A puzzle entry's `answer` field disagrees with the letters in `solutionGrid` at its position.

- This usually means a puzzle file is stale. Re-run `python3 scripts/generate-pack.py --pack <pack-id>` to regenerate.
- If the mismatch persists, check for manual edits to the puzzle JSON that broke grid consistency.

## "iOS app shows legacy puzzles only"

The updated `crossword-packs-index.json` or individual pack files were not copied into the app bundle.

- Run `bash scripts/run-pipeline.sh` — it copies outputs to `SmartGames/Games/Crossword/Resources/` automatically.
- If copying manually, ensure both `outputs/packs-index.json` (renamed to `crossword-packs-index.json`) and all `outputs/packs/*.json` files are added to the Xcode target.
- Clean and rebuild the Xcode project after updating bundle resources.
