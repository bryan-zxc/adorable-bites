# Levels 11-20: Building the Kitchen

Player has graduated from training. All core mechanics are known. These levels introduce new ingredients, tools, and recipes -- but the foundational game loop never changes.

**Tool Shop Tier 1** (available from level 10): Knife ($15), Pot ($28)
**Tool Shop Tier 2** (unfreezes around level 16, costs 16 snowflakes): Mixer ($25), Peeler ($22), 2nd Induction Spot ($45), Dishwasher ($42)

---

## Level Narratives

### Level 11 -- First Cuts
- **Produce unfrozen** (4 snowflakes each): potato, onion, tomato
- Buy **Knife** from Tier 1 shop
- New recipe: **Fried Potato** (chop potato -> pan)
- First use of prep station -- chop then cook

### Level 12 -- Onion Rings
- New recipe: **Fried Onion Egg** (chop onion + egg -> pan)
- Same tools, new ingredient combo
- Practice chopping under customer pressure

### Level 13 -- Boiling Point
- Buy **Pot** from Tier 1 shop
- New recipe: **Boiled Potato** (chop potato -> pot)
- First boiling recipe! Pot sits on bench, doesn't use induction
- Encourages healthy eating -- boiled veges

### Level 14 -- Veggie Plate
- New recipe: **Boiled Veges** (chop tomato + potato -> pot)
- Multi-ingredient pot recipe
- Practice with pot + pan simultaneously

### Level 15 -- Third Chair
- **3rd chair** available to buy
- More customers (9 total), faster arrival
- No new recipe -- practice managing 3 chairs with existing recipes

### Level 16 -- Tool Shop Upgrade
- **Tool Shop Tier 2 unfreezes** (16 snowflakes)
- **Bakery basics unfrozen** (5 snowflakes each): flour, milk, sugar
- Level itself is a practice round -- same recipes, building up snowflakes/money for purchases

### Level 17 -- The Mixer
- Buy **Mixer** from Tier 2 shop
- New recipe: **Scrambled Egg** (egg -> mixer -> pan)
- First mixer recipe -- simple, just one ingredient through mixer

### Level 18 -- Pancake Day
- New recipe: **Pancakes** (flour + egg + milk -> mixer -> pan)
- Multi-ingredient mixer recipe
- Higher cooking time, worth more money

### Level 19 -- Plate Crunch Returns
- Fewer plates available this level (3 -> 2 temporarily)
- Builds urgency to buy **Dishwasher** from Tier 2 shop
- Dishwasher auto-washes plates -- one less thing to manage

### Level 20 -- Parallel Cooking
- Buy **Peeler** from Tier 2 -- new recipe: **Hash Brown** (peel -> chop -> pan)
- Buy **2nd Induction Spot** from Tier 2 -- cook two things simultaneously
- Big upgrade level -- kitchen starts feeling like a real operation

---

## Level Config Table

| Level | Chairs | Plates | Customers | Arrival | Recipes Available | Frozen Cost | Est Duration | New Mechanic / Recipe |
|-------|--------|--------|-----------|---------|-------------------|-------------|--------------|----------------------|
| **11** | 2 | 3 | 10 | 35s | + Fried Potato | 8 | ~5.9 min | Knife, prep station (chop) |
| 12 | 2 | 3 | 9 | 35s | + Fried Onion Egg | -- | ~5.7 min | Multi-ingredient chop |
| **13** | 2 | 3 | 9 | 35s | + Boiled Potato | 8 | ~5.7 min | Pot (boiling) |
| 14 | 2 | 3 | 9 | 40s | + Boiled Veges | -- | ~6.0 min | Multi-ingredient pot |
| **15** | 3 | 3 | 9 | 35s | (practice) | 28 | ~5.8 min | 3rd chair |
| 16 | 3 | 3 | 9 | 35s | (practice / shop) | -- | ~5.8 min | Tier 2 shop, bakery ingredients |
| **17** | 3 | 3 | 9 | 35s | + Scrambled Egg | 10 | ~5.8 min | Mixer |
| 18 | 3 | 3 | 8 | 40s | + Pancakes | -- | ~5.6 min | Multi-ingredient mixer |
| 19 | 3 | 2 | 9 | 35s | (plate crunch) | -- | ~5.8 min | Dishwasher |
| **20** | 3 | 3 | 9 | 35s | + Hash Brown | 35 | ~5.7 min | Peeler, 2nd induction |

