---
name: create-level
description: Design and balance new game levels for Adorable Bites. Use this skill whenever the user wants to create, design, add, or balance a game level — even if they just say "what should level 31 look like" or "add a new level". Also trigger when the user asks about level timing, customer counts, Poisson rates, economy projections, or whether the player can afford things at a certain point. Covers anything related to level design, difficulty tuning, or resource economy planning.
---

# Create Level

Design new Adorable Bites levels with proper timing, customer counts, arrival rates, and economy balance. Every number is derived from the timing model — no guessing.

Levels are designed **10 at a time** in a single `docs/levels-X-Y.md` file. Each file is self-contained: it has the narrative design, per-level config, AND the resource economy for that batch (how much money/snowflakes are earned and spent across those 10 levels). The economy section in each batch is responsible for **depleting the player's accumulated resources** by the end of those 10 levels.

## Quick Reference

Run the calculator from the repo root:

```bash
# Analyse a specific level (uses existing config for L1-30, computes optimal for L31+)
python3 .claude/skills/create-level/scripts/level_calculator.py 31 --chairs 5 --plates 3

# Override customer count to test a specific number
python3 .claude/skills/create-level/scripts/level_calculator.py 15 --customers 10

# Analyse with specific recipes
python3 .claude/skills/create-level/scripts/level_calculator.py 31 --chairs 5 --recipes "Fried Egg,Pancakes,Omelette"

# Show timing for all 30 current levels
python3 .claude/skills/create-level/scripts/level_calculator.py --all

# Full economy projection (money + snowflakes for all profiles)
python3 .claude/skills/create-level/scripts/level_calculator.py --economy
```

## Workflow

### 1. Gather context

Read the previous batch's level doc to understand what the player has at this point:
- What tools, ingredients, and recipes do they have?
- How much money and snowflakes have they accumulated?
- What's the cumulative spend so far?

Also read:
- `docs/resource-economy.md` — master economy formulas, recipe payouts, player profiles
- `AdorableBites/Models/LevelConfig.swift` — level config structure

### 2. Discuss with the user

Design 10 levels as a batch. For each level, align on:
- **What's new?** New recipe, new tool, new mechanic, or practice/pressure level?
- **What's the feel?** Relaxed practice, moderate challenge, or intense pressure test?
- **Is this level frozen?** Tool levels need both snowflakes (to unfreeze) and money (to buy the tool). Milestone levels just need snowflakes.
- **New ingredients?** Each ingredient costs snowflakes to unfreeze individually.

### 3. Run the calculator for each level

```bash
python3 .claude/skills/create-level/scripts/level_calculator.py <level> --chairs <N> --plates <N> --recipes "Recipe1,Recipe2,..."
```

The calculator outputs:
- **Timing**: active/passive/sequential times, marginal time with parallelism, Poisson arrival interval, estimated duration for a strong player
- **Economy**: money and snowflakes earned per profile (average, slow, strong)

### 4. Check economy balance across the batch

The 10-level batch should **deplete most of the resources earned within it**. Run the economy check:

1. Start with the cumulative totals from the previous batch
2. For each level in this batch, add earnings and subtract any spending
3. By the end of the batch, the average player should have spent most of what they earned — leaving a small surplus (0-20% buffer)
4. There should be 0-1 replay points within each batch of 10

For tool levels (double-gated): the player needs BOTH enough snowflakes to unfreeze AND enough money to buy the tool. Check both currencies.

### 5. Write the level doc

Create `docs/levels-X-Y.md` with this structure:

#### Narrative section (per level)

```markdown
## Level N — Title
- Description of what's new, what the player learns
- New recipe: **Recipe Name** (ingredients → steps → device)
- Why this level exists in the progression
```

#### Level Config Table

Every level doc must include a complete config table with ALL parameters needed to implement the level:

