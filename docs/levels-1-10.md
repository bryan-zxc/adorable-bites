# Levels 1--10: Chef Training Academy

These are the foundational training levels. Every core game mechanic is introduced one at a time. After completing level 10, the player graduates as an official chef at A-Dora-ble Bites.

**Starting ingredients (free):** egg, butter, bread
**Starting equipment (free):** 1 pan, plates, 1 chair
**Starting resources:** $0 money, 0 snowflakes

---

## Level Narratives

### Level 1 -- First Order
- **Chairs:** 1 | **Plates:** 3 | **Customers:** 2
- **Tutorial:** "Welcome to A-Dora-ble Bites! Tap an ingredient, answer the quiz, then cook and serve!"
- **New mechanic:** Quiz to pick up ingredient, place in pan, tap pan to cook, pick up pan and tap customer to serve
- **What's automatic:** Money collection, table clearing, no overcooking, no customer timer
- **Recipes:** Fried Egg (egg -> pan)
- **Goal:** Learn the absolute basics. No pressure. Only 2 customers so the first experience is short and sweet.

### Level 2 -- Patience
- **Chairs:** 1 | **Plates:** 3 | **Customers:** 4
- **Tutorial:** "Watch out! Customers won't wait forever -- keep an eye on the timer above their heads!"
- **New mechanic:** Customer waiting timer (generous -- long patience)
- **What's automatic:** Money collection, table clearing, no overcooking
- **Recipes:** Fried Egg
- **Goal:** Learn that customers won't wait forever. Still relaxed.

### Level 3 -- Don't Burn It!
- **Chairs:** 1 | **Plates:** 3 | **Customers:** 3
- **Tutorial:** "Careful -- food can burn! Grab it from the pan quickly once it's cooked!"
- **New mechanic:** Overcooking / burn timer introduced (generous grace period)
- **New recipe:** Pan Toast (bread -> pan)
- **What's automatic:** Money collection, table clearing
- **Recipes:** Fried Egg, Pan Toast
- **Goal:** Learn overcooking with a forgiving timer. New recipe keeps it fresh -- toast burning feels natural and intuitive.

