---
name: build-and-preview
description: Build the AdorableBites app and analyse a simulator screenshot. Use this skill whenever the user asks to build, preview, test, run, or see the app — or after making code changes that should be visually verified. Also trigger proactively after writing or modifying Swift/SpriteKit code to show the user what it looks like. Covers phrases like "build and run", "show me the app", "take a screenshot", "what does it look like now", "preview", "build it", or simply "run it".
---

# Build and Preview

Build the AdorableBites iPad app, install it on the simulator, take a screenshot, and evaluate the result.

## Build pipeline

Run the build script:

```bash
bash .claude/skills/build-and-preview/scripts/build_and_preview.sh
```

The last line of output is `SCREENSHOT_PATH=<path>`. Extract this path and read the image with the Read tool.

Screenshots are saved to `.screenshots/` in the repo root (gitignored) so the user can also open them directly if they want.

### Build failure (exit code 2)

The script prints the last 30 lines of the build log. Read the errors, fix the Swift code yourself, and re-run the script. Do not ask the user to fix build errors that you introduced.

### Other exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | `xcodegen generate` failed |
| 3 | Simulator install or launch failed |
| 4 | Screenshot failed |

## Taking additional screenshots

The build script captures one screenshot 2 seconds after launch. If you need to verify state after interactions (e.g. after tapping ingredients, during cooking animations), take additional screenshots manually:

```bash
xcrun simctl io "iPad mini (A17 Pro)" screenshot .screenshots/extra.png
```

Then rotate if needed:
```bash
python3 -c "from PIL import Image; img = Image.open('.screenshots/extra.png'); w,h = img.size; img = img.rotate(-90, expand=True) if h > w else img; img.save('.screenshots/extra_landscape.png')"
```

## Evaluating the screenshot

After reading the screenshot image, perform two evaluations in order:

### 1. Primary: Did the work land?

Before this build-and-preview was triggered, you were working on something — a new feature, a layout change, a bug fix, an asset swap. The first and most important question is: **did those changes actually show up correctly in the app?**

Check specifically for what you just implemented:
- If you added a new node/element, is it visible and in the right position?
- If you changed a layout, does it match what was intended?
- If you swapped an image asset, is the new image rendering?
- If you fixed a bug, is the fix working?

State clearly whether the work landed or not. If something you implemented is missing or wrong, flag it immediately — this is the primary purpose of the screenshot.

### 2. Secondary: General quality review

After confirming the work landed, do a quick scan of the full screen for anything that looks unprofessional or would reduce the experience. This is a compulsory but secondary check. Look for:

- Elements overlapping, clipped by screen edges, or hidden behind the status bar
- Misaligned or unevenly spaced elements
- Missing or broken assets (blank/white squares, placeholder text)
- Elements rendering behind things they should be in front of
- Scaling problems — things too large, too small, or squashed
- Text hard to read against its background
- Large empty areas suggesting poor use of screen space
- Inconsistency between elements that should look similar

Present findings concisely. If the work landed and everything else looks fine, say so briefly and move on. Don't exhaustively describe every element — focus on issues.
