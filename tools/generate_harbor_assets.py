#!/usr/bin/env python3
"""Generate staged pixel-art harbor assets with OpenAI image generation.

Usage:
  export OPENAI_API_KEY=...
  python3 tools/generate_harbor_assets.py
"""

from __future__ import annotations

import argparse
import base64
import os
from pathlib import Path

from openai import OpenAI

ASSETS = {
    "harbor_stage_0_messy": (
        "Top-down-ish side-view pixel art background for a pre-steam wooden harbor. "
        "Early construction phase: muddy shoreline, broken temporary pier, scattered lumber, "
        "few crates, one tiny unfinished wooden hull frame, low activity. "
        "No characters, no text, clean readable silhouettes, game-ready background."
    ),
    "harbor_stage_1_structural": (
        "Pixel art harbor background, same camera and composition as stage 0. "
        "Now has sturdier dock sections, carpentry scaffolds, stacked timber, "
        "small warehouse shells, clear signs of active shipyard construction. "
        "Historical late age-of-sail vibe, no steam engines, no text."
    ),
    "harbor_stage_2_market": (
        "Pixel art harbor background, same framing as previous stages. "
        "Harbor is cleaner and more organized: warehouses complete, cargo lanes visible, "
        "more crates/barrels, one medium wooden sailing ship nearly complete, busy trade atmosphere. "
        "No text, no UI."
    ),
    "harbor_stage_3_prosperous": (
        "Pixel art harbor background, same framing as earlier stages. "
        "Prosperous wooden-ship port city just before steam era: multiple finished docks, "
        "one large historical-fantasy sailing vessel at berth, market stalls, ropes, cranes, "
        "rich detail but readable for a management sim. No text, no logos."
    ),
    "shipyard_crane_sprite": (
        "Single pixel art wooden dock crane sprite on transparent background, "
        "clean silhouette, 2D game asset, warm wood palette, no text."
    ),
    "crate_stack_sprite": (
        "Single pixel art crate stack sprite on transparent background, "
        "wooden cargo boxes, readable edges, 2D game asset, no text."
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate OpenAI image assets for the harbor prototype")
    parser.add_argument("--model", default="gpt-image-1.5", help="OpenAI image model")
    parser.add_argument("--size", default="1024x1024", help="Output size, e.g. 1024x1024")
    parser.add_argument(
        "--out-dir",
        default="sprites/generated",
        help="Output directory relative to project root",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite files that already exist",
    )
    return parser.parse_args()


def ensure_api_key() -> None:
    if not os.getenv("OPENAI_API_KEY"):
        raise SystemExit("OPENAI_API_KEY is not set.")


def generate_one(client: OpenAI, model: str, size: str, prompt: str, out_path: Path) -> None:
    response = client.images.generate(
        model=model,
        prompt=prompt,
        size=size,
    )

    b64_data = response.data[0].b64_json
    image_bytes = base64.b64decode(b64_data)
    out_path.write_bytes(image_bytes)


def main() -> None:
    args = parse_args()
    ensure_api_key()

    root = Path(__file__).resolve().parents[1]
    out_dir = root / args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    client = OpenAI()

    for name, prompt in ASSETS.items():
        out_path = out_dir / f"{name}.png"
        if out_path.exists() and not args.overwrite:
            print(f"skip   {out_path} (exists; use --overwrite)")
            continue

        print(f"build  {out_path.name}")
        generate_one(client, args.model, args.size, prompt, out_path)
        print(f"saved  {out_path}")

    print("done")


if __name__ == "__main__":
    main()