- **Arrival:** Poisson mean interval in seconds.
- **Frozen Cost:** snowflake cost to unfreeze, or "--" if free.
- **Est Duration:** strong player estimate (no missed customers).
- **Bold levels** are frozen (require snowflakes to unfreeze).

---

## Tools Introduced This Batch

| Tool | Tier | Price | Introduced |
|------|------|-------|------------|
| Knife | 1 | $15 | Level 11 |
| Pot | 1 | $28 | Level 13 |
| Mixer | 2 | $25 | Level 17 |
| Dishwasher | 2 | $42 | Level 19 |
| Peeler | 2 | $22 | Level 20 |
| 2nd Induction | 2 | $45 | Level 20 |

## Recipes Introduced This Batch

| Recipe | Ingredients | Steps | Method | Base $ | + Tip | Level |
|--------|-------------|-------|--------|--------|-------|-------|
| Fried Potato | potato | chop | chop -> pan | 2 | 3 | 11 |
| Fried Onion Egg | onion + egg | chop | chop onion -> pan with egg | 3 | 4 | 12 |
| Boiled Potato | potato | chop | chop -> pot | 2 | 3 | 13 |
| Boiled Veges | tomato + potato | chop x2 | chop -> pot | 4 | 5 | 14 |
| Scrambled Egg | egg | mix | mixer -> pan | 2 | 3 | 17 |
| Pancakes | flour + egg + milk | mix | mixer -> pan | 4 | 5 | 18 |
| Hash Brown | potato | peel, chop | peel -> chop -> pan | 3 | 4 | 20 |

---

## Economy -- L11-20

### Starting Resources (Carry-Forward from L1-10)

| Resource | Balance |
|----------|---------|
| Money | $25 |
| Snowflakes | 19 |

These are the surplus balances an average player carries into this batch after all L1-10 spending (2nd chair $30, extra plate $15, Tier 1 unlock 12sf, unfreeze L5 5sf, unfreeze L10 15sf).

### Earnings per Level (Average Player)

Average player profile: misses 0-1 customers per level (modelled as 0.5 missed), +2 quiz difficulty from L4, 80% accuracy, 35% tip rate.

| Level | Customers | Served | Avg $/Serve | Money Earned | Snowflakes Earned |
|-------|-----------|--------|-------------|--------------|-------------------|
| 11 | 10 | 9.5 | $1.85 | $18 | 12 |
| 12 | 9 | 8.5 | $2.15 | $18 | 13 |
| 13 | 9 | 8.5 | $2.18 | $19 | 12 |
| 14 | 9 | 8.5 | $2.49 | $21 | 13 |
| 15 | 9 | 8.5 | $2.49 | $21 | 13 |
| 16 | 9 | 8.5 | $2.49 | $21 | 13 |
| 17 | 9 | 8.5 | $2.48 | $21 | 12 |
| 18 | 8 | 7.5 | $2.68 | $20 | 12 |
| 19 | 9 | 8.5 | $2.68 | $23 | 14 |
| 20 | 9 | 8.5 | $2.75 | $23 | 14 |
| **Totals** | | | | **$205** | **~129** |

### Spending Milestones

#### Money Spending ($190 total)

| Item | Price | When |
|------|-------|------|
| Knife | $15 | L11 |
| Pot | $28 | L13 |
| 3rd Chair | $58 | L15 |
| Mixer | $25 | L17 |
| Dishwasher | $42 | L19 |
| Peeler | $22 | L20 |

