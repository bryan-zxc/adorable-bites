# Adorable Bites

## Project Goal
Build a fun, engaging iPad cooking game for a 6-year-old. The game should:
- Be entertaining and keep them wanting to play
- Sprinkle in educational content naturally (not feel like a lesson)
- Be age-appropriate and intuitive for a young child

## Game Concept
A cooking/restaurant game where:
- Customers come in and place food orders
- The player must process ingredients (chop, mix, cook, etc.)
- Assemble the ingredients to compile the complete meal
- Fulfil orders correctly to earn points/rewards

### Educational Elements
- Crafted quizzes appear at various points in gameplay (e.g. when collecting ingredients, upgrading kitchen features — exact placement TBD)
- Quizzes are woven into the game flow so they feel like part of the experience, not a separate lesson

## Tech Stack
- **Language:** Swift
- **Framework:** SpriteKit (2D game framework)
- **Platform:** iPadOS
- **Target device:** iPad mini
- **IDE:** Xcode

## Art Generation
- **Always use the Python scripts in `scripts/` to generate or edit game art** — never generate images any other way
- `uv run scripts/generate_art.py` — generate all assets, or pass a name to generate one (e.g. `uv run scripts/generate_art.py frying_pan`)
- `uv run scripts/edit_art.py <image_path> "<prompt>"` — edit an existing image in place
- These scripts use Google Gemini via the API key in `scripts/.env.local`
- New assets must be added to the `ASSETS` list in `generate_art.py` before generating
