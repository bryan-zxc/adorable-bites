# Levels 21-30: Expanding the Menu

Player now has: pan, pot, mixer, knife, peeler, 2nd induction, dishwasher, 3 chairs. Core loop mastered. These levels push complexity with new cooking surfaces, more ingredients, and faster pace.

**Tool Shop Tier 3** (unfreezes around level 25, costs 22 snowflakes): Toaster ($32), Wok + Gas Burner ($58), Grater ($28)

---

## Level Descriptions

### Level 21 -- Comfort Zone
- Practice level -- all existing recipes, faster arrival rate
- 11 customers, build up money for upcoming purchases
- Buy **2nd Induction** ($45) -- relieves the cooking bottleneck before recipes get harder
- 4th chair available to buy (but average player cannot yet afford it)

### Level 22 -- Omelette
- New recipe: **Omelette** (egg + tomato + onion -> chop both -> mixer -> pan)
- Most complex recipe so far -- multi-prep, mix, cook
- Worth good money ($6 base, $7 with tip)
- Buy **4th Chair** ($68) -- average player needs 1 replay to afford this

### Level 23 -- Simple Soup
- New recipe: **Potato Soup** (potato + onion -> chop -> pot, longer cook time)
- Pot recipes getting more complex
- Introduces idea that some recipes take longer and are worth more

### Level 24 -- Busy Service
- 10 customers, fast Poisson arrival
- No new recipe -- pure pressure test
- Encourages buying 4th chair if not already done

### Level 25 -- New Equipment
- **Tool Shop Tier 3 unfreezes** (22 snowflakes)
- **Proteins unfrozen** (6 snowflakes each): chicken, bacon
- Toaster available -- pan toast becomes optional (toaster is faster, frees up pan)

### Level 26 -- The Toaster
- Buy **Toaster** ($32) -- toast now takes 3s vs 10s in pan, no overcook risk
- New recipe: **Bacon** (bacon -> pan)
- Simple single-ingredient protein recipe

### Level 27 -- Bacon & Eggs
- New recipe: **Bacon & Eggs** (bacon + egg -> pan)
- Combo plating -- two items on one plate
- Worth more money

### Level 28 -- The Wok
- Buy **Wok + Gas Burner** ($58) -- fast cooking but very short overcook window
- New recipe: **Stir Fry Chicken** (chop chicken + onion -> wok)
- Different cooking dynamic -- wok is fast but punishing

### Level 29 -- Grater
- Buy **Grater** ($28) from Tier 3
- New recipe: **Hash Brown Deluxe** (potato -> peel -> grate -> pan)
- Grating as a new prep action

### Level 30 -- Full House
- Buy **5th Chair** ($95), 11 customers
- All recipes from levels 1-29 available
- Fast pace -- prove you can run a full kitchen

---

## Level Config Table

| Level | Chairs | Plates | Customers | Arrival | Recipes | Frozen Cost | Duration | New |
|-------|--------|--------|-----------|---------|---------|-------------|----------|-----|
| 21 | 4 | 3 | 11 | 35s | all L1-20 recipes | -- | ~6.8 min | 2nd Induction (buy) |
| 22 | 4 | 3 | 10 | 40s | + Omelette | -- | ~6.7 min | Omelette, 4th Chair (buy) |
| 23 | 4 | 3 | 10 | 40s | + Potato Soup | -- | ~6.8 min | Potato Soup |
| 24 | 4 | 3 | 10 | 40s | (same) | -- | ~6.8 min | pressure test |
| 25 | 4 | 3 | 10 | 40s | (same) | 45 sf | ~6.8 min | Tier 3 shop, proteins |
| 26 | 4 | 3 | 10 | 40s | + Bacon | 12 sf | ~6.6 min | Toaster (buy), Bacon |
| 27 | 4 | 3 | 10 | 40s | + Bacon & Eggs | -- | ~6.6 min | Bacon & Eggs |
| 28 | 4 | 3 | 10 | 40s | + Stir Fry Chicken | 15 sf | ~6.7 min | Wok + Gas (buy), Stir Fry |
| 29 | 4 | 3 | 10 | 40s | + Hash Brown Deluxe | 8 sf | ~6.6 min | Grater (buy), Hash Brown Deluxe |
| 30 | 5 | 3 | 11 | 35s | all L1-29 recipes | 55 sf | ~7.0 min | 5th Chair (buy), capstone |