#### Snowflake Spending (132 total)

| Category | Item | Cost | When |
|----------|------|------|------|
| Frozen level | Unfreeze L11 | 8 | Before L11 |
| Produce | Potato + Onion + Tomato | 12 (4+4+4) | L11 |
| Frozen level | Unfreeze L13 | 8 | Before L13 |
| Frozen level | Unfreeze L15 | 28 | Before L15 |
| Tier unlock | Tool Shop Tier 2 | 16 | L16 |
| Bakery | Flour + Milk + Sugar | 15 (5+5+5) | L16 |
| Frozen level | Unfreeze L17 | 10 | Before L17 |
| Frozen level | Unfreeze L20 | 35 | Before L20 |
| | **Total** | **132** | |

### Cashflow Trace (Average Player)

Traces money and snowflake balance through the batch. "Before" entries show spending that gates the level; "After" entries show the balance once that level's earnings are collected.

| Point | Money | Snowflakes | Event |
|-------|-------|------------|-------|
| **Start of batch** | **$25** | **19** | Carry-forward from L1-10 |
| Before L11 | $10 | -1 | Buy knife ($15), unfreeze L11 (8sf), buy produce (12sf) |
| After L11 | $28 | 11 | Earn $18, 12sf |
| After L12 | $46 | 24 | Earn $18, 13sf |
| Before L13 | $18 | 16 | Buy pot ($28), unfreeze L13 (8sf) |
| After L13 | $37 | 28 | Earn $19, 12sf |
| After L14 | $58 | 41 | Earn $21, 13sf |
| Before L15 | $0 | 13 | Buy 3rd chair ($58), unfreeze L15 (28sf) |
| After L15 | $21 | 26 | Earn $21, 13sf |
| L16 shop | $21 | -5 | Buy Tier 2 (16sf) + bakery (15sf) |
| After L16 | $42 | 8 | Earn $21, 13sf |
| Before L17 | $42 | -2 | Unfreeze L17 (10sf) -- **replay needed** |
| After replay + L17 | ~$63 | ~22 | Replay a level (~$21, ~13sf), then earn L17 ($21, 12sf) |
| After L18 | ~$83 | ~34 | Earn $20, 12sf |
| Before L19 | ~$41 | ~34 | Buy dishwasher ($42) |
| After L19 | ~$64 | ~48 | Earn $23, 14sf |
| Before L20 | ~$42 | ~13 | Unfreeze L20 (35sf), buy peeler ($22) |
| After L20 | ~$65 | ~27 | Earn $23, 14sf |
| **End of batch** | **~$65** | **~27** | Carry-forward to L21-30 |

Key pressure points:
- **Before L11 (sf -1):** The triple spend of unfreeze + produce + knife is the tightest moment. A good quiz run during L10 can cover the 1sf shortfall; otherwise the player needs a brief replay.
- **Before L17 (sf -2):** After the Tier 2 + bakery spending spree at L16, the player is 2sf short of unfreezing L17. One replay of a mid-batch level (e.g. L14 or L15, which each yield ~13sf) resolves this comfortably.
- **Before L15 (money $0):** The 3rd chair wipes out the money balance completely, but L15 earnings immediately restore it to $21.

### Batch Totals

| | Money | Snowflakes |
|---|-------|------------|
| Carry-in (from L1-10) | $25 | 19 |
| Earned this batch | $205 | ~129 |
| Spent this batch | $190 | 132 |
| **Carry-forward to L21-30** | **~$40** | **~16** |

Note: The carry-forward figures account for one replay level (earning ~$21, ~13sf) needed to cover the L17 snowflake shortfall. Without the replay, raw carry-forward would be $40 money and 16sf. With the replay, it is approximately $65 money and ~27sf. The exact figures depend on which level is replayed and player performance.

Replay budget for this batch: **1 snowflake replay** (before L17). No money replay needed -- money stays positive throughout, though it hits $0 at L15 before immediately recovering.