| Level | Chairs | Plates | Customers | Arrival | Recipes | Frozen | Duration | New |
|-------|--------|--------|-----------|---------|---------|--------|----------|----|
| 11 | 2 | 3 | 10 | 35s | FE, PT, BE, FrPo | 8❄ | 5.9 min | Fried Potato, Knife |
| 12 | 2 | 3 | 9 | 35s | + FrOE | — | 5.7 min | Fried Onion Egg |
| ... | | | | | | | | |

Columns:
- **Chairs**: number of seats
- **Plates**: plate count (limited resource)
- **Customers**: total customers to serve
- **Arrival**: Poisson mean interval in seconds, or "seq" for sequential (1-chair training levels)
- **Recipes**: available recipe pool (cumulative)
- **Frozen**: snowflake cost to unfreeze, or "—"
- **Duration**: estimated time for strong player (from calculator)
- **New**: what's introduced at this level (recipe, tool, mechanic)

#### Feature flags (if applicable)

For training levels (L1-10), list which automation is on/off:

| Level | autoCollectMoney | autoClearTable | canOvercook | hasCustomerTimer |
|-------|------------------|----------------|-------------|-----------------|
| 1 | true | true | false | false |
| 2 | true | true | false | true |
| ... | | | | |

#### Economy section

Each 10-level batch includes its own economy section showing:

1. **Earnings per level** (money + snowflakes for average player)
2. **Spending milestones** within this batch (tools, chairs, frozen levels, ingredients)
3. **Cashflow trace** — running balance showing where the squeeze points are
4. **Batch totals** — money earned vs spent, snowflakes earned vs spent
5. **Carry-forward** — what the player takes into the next batch

### 6. Update LevelConfig.swift

Add each level to `AdorableBites/Models/LevelConfig.swift`:

```swift
LevelConfig(
    level: N, name: "", recipeNames: ["Recipe1", "Recipe2"],
    chairCount: C, customerCount: N, plateCount: P, unlockCost: 0,
    autoCollectMoney: false, autoClearTable: false,
    canOvercook: true, hasCustomerTimer: true
),
```

Feature flags for L11+: all manual (`autoCollectMoney: false, autoClearTable: false, canOvercook: true, hasCustomerTimer: true`).

### 7. Update the calculator

If the batch introduces new recipes, add them to `RECIPES` in `scripts/level_calculator.py`:

```python
Recipe("Recipe Name", ingredients=N, steps=N, has_mixing=bool, cook_device="pan", introduced_at=level),
```

Also add the new levels to `CURRENT_LEVELS` and any new spending to `MONEY_SPENDING` / `SNOWFLAKE_SPENDING`.

### 8. Verify

Run the full economy projection to verify everything balances:

```bash
python3 .claude/skills/create-level/scripts/level_calculator.py --economy
```

## Timing Model

The calculator encodes the full timing model. Summary for quick reference:

**Active time per customer** = quiz+pickup (13s/ingredient) + steps (3s/step) + mixer overhead (5s if mixing) + device handling (4s) + post-serve taps (varies by level automation)

**Passive time** = mixer animation (2s if mixing) + cook time (pan 8s, pot 12s, wok 5s, toaster 3s) + eating (6s)

**Parallelism**: with multiple chairs, passive time overlaps with the next customer's active time. Overhead factors: 2 chairs = 1.15, 3 = 1.10, 4 = 1.08, 5 = 1.05.

**Strong player duration**: sequential_time + (customers - 1) x marginal_time. Target 5-7.5 min for post-training levels.

## Economy Rules

- **Money formula**: base_pay = ingredients + steps. Tip = +$1.
- **Snowflakes**: 1 quiz per ingredient pickup. Reward scales with difficulty (+1/+2/+3). Wrong answers cost -1. Missed customers cost -1.
- **Tool levels are double-gated**: need snowflakes to unfreeze the level AND money to buy the tool.
- **Average player target**: ~2 replays across the full game (0-1 per batch of 10). If a batch creates 2+ replay points, prices need adjusting.
- **Player profiles**: strong (0 miss, 90% acc), average (0.5 miss, 80% acc), slow (2 miss, 70% acc).
- **Resource depletion**: each 10-level batch should spend most of what it earns. The player shouldn't accumulate a large surplus across batches.
