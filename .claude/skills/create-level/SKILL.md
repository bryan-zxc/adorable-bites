---
name: create-level
description: Design and balance new game levels for Adorable Bites. Use this skill whenever the user wants to create, design, add, or balance a game level — even if they just say "what should level 31 look like" or "add a new level". Also trigger when the user asks about level timing, customer counts, Poisson rates, economy projections, or whether the player can afford things at a certain point. Covers anything related to level design, difficulty tuning, or resource economy planning.
---

# Create Level

Design new Adorable Bites levels with proper timing, customer counts, arrival rates, and economy balance. Every number is derived from the timing model — no guessing.

Levels are designed **10 at a time** in a single `docs/levels-X-Y.md` file. Each file is self-contained: narrative design, per-level config, AND the resource economy for that batch.

## Core Economy Principles

### 1. Each 10-level band is self-contained

Each batch starts near zero and **depletes to near zero (or negative)** by the end. Bands operate relatively independently — no large surplus carries across batches.

### 2. Tool pricing forces a saving period

When a tool is introduced (made available for purchase), **the player's expected balance must be negative at that point**. They cannot afford it immediately — they must earn over the next few levels before buying.

Once the player buys the tool, customers start ordering recipes that need it. The flow is:
1. Tool becomes available → player can't afford it (negative balance)
2. Player earns money over the next few levels
3. Player buys the tool
4. Subsequent levels introduce recipes that use the tool
5. This creates the "I need this tool" → "I'm saving up" → "I bought it!" → "Now I can cook this!" satisfaction loop

**Never** introduce a tool and immediately require it in the very next level. There must always be a gap for earning.

Tools can open at any point in a band (beginning, middle, or end). The recommendation is towards the end of a band to set up the next batch, but this is flexible. The hard rule is the negative balance on introduction.

**Exception**: The very first chair purchase (L1-10 training) can be immediately affordable — this is the player's first shop experience and should feel rewarding, not frustrating.

### 2b. Multi-purchase items (chairs, pans, pots, induction tops, etc.)

Items that can be bought multiple times follow a **backwards design** process:

1. **Start with the goal**: "At level X, I want the player to NEED 2 pans to keep up"
2. **Verify with the calculator**: Run achievability — confirm level X is impossible with 1 pan, achievable with 2
3. **Place the purchase**: A few levels before X, count the 2nd pan purchase (balance goes negative)
4. **Place the hint**: A level before the purchase point, the level-end screen hints: "To handle the next levels, you might want another pan!"
5. **Price it**: Set the price so balance is negative at the purchase point

You always design backwards from the difficulty target, not forwards from the tool availability.

### 3. Negative balance at tool introduction is expected

The plan should show a negative balance when a tool becomes available. This is a planning artefact only — in the game, the player simply can't purchase until they have enough. The negative value shows how many levels of earning are needed before the tool is affordable.

### 4. Customers never exceed plates (before dishwashing)

Until dishwashing is introduced, customers per level must never exceed plate count. After dishwashing, plates become a reusable resource.

### 5. Snowflake earning model

- Quiz snowflakes earned during gameplay (correct = +difficulty reward, wrong = -1)
- Level-end bonus: 3sf (0 missed), 2sf (1 missed), 1sf (2+ missed)
- Every level costs 1sf to unfreeze (special frozen levels cost more)
- New ingredients cost snowflakes to unfreeze (shown in combined unfreeze popup with the level)
- If net snowflakes for the level are negative, nothing counts — must retry

## Quick Reference

Run the calculator from the repo root:

```bash
python3 .claude/skills/create-level/scripts/level_calculator.py --economy       # Full economy projection
python3 .claude/skills/create-level/scripts/level_calculator.py --all           # Timing for all levels
python3 .claude/skills/create-level/scripts/level_calculator.py 31 --chairs 5   # Analyse specific level
```

## Workflow

### 1. Read the previous band

