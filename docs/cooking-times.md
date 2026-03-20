# Cooking Times

Cooking time is determined by the ingredients in the pan/pot/wok — the sum of each ingredient's individual cook time. Prep steps (chop, peel, grate, mix) happen before cooking and don't affect cook duration.

## Design Intent

- **L1-10 (training):** Cook times are halved so the player can focus on learning mechanics without waiting.
- **L11+ (real mode):** Full cook times apply. This is where cooking becomes a bottleneck and parallel prep (starting the next order while the current one cooks) becomes essential.
- **Wok:** Reduces total cook time by 40% — the speed tool that rewards the player for buying it.

## Ingredient Cook Times

| Ingredient | Cook Time | Notes |
|-----------|-----------|-------|
| egg | 8s | Quick to fry |
| bread | 6s | Toast is fast |
| butter | 2s | Melts instantly |
| potato | 12s | Dense, takes longer |
| onion | 8s | Medium |
| tomato | 6s | Soft, quick |
| flour | 4s | Part of batter |
| milk | 2s | Liquid |
| sugar | 2s | Dissolves |
| chicken | 14s | Meat takes longest |
| bacon | 10s | Meat but thin |

## Recipe Cook Times

Total cook time = sum of ingredient cook times.

| Recipe | Ingredients | Sum | Real Cook | Training (x0.5) | Wok (x0.6) |
|--------|-----------|-----|-----------|-----------------|------------|
| Fried Egg | egg | 8 | 8s | 4s | — |
| Pan Toast | bread | 6 | 6s | 3s | — |
| Buttered Egg | egg + butter | 8+2 | 10s | 5s | — |
| Fried Potato | potato | 12 | 12s | — | — |
| Fried Onion Egg | onion + egg | 8+8 | 16s | — | — |
| Boiled Potato | potato | 12 | 12s | — | — |
| Boiled Veges | tomato + potato | 6+12 | 18s | — | — |
| Scrambled Egg | egg | 8 | 8s | — | — |
| Pancakes | flour + egg + milk | 4+8+2 | 14s | — | — |
| Hash Brown | potato | 12 | 12s | — | — |
| Omelette | egg + tomato + onion | 8+6+8 | 22s | — | — |
| Potato Soup | potato + onion | 12+8 | 20s | — | — |
| Bacon | bacon | 10 | 10s | — | — |
| Bacon & Eggs | bacon + egg | 10+8 | 18s | — | — |
| Stir Fry Chicken | chicken + onion | 14+8 | 22s | — | 13s |
| Hash Brown Deluxe | potato | 12 | 12s | — | — |

## Modifiers

| Modifier | Effect | Available |
|----------|--------|-----------|
| Training mode (L1-10) | Cook time x 0.5 | L1-10 |
| Wok | Cook time x 0.6 | L28+ |

## Why This Matters

The cooking bottleneck drives tool purchases:

- **L11-16 (1 induction):** Single pan means waiting 6-9s per meal. Player starts to feel the wait.
- **L13 (pot):** Pot cooks independently from pan. Boil potato (6s) while frying egg (4s) — first real parallel cooking.
- **L17 (mixer):** Mixer prep takes time, but so does cooking. Player can mix the next order while the current one cooks.
- **L20 (2nd induction):** Two pans cooking simultaneously. Directly halves the cooking bottleneck.
- **L28 (wok):** 40% faster cooking. Stir fry chicken goes from 11s to 7s — noticeably snappier.