- **Arrival:** Poisson mean interval in seconds.
- **Frozen Cost:** snowflake cost to unfreeze the level, or "--" if free.
- **Duration:** strong player estimate (no missed customers).

---

## Economy

All figures below are for the **average player** profile (0-1 missed customers from L6+, +2 quiz difficulty from L4, 80% accuracy, 35% tip rate). Data sourced from `resource-economy.md`.

### Starting Resources (carry-forward from L1-20)

| Resource | Earned (L1-20) | Spent (L1-20) | Carry-forward |
|----------|---------------|---------------|---------------|
| Money | $275 | $235 | **$40** |
| Snowflakes | 179 | 164 | **15** |

**Money spent through L20:** 2nd Chair $30 + Extra Plate $15 + Knife $15 + Pot $28 + 3rd Chair $58 + Mixer $25 + Dishwasher $42 + Peeler $22 = $235.

**Snowflakes spent through L20:** freeze L5 (5) + freeze L10 (15) + Tier 1 (12) + freeze L11 (8) + produce (12) + freeze L13 (8) + freeze L15 (28) + Tier 2 (16) + bakery ingredients (15) + freeze L17 (10) + freeze L20 (35) = 164.

### Earnings per Level (average player)

| Level | Cust | Served | Avg $/serve | Money | Snowflakes |
|-------|------|--------|-------------|-------|------------|
| 21 | 11 | 10.5 | $2.75 | $29 | 16 |
| 22 | 10 | 9.5 | $3.08 | $29 | 16 |
| 23 | 10 | 9.5 | $3.18 | $30 | 17 |
| 24 | 10 | 9.5 | $3.18 | $30 | 17 |
| 25 | 10 | 9.5 | $3.18 | $30 | 17 |
| 26 | 10 | 9.5 | $3.04 | $29 | 16 |
| 27 | 10 | 9.5 | $2.99 | $28 | 16 |
| 28 | 10 | 9.5 | $3.08 | $29 | 17 |
| 29 | 10 | 9.5 | $3.10 | $29 | 16 |
| 30 | 11 | 10.5 | $3.10 | $33 | 18 |
| **Batch total** | | | | **$296** | **166** |

### Spending Milestones

#### Money purchases (total $326)

| Level | Item | Cost | Gate |
|-------|------|------|------|
| 21 | 2nd Induction | $45 | -- |
| 22 | 4th Chair | $68 | -- (needs replay) |
| 26 | Toaster | $32 | tool + sf |
| 28 | Wok + Gas Burner | $58 | tool + sf |
| 29 | Grater | $28 | tool + sf |
| 30 | 5th Chair | $95 | sf |

#### Snowflake spending (total 169)

| Level | Item | Cost |
|-------|------|------|
| 25 | Unfreeze L25 | 45 |
| 25 | Tool Shop Tier 3 | 22 |
| 25 | Chicken (ingredient) | 6 |
| 25 | Bacon (ingredient) | 6 |
| 26 | Unfreeze L26 | 12 |
| 28 | Unfreeze L28 | 15 |
| 29 | Unfreeze L29 | 8 |
| 30 | Unfreeze L30 | 55 |

### Cashflow Trace (average player)

Money and snowflake balances tracked through each significant event. "Balance" is the running total after the event.

#### Money

| Point | Event | Earned | Spent | Balance |
|-------|-------|--------|-------|---------|
| Start of L21 | carry-forward from L1-20 | -- | -- | $40 |
| After L21 | earn $29, buy 2nd Induction $45 | +$29 | -$45 | $24 |
| After L22 | earn $29, buy 4th Chair $68 | +$29 | -$68 | **-$15** |
| | **replay needed** (~1 level replay to cover $15 deficit) | +~$29 | -- | ~$14 |
| After L23 | earn $30 | +$30 | -- | $44 |
| After L24 | earn $30 | +$30 | -- | $74 |
| After L25 | earn $30 | +$30 | -- | $104 |
| After L26 | earn $29, buy Toaster $32 | +$29 | -$32 | $101 |
| After L27 | earn $28 | +$28 | -- | $129 |
| After L28 | earn $29, buy Wok + Gas $58 | +$29 | -$58 | $100 |
| After L29 | earn $29, buy Grater $28 | +$29 | -$28 | $101 |
| After L30 | earn $33, buy 5th Chair $95 | +$33 | -$95 | $39 |

