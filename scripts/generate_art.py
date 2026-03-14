# /// script
# dependencies = ["google-genai", "Pillow", "python-dotenv", "numpy"]
# ///

"""
Generate game art assets using Google Gemini and save them
directly into the Xcode asset catalogue.

Usage:
    uv run scripts/generate_art.py            # generate all assets
    uv run scripts/generate_art.py frying_pan  # generate one asset by name
"""

import json
import os
import sys
from io import BytesIO
from pathlib import Path

import numpy as np
from dotenv import load_dotenv
from google import genai
from PIL import Image

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent

load_dotenv(SCRIPT_DIR / ".env.local")

ASSETS_DIR = REPO_ROOT / "AdorableBites" / "Assets.xcassets"

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

PROMPT_TEMPLATE = (
    "A cute cartoon {description}, game art style, simple clean design, "
    "square aspect ratio 1:1, bright green #00FF00 background, "
    "suitable for a children's cooking game"
)

# Define the assets to generate: (name, description)
ASSETS = [
    # Ingredients
    ("flour", "bag of flour"),
    ("egg", "egg"),
    ("milk", "glass of milk"),
    ("butter", "stick of butter"),
    ("chocolate", "bar of chocolate"),
    # Kitchen
    ("frying_pan", "empty frying pan, top-down view"),
    ("induction_cooktop", "single induction cooktop burner, top-down view, circular heating zone with glass surface"),
    # Furniture
    ("bench_counter", "simple long rectangular wooden counter surface, warm wood grain, no objects on it, top-down view"),
    ("bar_stool", "single cute round wooden bar stool, top-down view"),
    ("pantry_cupboard", "wide horizontal open wooden pantry shelf with exactly 5 equal empty square compartments in a single horizontal row, no doors, warm wood tones, small blank label tag below each compartment, front-facing view, completely empty compartments"),
    # Mixing
    ("mixing_bowl", "cute empty mixing bowl, top-down view, no utensils inside"),
    ("unmixed_batter", "lumpy chunky unmixed batter with visible flour clumps and egg bits, circular blob shape, no bowl, transparent background, top-down view"),
    ("mixed_batter", "smooth creamy mixed batter, circular blob shape, no bowl, transparent background, top-down view"),
    # Pan states
    ("raw_batter_in_pan", "circle of raw poured pancake batter, pale yellow, no pan, transparent background, top-down view"),
    ("finished_pancake_in_pan", "single cooked golden brown pancake, no pan, transparent background, top-down view"),
    ("burnt_food", "generic charred blackened burnt food, dark brown and black, no pan, transparent background, top-down view"),
    # Furniture
    ("kitchen_counter", "large rectangular clean kitchen counter surface, light marble or light wood, no objects on it, top-down view"),
    # Plating
    ("plate", "single clean white dinner plate, top-down view, simple round plate, no food on it"),
    # Button icons (small, simple, icon-style — not detailed images)
    ("icon_whisk", "tiny cute cartoon whisk icon, simple minimal design, small icon size, no background"),
    ("icon_serve", "tiny cute cartoon serving cloche dome icon, simple minimal design, small icon size, no background"),
    # Dishes
    ("pancakes", "stack of pancakes with syrup on a plate"),
    # Customer animals (head/portrait only)
    ("customer_bear", "friendly bear face, front-facing portrait"),
    ("customer_cat", "friendly cat face, front-facing portrait"),
    ("customer_dog", "friendly dog face, front-facing portrait"),
    ("customer_bunny", "friendly bunny face, front-facing portrait"),
    ("customer_frog", "friendly frog face, front-facing portrait"),
]


def remove_green_background(image: Image.Image) -> Image.Image:
    """Replace green chroma key pixels with transparency."""
    img = image.convert("RGBA")
    data = np.array(img)

    r, g, b = data[:, :, 0], data[:, :, 1], data[:, :, 2]
    green_mask = (r < 120) & (g > 150) & (b < 120) & (g > r) & (g > b)

    data[green_mask] = [0, 0, 0, 0]
    return Image.fromarray(data)


def save_to_asset_catalogue(name: str, image: Image.Image) -> None:
    """Save a PIL image into Assets.xcassets as a proper image set."""
    imageset_dir = ASSETS_DIR / f"{name}.imageset"
    imageset_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{name}@2x.png"
    image.save(imageset_dir / filename)

    contents = {
        "images": [
            {
                "filename": filename,
                "idiom": "universal",
                "scale": "2x",
            }
        ],
        "info": {"author": "xcode", "version": 1},
    }
    with open(imageset_dir / "Contents.json", "w") as f:
        json.dump(contents, f, indent=2)

    print(f"  Saved to {imageset_dir}")


def generate_asset(name: str, description: str) -> None:
    """Generate a single asset using Gemini."""
    prompt = PROMPT_TEMPLATE.format(description=description)
    print(f"Generating: {name} ({description})...")

    response = client.models.generate_content(
        model="gemini-3.1-flash-image-preview",
        contents=[prompt],
    )

    for part in response.parts:
        if part.inline_data is not None:
            raw = BytesIO(part.inline_data.data)
            image = Image.open(raw)
            image = remove_green_background(image)
            bbox = image.getbbox()
            if bbox:
                image = image.crop(bbox)
                print(f"  Cropped from 1024x1024 to {image.size[0]}x{image.size[1]}")
            save_to_asset_catalogue(name, image)
            return

    print(f"  WARNING: No image generated for {name}")


def main() -> None:
    asset_dict = {name: desc for name, desc in ASSETS}
    filter_name = sys.argv[1] if len(sys.argv) > 1 else None

    if filter_name:
        if filter_name not in asset_dict:
            print(f"Unknown asset: {filter_name}")
            print(f"Available: {', '.join(asset_dict.keys())}")
            sys.exit(1)
        to_generate = [(filter_name, asset_dict[filter_name])]
    else:
        to_generate = ASSETS

    print(f"Asset catalogue: {ASSETS_DIR}")
    print(f"Generating {len(to_generate)} asset(s)...\n")

    for name, prompt in to_generate:
        generate_asset(name, prompt)

    print("\nDone! Re-run xcodegen to pick up new assets.")


if __name__ == "__main__":
    main()
