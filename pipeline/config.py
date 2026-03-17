"""Load and validate pipeline configuration from themes-config.json."""

import json
import os
from pathlib import Path

# Resolve config path relative to this file's directory
_CONFIG_PATH = Path(__file__).parent / "themes-config.json"


def load_config(config_path: str | None = None) -> dict:
    """Load and validate themes-config.json.

    Args:
        config_path: Optional override path. Defaults to pipeline/themes-config.json.

    Returns:
        Validated config dict with keys: themes, global, boardSizes.

    Raises:
        FileNotFoundError: If config file does not exist.
        ValueError: If required top-level keys are missing.
    """
    path = Path(config_path) if config_path else _CONFIG_PATH

    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")

    with open(path, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    # Validate required top-level keys
    required_keys = {"themes", "global", "boardSizes"}
    missing = required_keys - set(cfg.keys())
    if missing:
        raise ValueError(f"Config missing required keys: {missing}")

    # Validate each theme has required fields
    for theme_name, theme_cfg in cfg["themes"].items():
        if "sources" not in theme_cfg:
            raise ValueError(f"Theme '{theme_name}' missing 'sources' field")
        if "targetDifficulty" not in theme_cfg:
            raise ValueError(f"Theme '{theme_name}' missing 'targetDifficulty' field")

    return cfg
