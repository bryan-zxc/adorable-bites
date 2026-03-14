# /// script
# dependencies = ["google-genai", "Pillow", "python-dotenv", "numpy"]
# ///

"""
Edit an existing image using Google Gemini and replace it in place
with a transparent background.

Usage:
    uv run scripts/edit_art.py <image_path> "<prompt>"

Example:
    uv run scripts/edit_art.py AdorableBites/Assets.xcassets/flour.imageset/flour@2x.png "change the background to bright green #00FF00"
"""

import os
import sys
from pathlib import Path

import numpy as np
from dotenv import load_dotenv
from google import genai
from PIL import Image

SCRIPT_DIR = Path(__file__).resolve().parent
load_dotenv(SCRIPT_DIR / ".env.local")

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])


def remove_green_background(image: Image.Image) -> Image.Image:
    """Replace green chroma key pixels with transparency."""
    img = image.convert("RGBA")
    data = np.array(img)

    r, g, b = data[:, :, 0], data[:, :, 1], data[:, :, 2]
    green_mask = (r < 120) & (g > 150) & (b < 120) & (g > r) & (g > b)

    data[green_mask] = [0, 0, 0, 0]
    return Image.fromarray(data)


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: uv run scripts/edit_art.py <image_path> \"<prompt>\"")
        sys.exit(1)

    image_path = Path(sys.argv[1])
    prompt = sys.argv[2]

    if not image_path.exists():
        print(f"File not found: {image_path}")
        sys.exit(1)

    print(f"Loading: {image_path}")
    source_image = Image.open(image_path)

    print(f"Prompt: {prompt}")
    print("Sending to Gemini...")

    response = client.models.generate_content(
        model="gemini-3.1-flash-image-preview",
        contents=[prompt, source_image],
    )

    for part in response.parts:
        if part.inline_data is not None:
            from io import BytesIO
            raw = BytesIO(part.inline_data.data)
            pil_image = Image.open(raw)
            result = remove_green_background(pil_image)
            bbox = result.getbbox()
            if bbox:
                result = result.crop(bbox)
                print(f"Cropped to {result.size[0]}x{result.size[1]}")
            result.save(image_path)
            print(f"Saved to: {image_path}")
            return

    print("WARNING: No image returned from Gemini")


if __name__ == "__main__":
    main()
