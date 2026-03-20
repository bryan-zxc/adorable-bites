# /// script
# dependencies = ["google-genai", "Pillow", "python-dotenv", "numpy"]
# ///

"""
Generate game art assets using Google Gemini and save them
directly into the Xcode asset catalogue.

Usage:
    uv run scripts/generate_art.py                        # generate all assets
    uv run scripts/generate_art.py frying_pan              # generate one asset by name
    uv run scripts/generate_art.py --prompt "description" --name my_asset  # custom prompt
    uv run scripts/generate_art.py --prompt "description" --name my_asset --ref image1.png image2.png
    uv run scripts/generate_art.py --prompt "description" --name my_asset --no-chroma
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

PLATE_SUFFIX = "served on a plate, side-on view, no table, no background elements"

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
    ("sink", "kitchen sink basin, top-down view, simple stainless steel or ceramic, empty, no taps"),
    ("dirty_plate", "single used dirty plate with food crumbs and sauce smears, top-down view, simple round plate, no knife, no fork, no cutlery, no utensils"),
    # Currency
    ("money", "cute small pile of gold coins, game art style, simple clean design, top-down view"),
    ("snowflake", "single cute sparkly snowflake, Frozen Elsa themed, light blue and white, ice crystal design"),
    # Egg recipes — pan states
    ("raw_egg_in_pan", "single cracked raw egg sunny side up, no pan, transparent background, top-down view"),
    ("fried_egg_in_pan", "single cooked fried egg sunny side up with crispy edges, no pan, transparent background, top-down view"),
    ("raw_scrambled_in_pan", "wet mixed raw egg liquid poured in circle shape, no pan, transparent background, top-down view"),
    ("scrambled_egg_in_pan", "cooked fluffy scrambled egg, no pan, transparent background, top-down view"),
    # Egg recipes — served dishes
    ("fried_egg_plate", "fried egg sunny side up, {plate}"),
    ("scrambled_egg_plate", "fluffy scrambled egg, {plate}"),
    # Mystery food (unrecognised recipe)
    ("mystery_raw_in_pan", "messy unknown raw food mixture blob, no pan, transparent background, top-down view"),
    ("mystery_cooked_in_pan", "messy unknown cooked food blob, no pan, transparent background, top-down view"),
    ("mystery_dish_plate", "messy unknown questionable food, {plate}"),
    # Restaurant
    ("door", "cute restaurant entrance door, wooden door with small window, front-facing view, warm colours"),
    ("restaurant_exterior", "cute cartoon restaurant building exterior, front-facing view, wooden door in centre, windows on each side, striped awning, warm cosy colours, wide landscape aspect"),
    # Button icons (small, simple, icon-style — not detailed images)
    ("icon_whisk", "tiny cute cartoon whisk icon, simple minimal design, small icon size, no background"),
    ("icon_serve", "tiny cute cartoon serving cloche dome icon, simple minimal design, small icon size, no background"),
    # Dishes
    ("pancakes_plate", "stack of pancakes with syrup, {plate}"),
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


def generate_asset(
    name: str,
    description: str,
    ref_images: list[Path] | None = None,
    skip_chroma: bool = False,
) -> None:
    """Generate a single asset using Gemini, optionally with reference images."""
    description = description.replace("{plate}", PLATE_SUFFIX)
    prompt = PROMPT_TEMPLATE.format(description=description)

    print(f"Generating: {name}")
    print(f"  Prompt: {prompt[:120]}...")

    # Build content list: text prompt + any reference images
    contents: list = [prompt]
    if ref_images:
        for ref_path in ref_images:
            print(f"  Reference image: {ref_path}")
            contents.append(Image.open(ref_path))

    response = client.models.generate_content(
        model="gemini-3.1-flash-image-preview",
        contents=contents,
    )

    for part in response.parts:
        if part.inline_data is not None:
            raw = BytesIO(part.inline_data.data)
            image = Image.open(raw)
            if not skip_chroma:
                image = remove_green_background(image)
            bbox = image.getbbox()
            if bbox:
                image = image.crop(bbox)
                print(f"  Cropped to {image.size[0]}x{image.size[1]}")
            save_to_asset_catalogue(name, image)
            return

    print(f"  WARNING: No image generated for {name}")


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Generate game art with Gemini")
    parser.add_argument("asset_name", nargs="?", help="Name of predefined asset to generate")
    parser.add_argument("--prompt", type=str, help="Custom prompt (use with --name)")
    parser.add_argument("--name", type=str, help="Asset name for custom prompt")
    parser.add_argument("--ref", nargs="+", type=str, help="Reference image path(s) to send alongside prompt")
    parser.add_argument("--no-chroma", action="store_true", help="Skip green background removal")

    args = parser.parse_args()

    print(f"Asset catalogue: {ASSETS_DIR}\n")

    if args.prompt and args.name:
        # Custom prompt mode with optional reference images
        ref_images = [Path(p) for p in args.ref] if args.ref else None
        generate_asset(
            args.name, args.prompt,
            ref_images=ref_images,
            skip_chroma=args.no_chroma,
        )
    elif args.asset_name:
        # Generate a predefined asset by name
        asset_dict = {name: desc for name, desc in ASSETS}
        if args.asset_name not in asset_dict:
            print(f"Unknown asset: {args.asset_name}")
            print(f"Available: {', '.join(asset_dict.keys())}")
            sys.exit(1)
        generate_asset(args.asset_name, asset_dict[args.asset_name])
    else:
        # Generate all predefined assets
        print(f"Generating {len(ASSETS)} asset(s)...\n")
        for name, prompt in ASSETS:
            generate_asset(name, prompt)

    print("\nDone! Re-run xcodegen to pick up new assets.")


if __name__ == "__main__":
    main()