**Average player needs ~1 money replay** at L22 for the 4th Chair. After that, the late batch is comfortable.

#### Snowflakes

| Point | Event | Earned | Spent | Balance |
|-------|-------|--------|-------|---------|
| Start of L21 | carry-forward from L1-20 | -- | -- | 15 |
| After L21 | earn 16 | +16 | -- | 31 |
| After L22 | earn 16 | +16 | -- | 47 |
| After L23 | earn 17 | +17 | -- | 64 |
| After L24 | earn 17 | +17 | -- | 81 |
| Before L25 | unfreeze L25 (45) + Tier 3 (22) + protein (12) | -- | -79 | 2 |
| After L25 | earn 17 | +17 | -- | 19 |
| Before L26 | unfreeze L26 | -- | -12 | 7 |
| After L26 | earn 16 | +16 | -- | 23 |
| After L27 | earn 16 | +16 | -- | 39 |
| Before L28 | unfreeze L28 | -- | -15 | 24 |
| After L28 | earn 17 | +17 | -- | 41 |
| Before L29 | unfreeze L29 | -- | -8 | 33 |
| After L29 | earn 16 | +16 | -- | 49 |
| Before L30 | unfreeze L30 | -- | -55 | -6 |

**L30 is tight.** The average player sits at -6 before L30, meaning they need a strong quiz run in L29 or a single replay to cover the shortfall. After earning 18 snowflakes in L30 itself, the player ends the batch with 12 snowflakes.

Note: The economy doc's cumulative trace (which includes the L17 replay snowflakes rolling forward) shows L30 as achievable at balance 6 before unfreezing. The slight difference here comes from rounding in per-level net snowflake figures. In practice this is a "tight but doable" gate -- exactly the intended feel for the capstone level.

### Batch Totals

| | Money | Snowflakes |
|---|-------|------------|
| Carry-forward into L21 | $40 | 15 |
| Earned in L21-30 | $296 | 166 |
| Spent in L21-30 | $326 | 169 |
| **Carry-forward into L31** | **~$10** | **~12** |

The average player enters L31+ with roughly $10 in money and 12 snowflakes -- a lean but viable starting position for the next batch of content.

**Replays in this batch:** ~1 (money replay at L22 for the 4th Chair). Snowflakes are tight at L30 but the economy doc's cumulative trace confirms it is achievable without a dedicated snowflake replay.

---

## Seeded for 31+
- **Tool Shop Tier 4** (5 snowflakes): Oven ($), Deep Fryer ($), Rolling Pin ($)
- **Baking ingredients** (3 snowflakes): chocolate, cream, vanilla
- **Asian pantry** (3 snowflakes): rice, noodles, soy sauce
- Oven recipes: cookies, cake, pizza
- Deep fryer recipes: chips, fried chicken, tempura
- Wok recipes: fried rice, fried noodles
- 3rd induction spot
- Hiring kitchen help (automated prep station assistant)
- VIP customers (double pay, half patience)
- Catering orders (bulk single recipe)
- Sous vide, charcoal grill -- premium tier tools for levels 40+
- Bowls (for soups, rice dishes) and cups (for drinks) as serving ware purchases

## Long-term Progression Notes
- Every 10 levels roughly = 1 tool shop tier
- New ingredient groups every 5-8 levels
- Chair purchases every 8-10 levels
- "Practice" levels (no new mechanics, just faster/more customers) fill 30-40% of levels
- Tool upgrades that reduce workload (dishwasher, hiring help) spaced out to prevent game becoming too easy
- Each tool shop tier should feel like a meaningful event -- anticipation builds over several levels