Read the previous batch's `docs/levels-X-Y.md` to find:
- **Ending balance** (money and snowflakes — expected to be negative or near zero)
- **Tools made available** that the player couldn't yet afford (need purchasing in THIS band)
- **Ingredients unfrozen** so far
- **Recipes available** so far

The starting balance for the new band = the previous band's ending balance (in-game this clamps to 0 since you can't spend what you don't have, but the plan tracks the deficit).

### 2. Design the 10 levels

For each level, align on:
- **What's new?** New recipe, new tool, new mechanic, or practice/pressure level?
- **What's the feel?** Relaxed practice, moderate challenge, or intense pressure test?
- **Is this level frozen?** All levels cost 1sf+. Tool levels also need money for the tool.
- **New ingredients?** Each costs snowflakes to unfreeze.

Ensure:
- Tools that were opened in the previous band get purchased early in this band (after 2-3 levels of earning)
- Any new tools opened in this band create a negative balance at introduction
- Recipes requiring a tool only appear AFTER the player can afford and buy the tool
- Each band roughly depletes resources by the end

### 3. Run the calculator

```bash
python3 .claude/skills/create-level/scripts/level_calculator.py --economy
```

Check:
- **Negative balance when tools are introduced** (confirms player can't buy immediately)
- **Balance recovers** over the next few levels (player earns enough to buy)
- **Band ends near zero or negative** (resources depleted, possibly new tool opened)
- **No NEED flags for level unfreezes** (player can always afford to play the next level)

### 4. Write the level doc

Create `docs/levels-X-Y.md` with these sections:

#### Level Narratives
Per-level descriptions with goals, new mechanics, recipes.

#### Level Config Table
| Level | Chairs | Plates | Customers | Arrival | Recipes | Frozen | Duration | New |
|-------|--------|--------|-----------|---------|---------|--------|----------|----|

#### Feature Flags (if training levels)

#### Tutorial Messages (if applicable)

#### Economy Section
Must include:
1. **Starting balance** (from previous band's ending balance)
2. **Earnings per level** (money + snowflakes for average player)
3. **Spending milestones** (tools, ingredients, unfreezes) — note which create negative balance
4. **Cashflow trace** with running balance — negative values are expected at tool introductions
5. **Ending balance** (expected near zero or negative)
6. **Tools/ingredients opened** at the end of this band (setup for next band)

### 5. Update LevelConfig.swift

Add levels to `AdorableBites/Models/LevelConfig.swift`. Include `newIngredients` for any level that introduces ingredients.

### 6. Update the calculator

Add new recipes to `RECIPES`, new levels to `CURRENT_LEVELS`, new spending to `MONEY_SPENDING` / `SNOWFLAKE_PURCHASES`.

### 7. Verify

Run `--economy` to verify:
- Tool introductions create negative balance
- Balance recovers within a few levels
- Band ends near zero or negative
- Snowflakes deplete similarly
- No level unfreeze is unaffordable (player can always play the next level)

## Timing Model

**Active time per customer** = quiz+pickup (13s/ingredient) + steps (3s/step) + mixer overhead (5s if mixing) + device handling (4s) + post-serve taps (varies by level automation)

**Passive time** = mixer animation (2s if mixing) + cook time (sum of ingredient cook times, halved for L1-10 training) + eating (6s)

**Parallelism overhead**: 2 chairs = 1.15, 3 = 1.10, 4 = 1.08, 5 = 1.05

**Duration target**: 5-7.5 min for post-training levels.

## Economy Formulas

- **Money**: base_pay = ingredients + steps. Tip = +$1.
- **Snowflakes**: quiz reward scales with difficulty (+1/+2/+3). Wrong = -1. Level-end bonus = 3/2/1 based on missed customers. Every level costs 1sf+ to unfreeze.
- **Cooking time**: sum of each ingredient's cook time. L1-10 at half speed. Wok at 60%.
- **Player profiles**: strong (0 miss, 90% acc, +3), average (0.5 miss, 80% acc, +2), slow (2 miss, 70% acc, +1).
