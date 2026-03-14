---
name: generate-art
description: Generate and manage game art assets for Adorable Bites. Use this skill whenever the user asks to generate, create, edit, modify, regenerate, or crop game art, images, sprites, icons, or visual assets — even if they just say "generate an image for X" or "make the X look different". Also trigger when adding new visual elements to the game that will need artwork.
---

# Generate Art

All game art is generated via Python scripts that call Google Gemini's image generation API. Never generate images any other way (no DALL-E, no inline base64, no manual drawing).

## Generating new assets

### 1. Add the asset to the ASSETS list

Open `scripts/generate_art.py` and add a tuple to the `ASSETS` list:

```python
("asset_name", "description of the image you want"),
```

The description gets wrapped in a prompt template that adds "cute cartoon", "game art style", and "green #00FF00 background" automatically — so focus the description on what the subject looks like, the viewing angle, and what should or shouldn't be included.

Tips for good descriptions:
- Specify the view angle (e.g. "top-down view", "front-facing")
- If the image will be layered on top of another sprite, say "no bowl" / "no pan" / "transparent background" so you get just the subject
- Be specific about quantity and arrangement (e.g. "exactly 5 equal compartments in a single horizontal row")

### 2. Run the generator

```bash
# Generate a single asset by name
uv run scripts/generate_art.py asset_name

# Generate all assets (rarely needed — only for a full rebuild)
uv run scripts/generate_art.py
```

The script automatically:
- Generates a 1024x1024 image via Gemini
- Removes the green chroma key background
- Crops transparent padding (generated images often have 40–70% empty space)
- Saves into the Xcode asset catalogue at `AdorableBites/Assets.xcassets/<name>.imageset/`

### 3. Run xcodegen

After adding new assets, regenerate the Xcode project so it picks them up. The build-and-preview skill handles this automatically, but if building manually:

```bash
xcodegen
```

## Editing existing assets

To modify an existing image (e.g. rotate it, change a detail, adjust colours):

```bash
uv run scripts/edit_art.py <path-to-image> "<what to change>"
```

**When to use edit vs generate:** If an asset already exists and needs modification (remove an element, change a colour, adjust a detail), always use the edit script rather than regenerating from scratch. Regenerating produces a completely different image, while editing preserves the existing style and makes targeted changes.

Example:
```bash
uv run scripts/edit_art.py AdorableBites/Assets.xcassets/frying_pan.imageset/frying_pan@2x.png "rotate the pan 90 degrees clockwise so the handle points down"
```

The script sends the existing image plus your prompt to Gemini, removes the green background, crops padding, and overwrites the original file.

## Batch operations

When generating multiple assets, run them in parallel for speed:

```bash
uv run scripts/generate_art.py asset_one 2>&1 &
uv run scripts/generate_art.py asset_two 2>&1 &
uv run scripts/generate_art.py asset_three 2>&1 &
wait
```

## PIL-based image manipulation

For transformations that don't need Gemini (rotation, flipping, resizing), use PIL directly rather than calling the edit script:

```python
from PIL import Image
img = Image.open('<path>')
img = img.rotate(-90, expand=True)  # 90° clockwise
img.save('<path>')
```