### Level 4 -- Collect Your Pay & Quiz Challenge
- **Chairs:** 1 | **Plates:** 3 | **Customers:** 3
- **Tutorial:** "Time to collect your pay! Tap the money on the table after customers finish eating."
- **New mechanic:** Money collection -- must tap money on table after customer finishes eating. Money no longer auto-collects. **Quiz difficulty selection** introduced -- can choose +1 (1 snowflake), +2 (2 snowflakes), or +3 (3 snowflakes). (Ticket #10)
- **What's automatic:** Table clearing
- **Recipes:** Fried Egg, Pan Toast
- **Goal:** Learn the money tap (simple addition to the flow) and quiz difficulty (optional upgrade). Both are light additions. Quiz difficulty lets them earn snowflakes faster to prepare for the shop at level 8.

### Level 5 -- Clean Up
- **Chairs:** 1 | **Plates:** 3 | **Customers:** 3
- **Frozen cost:** 7 snowflakes
- **Tutorial:** "Customers are messy! Tap the dirty plate to clear the table."
- **New mechanic:** Table clearing -- must tap dirty plate to send to sink. No more auto-clearing.
- **What's automatic:** Nothing -- all manual from here
- **Recipes:** Fried Egg, Pan Toast
- **Goal:** Full serve->eat->money+plate->clear cycle. Still 1 customer at a time so not overwhelming.

### Level 6 -- Wash the Dishes
- **Chairs:** 1 | **Plates:** 2 | **Customers:** 5
- **Tutorial:** "Only 2 plates today! Wash dirty dishes at the sink so you can reuse them."
- **New mechanic:** Dishwashing. Only 2 plates -- must tap dirty plate at sink to wash and reuse. Plates are now a limited resource.
- **Recipes:** Fried Egg, Pan Toast
- **Goal:** Feel the plate crunch. Learn to wash dishes promptly or you can't serve the next customer.

### Level 7 -- The Rush
- **Chairs:** 1 | **Plates:** 2 | **Customers:** 5
- **Tutorial:** "It's getting busy! Customers will queue at the door -- don't keep them waiting!"
- **New mechanic:** Multiple customers start arriving (Poisson, slow rate). Door queue with 10s timer. All foundational mechanics now active simultaneously.
- **New recipe:** Buttered Egg (egg+butter -> pan)
- **Recipes:** Fried Egg, Pan Toast, Buttered Egg
- **Goal:** Hardest training level. Everything is on. New recipe as reward. Learn to juggle cooking + clearing + washing + door queue with only 1 chair.

### Level 8 -- Open for Business
- **Chairs:** 1->2 | **Plates:** 2 | **Customers:** 7
- **Tutorial:** "The shop is open! Buy a second chair to seat more customers."
- **New mechanic:** Shop introduced! Can buy 2nd chair ($). First purchase experience.
- **Recipes:** Fried Egg, Pan Toast, Buttered Egg
- **Goal:** Relief from door queue. Learn the shop. Managing 2 seated customers for the first time.

### Level 9 -- Getting Comfortable
- **Chairs:** 2 | **Plates:** 2->3 | **Customers:** 7
- **New mechanic:** Can buy extra plate ($) from shop. Practice with 2 chairs.
- **Recipes:** Fried Egg, Pan Toast, Buttered Egg
- **Goal:** Settle into the full game loop with 2 chairs. Build confidence.

### Level 10 -- Graduation Day
- **Chairs:** 2 | **Plates:** 3 | **Customers:** 7
- **Frozen cost:** 20 snowflakes
- **New mechanic:** Faster customer arrival (Poisson medium). Prove yourself under pressure. **Tool Shop Tier 1 unfreezes as graduation reward** (costs 12 snowflakes).
- **Recipes:** Fried Egg, Pan Toast, Buttered Egg
- **Goal:** Final test. Show you can handle the full game. Celebration screen: "Congratulations! You are now an official chef at A-Dora-ble Bites!" Tier 1 shop unfreezes new possibilities for level 11+.

---

## Level Config Table

| Level | Chairs | Plates | Customers | Arrival | Seq time | Recipes | Frozen cost | Duration | Tutorial | New mechanic / recipe |
|-------|--------|--------|-----------|---------|----------|---------|-------------|----------|----------|-----------------------|
| 1 | 1 | 3 | 2 | seq | 33.0s | Fried Egg | -- | ~1.1 min | Welcome + basics | Quiz pickup, pan cook, serve |
| 2 | 1 | 3 | 4 | seq | 33.0s | Fried Egg | 1 sf | ~2.2 min | Customer timer warning | Customer waiting timer |
| 3 | 1 | 3 | 3 | seq | 33.0s | Fried Egg, Pan Toast | 2 sf | ~1.7 min | Burn warning | Overcooking / burn timer; Pan Toast |
| 4 | 1 | 3 | 3 | seq | 35.0s | Fried Egg, Pan Toast | 1 sf | ~1.8 min | Money collection | Money collection; quiz difficulty |
| 5 | 1 | 3 | 3 | seq | 37.0s | Fried Egg, Pan Toast | 7 sf | ~1.9 min | Table clearing | Table clearing (all manual) |
| 6 | 1 | 2 | 5 | seq | 40.0s | Fried Egg, Pan Toast | 1 sf | ~3.3 min | Plate limit + washing | Dishwashing (plate limit) |
| 7 | 1 | 2 | 5 | 45s | 44.3s | Fried Egg, Pan Toast, Buttered Egg | 1 sf | ~3.7 min | Door queue | Poisson arrival + door queue; Buttered Egg |
| 8 | 2 | 2 | 7 | 35s | 44.3s | Fried Egg, Pan Toast, Buttered Egg | 1 sf | ~4.2 min | Shop intro | Shop + 2nd chair ($30) |
| 9 | 2 | 3 | 7 | 35s | 44.3s | Fried Egg, Pan Toast, Buttered Egg | 1 sf | ~4.2 min | -- | Extra plate ($15) |
| 10 | 2 | 3 | 7 | 35s | 44.3s | Fried Egg, Pan Toast, Buttered Egg | 20 sf | ~4.2 min | -- | Faster Poisson; Tier 1 (12 sf) |

- **Arrival:** "seq" = next customer arrives when chair clears (no overlap). Seconds = Poisson mean interval.

### Poisson Customer Arrival (L7+)

From L7 onwards, customers arrive on a Poisson timer that runs independently of gameplay:

- A random timer (mean = arrival interval) fires in the background, spawning customers until all for the level have arrived
- **First customer** arrives immediately at level start (no wait)
- **Clear seat available**: customer sits immediately
- **No clear seat, door is empty**: customer stands at door with a door timer
- **No clear seat, door already occupied**: customer does NOT spawn — the remaining customer count stays the same (totalCustomersSpawned is NOT incremented), and we wait for the next Poisson tick to try again
- The Poisson timer is completely independent of cooking, serving, or table clearing — it just keeps ticking
- "seq" levels (L1-6) do NOT use Poisson — the next customer spawns only after the previous customer's seat is fully cleared
- **Seq time:** per-customer sequential cycle time from the timing model.
- **Frozen cost:** snowflake cost to unfreeze. L1 is free (starting level). All other levels cost at least 1 sf; special frozen levels cost more.
- **Duration:** strong-player estimate (no missed customers).
- **Tutorial:** short label for the tutorial message shown at level start (see Tutorial Messages section for full text).

---

## Feature Flags

| Level | autoCollectMoney | autoClearTable | canOvercook | hasCustomerTimer |
|-------|------------------|----------------|-------------|------------------|
| 1 | yes | yes | no | no |
| 2 | yes | yes | no | yes |
| 3 | yes | yes | yes | yes |
| 4 | no | yes | yes | yes |
| 5 | no | no | yes | yes |
| 6 | no | no | yes | yes |
| 7 | no | no | yes | yes |
| 8 | no | no | yes | yes |
| 9 | no | no | yes | yes |
| 10 | no | no | yes | yes |

- **autoCollectMoney:** money appears on the table automatically after the customer eats. Turns off at L4 (player must tap to collect).
- **autoClearTable:** dirty plates clear themselves. Turns off at L5 (player must tap to send plate to sink).
- **canOvercook:** food can burn if left too long on the pan. Turns on at L3.
- **hasCustomerTimer:** customers have a patience timer and can leave angry. Turns on at L2.

---

## Tutorial Messages

Tutorial messages are shown once at the start of each level. They introduce the new mechanic for that level in a friendly, age-appropriate way.

| Level | Tutorial Message |
|-------|-----------------|
| 1 | "Welcome to A-Dora-ble Bites! Tap an ingredient, answer the quiz, then cook and serve!" |
| 2 | "Watch out! Customers won't wait forever -- keep an eye on the timer above their heads!" |
| 3 | "Careful -- food can burn! Grab it from the pan quickly once it's cooked!" |
| 4 | "Time to collect your pay! Tap the money on the table after customers finish eating." |
| 5 | "Customers are messy! Tap the dirty plate to clear the table." |
| 6 | "Only 2 plates today! Wash dirty dishes at the sink so you can reuse them." |
| 7 | "It's getting busy! Customers will queue at the door -- don't keep them waiting!" |
| 8 | "The shop is open! Buy a second chair to seat more customers." |

Levels 9 and 10 have no tutorial message (no new mechanic that requires explanation).

---

## Economy -- Levels 1 to 10

### Starting Resources

| Resource | Amount |
|----------|--------|
| Money | $0 |
| Snowflakes | 0 |

### Snowflake Reward System

Snowflakes are earned through two channels during each level:

**1. Quiz snowflakes (earned during gameplay)**

Each customer requires a quiz to pick up their ingredient. Correct answers earn snowflakes based on the question difficulty; wrong answers deduct 1 snowflake.

| Difficulty Setting | Possible Questions | Snowflake per correct |
|-------------------|-------------------|----------------------|
| +1 | +1 | 1 |
| +2 | random mix of +1 and +2 | 1 or 2 |
| +3 | random mix of +1, +2, and +3 | 1, 2, or 3 |

Wrong answers always deduct 1 snowflake regardless of difficulty. Future difficulty levels will be introduced as the game progresses (subtraction, multiplication, larger numbers, etc.).

**2. Level-end bonus (awarded after the level is complete)**

| Missed answers during the level | Bonus snowflakes |
|---------------------------------|-----------------|
| 0 missed | 3 sf |
| 1 missed | 2 sf |
| 2 or more missed | 1 sf |

**Negative protection:** If the player's net snowflakes for the level are negative (more wrong answers than correct), nothing counts -- the level's snowflake earnings are zeroed out and the player must retry the level to earn snowflakes.

### Unfreeze Costs

Every level costs 1 snowflake to unfreeze, except L1 (free as the starting level) and special frozen levels which cost more.

| Level | Unfreeze cost |
|-------|--------------|
| 1 | 0 (free -- starting level) |
| 2 | 1 sf |
| 3 | 1 sf |
| 4 | 1 sf |
| 5 | 7 sf |
| 6 | 1 sf |
| 7 | 1 sf |
| 8 | 1 sf |
| 9 | 1 sf |
| 10 | 20 sf |
| **Total** | **34 sf** |

### Earnings per Level (Average Player)

Average player: 80% accuracy, +2 difficulty from L4, misses 0 customers in training (L1--L5), misses 0.5 customers from L6+, 35% tip rate. Quizzes attempted for ALL customers (including any who might leave -- you pick up the ingredient before you know if the customer will leave).

| Level | Cust | Served | Avg $/serve | Money | Quiz sf | Bonus | Total sf |
|-------|------|--------|-------------|-------|---------|-------|----------|
| 1 | 2 | 2.0 | 1.35 | 3 | 1 | 3 | 4 |
| 2 | 4 | 4.0 | 1.35 | 5 | 2 | 3 | 5 |
| 3 | 4 | 4.0 | 1.35 | 5 | 2 | 3 | 5 |
| 4 | 3 | 3.0 | 1.35 | 4 | 3 | 3 | 6 |
| 5 | 3 | 3.0 | 1.35 | 4 | 3 | 3 | 6 |
| 6 | 5 | 4.5 | 1.35 | 6 | 5 | 2 | 7 |
| 7 | 5 | 4.5 | 1.68 | 8 | 6 | 2 | 8 |
| 8 | 7 | 6.5 | 1.68 | 11 | 9 | 2 | 11 |
| 9 | 7 | 6.5 | 1.68 | 11 | 9 | 2 | 11 |
| 10 | 7 | 6.5 | 1.68 | 11 | 9 | 2 | 11 |

### Spending Milestones (within this batch)

| When | Item | Currency | Cost |
|------|------|----------|------|
| Before each level (except L1) | Unfreeze level | Snowflakes | 1 sf (or 7/20 for special levels) |
| L8 (shop opens) | 2nd Chair | Money | $30 |
| L9 | Extra Plate | Money | $15 |
| After L10 (graduation) | Tool Shop Tier 1 | Snowflakes | 12 sf |

### Cashflow Trace -- Snowflakes

| Point | Balance | Event | Cost | After |
|-------|---------|-------|------|-------|
| After L1 | 4 | Earned 4 (1 quiz + 3 bonus) | -- | 4 |
| Before L2 | 4 | Unfreeze L2 | 1 | 3 |
| After L2 | 3 | Earned 5 | -- | 8 |
| Before L3 | 8 | Unfreeze L3 | 1 | 7 |
| After L3 | 7 | Earned 5 | -- | 12 |
| Before L4 | 12 | Unfreeze L4 | 1 | 11 |
| After L4 | 11 | Earned 6 | -- | 17 |
| Before L5 | 17 | Unfreeze L5 | 7 | 10 |
| After L5 | 10 | Earned 6 | -- | 16 |
| Before L6 | 16 | Unfreeze L6 | 1 | 15 |
| After L6 | 15 | Earned 7 | -- | 22 |
| Before L7 | 22 | Unfreeze L7 | 1 | 21 |
| After L7 | 21 | Earned 8 | -- | 29 |
| Before L8 | 29 | Unfreeze L8 | 1 | 28 |
| After L8 | 28 | Earned 11 | -- | 39 |
| Before L9 | 39 | Unfreeze L9 | 1 | 38 |
| After L9 | 38 | Earned 11 | -- | 49 |
| Before L10 | 49 | Unfreeze L10 | 20 | 29 |
| After L10 | 29 | Earned 11 | -- | 40 |
| Graduation | 40 | Buy Tier 1 | 12 | **28** |

### Cashflow Trace -- Money

| Point | Cumul earned | Cumul spent | Available | Purchase | Cost | After |
|-------|-------------|-------------|-----------|----------|------|-------|
| After L1--L7 | $35 | $0 | $35 | -- | -- | $35 |
| After L8 | $46 | $0 | $46 | 2nd Chair | $30 | $16 |
| After L9 | $57 | $30 | $27 | Extra Plate | $15 | $12 |
| After L10 | $68 | $45 | -- | -- | -- | $23 |

### Batch Totals

| Category | Earned | Spent | Net |
|----------|--------|-------|-----|
| Money | $68 | $45 ($30 chair + $15 plate) | +$23 |
| Snowflakes | 74 | 46 (34 unfreezes + 12 Tier 1) | +28 |

### Carry-Forward into Levels 11--20

| Resource | Balance |
|----------|---------|
| Money | $23 |
| Snowflakes | 28 |

The player enters Level 11 with $23 and 28 snowflakes. Level 11 requires unfreezing (8 sf) plus buying the knife ($15) and unfreezing three produce ingredients (potato 4 sf, onion 4 sf, tomato 4 sf = 12 sf total). That costs $15 money and 20 snowflakes -- comfortably within reach.

---

## Mechanic Summary

| Mechanic | Introduced at |
|----------|--------------|
| Quiz + ingredient pickup | Level 1 |
| Place in pan + cook + serve to customer | Level 1 |
| Customer waiting timer | Level 2 |
| Overcooking / burn timer | Level 3 |
| Money collection (tap to collect) | Level 4 |
| Quiz difficulty selection (Ticket #10) | Level 4 |
| Table clearing (tap dirty plate) | Level 5 |
| Dishwashing (wash plates to reuse) | Level 6 |
| Multiple customers + door queue | Level 7 |
| Shop + buying chairs/plates | Level 8 |
| All mechanics at speed | Level 10 |

## Recipe Summary

| Recipe | Introduced at | Ingredients | Method |
|--------|--------------|-------------|--------|
| Fried Egg | Level 1 | egg | pan |
| Pan Toast | Level 3 | bread | pan |
| Buttered Egg | Level 7 | egg + butter | pan |

**Tool Shop Tier 1** (unfreezes after level 10, costs 12 snowflakes):
- Knife ($15)
- Pot ($28)

**Starting free items:** egg, butter, bread, 1 pan, 3 plates (reduced to 2 at level 6), 1 chair
