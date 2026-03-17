# License Notes — Word List Sources

This project's content pipeline downloads word lists from third-party sources at **build time only**.
These files are **not bundled into the iOS app** and are not distributed to end users.

---

## Word List Sources

### 1. imsky/wordlists
- **URL**: https://github.com/imsky/wordlists
- **License**: MIT
- **Usage**: Topic-specific word lists (animals, foods, sports, music, etc.)
- **Download path**: `data/raw/imsky/`

### 2. BartMassey/wordlists
- **URL**: https://github.com/BartMassey/wordlists
- **License**: MIT
- **Usage**: Top-5000 frequency word list for popularity scoring
- **Download path**: `data/raw/bartmassey/`

### 3. christophsjones/crossword-wordlist
- **URL**: https://github.com/christophsjones/crossword-wordlist
- **License**: MIT
- **Usage**: Crossword-optimized word corpus (reserved for future phases)
- **Download path**: `data/raw/christophsjones/`

---

## Important Notes

- All three sources are MIT licensed, permitting free use, modification, and distribution.
- Word lists are consumed **only during the pipeline build process** on developer machines or CI.
- The generated puzzle JSON files (outputs in `outputs/packs/`) contain only the selected words
  and clues — no raw word list data is shipped.
- The app bundles only the final puzzle packs under `SmartGames/Games/Crossword/Resources/`.
