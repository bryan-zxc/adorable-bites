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

### Snowflake & Freeze Theme
- Snowflakes are Elsa's magical power — they **unfreeze** things, never "unlock" or "lock"
- All locked content is visually represented as **frozen in ice** (ice block overlay), never a padlock/lock icon
- Tapping frozen content with enough snowflakes triggers an **unfreeze animation** (ice shatters/melts)
- Snowflakes are spent to:
  - **Unfreeze levels** — major milestone levels cost snowflakes (not every level)
  - **Unfreeze ingredients** — every new ingredient costs snowflakes to unfreeze
  - **Unfreeze tool shop tiers** — each tier costs snowflakes
- Use "unfreeze" in all UI text, never "unlock"
- Use ice block imagery, never padlock imagery

## Tech Stack
- **Language:** Swift
- **Framework:** SpriteKit (2D game framework)
- **Platform:** iPadOS
- **Target device:** iPad mini
- **IDE:** Xcode

## Build & Preview
- **Always use the `/build-and-preview` skill** after making changes to the app — to build, run, and visually verify the result

## Workflow
- **Always plan before acting** — for non-trivial changes, enter plan mode and get user approval before writing code

## Art Generation
- **Always use the `/generate-art` skill** to generate or edit game art — never generate images any other way
