#!/usr/bin/env python3
"""
Level Calculator for Adorable Bites

Computes timing, customer counts, arrival rates, and economy projections
for game levels based on the timing model and economy constraints defined
in docs/resource-economy.md.

Usage:
    python level_calculator.py <level_number> [--chairs N] [--plates N] [--recipes "R1,R2,..."]
    python level_calculator.py --all                # Recalculate all 30 levels
    python level_calculator.py --economy            # Full economy projection
"""

import argparse
from dataclasses import dataclass


# ---------------------------------------------------------------------------
# Recipe database
# ---------------------------------------------------------------------------

@dataclass
class Recipe:
    name: str
    ingredients: int
    steps: int          # chop, peel, grate, mix — each counts as 1
    has_mixing: bool
    cook_device: str    # pan, pot, wok, toaster
    introduced_at: int  # level number
    cook_time: float    # sum of ingredient cook times (from cooking-times.md)

    @property
    def base_pay(self) -> int:
        return self.ingredients + self.steps

    @property
    def tip_pay(self) -> int:
        return self.base_pay + 1

    @property
    def active_base(self) -> float:
        """Active player time for prep: quiz+pickup (13s/ing) + steps (3s/step) + mixer (5s) + device handling (4s)"""
        return 13 * self.ingredients + 3 * self.steps + (5 if self.has_mixing else 0) + 4

    @property
    def passive_time(self) -> float:
        """Passive time: mixer animation + cook + eat"""
        return (2 if self.has_mixing else 0) + self.cook_time + 6


# Cook times from docs/cooking-times.md:
# egg=8, bread=6, butter=2, potato=12, onion=8, tomato=6,
# flour=4, milk=2, sugar=2, chicken=14, bacon=10
RECIPES = [
    Recipe("Fried Egg",          1, 0, False, "pan", 1,  8),       # egg
    Recipe("Pan Toast",          1, 0, False, "pan", 3,  6),       # bread
    Recipe("Buttered Egg",       2, 0, False, "pan", 7,  10),      # egg+butter
    Recipe("Fried Potato",       1, 1, False, "pan", 11, 12),      # potato
    Recipe("Fried Onion Egg",    2, 1, False, "pan", 12, 16),      # onion+egg
    Recipe("Boiled Potato",      1, 1, False, "pot", 13, 12),      # potato
    Recipe("Boiled Veges",       2, 2, False, "pot", 14, 18),      # tomato+potato
    Recipe("Scrambled Egg",      1, 1, True,  "pan", 17, 8),       # egg
    Recipe("Pancakes",           3, 1, True,  "pan", 18, 14),      # flour+egg+milk
    Recipe("Hash Brown",         1, 2, False, "pan", 20, 12),      # potato
    Recipe("Omelette",           3, 3, True,  "pan", 22, 22),      # egg+tomato+onion
    Recipe("Potato Soup",        2, 2, False, "pot", 23, 20),      # potato+onion
    Recipe("Bacon",              1, 0, False, "pan", 26, 10),      # bacon
    Recipe("Bacon & Eggs",       2, 0, False, "pan", 27, 18),      # bacon+egg
    Recipe("Stir Fry Chicken",   2, 2, False, "wok", 28, 22),      # chicken+onion
    Recipe("Hash Brown Deluxe",  1, 2, False, "pan", 29, 12),      # potato
]

RECIPE_BY_NAME = {r.name: r for r in RECIPES}


def recipes_at_level(level: int) -> list[Recipe]:
    """All recipes available at a given level (cumulative pool)."""
    return [r for r in RECIPES if r.introduced_at <= level]


# ---------------------------------------------------------------------------
# Level automation
# ---------------------------------------------------------------------------

def post_active_time(level: int, has_dishwasher: bool = False) -> float:
    """Post-serve active taps: serve + money + clear + wash."""
    if level <= 3:
        return 2  # serve only (auto money, auto clear, no wash)
    elif level == 4:
        return 4  # serve + money
    elif level == 5:
        return 6  # serve + money + clear
    elif has_dishwasher or level >= 19:
        return 6  # serve + money + clear (dishwasher handles wash)
    else:
        return 9  # serve + money + clear + wash


# ---------------------------------------------------------------------------
# Parallelism overhead factors
# ---------------------------------------------------------------------------

OVERHEAD_BY_CHAIRS = {1: 1.0, 2: 1.15, 3: 1.10, 4: 1.08, 5: 1.05}


def overhead_factor(chairs: int) -> float:
    return OVERHEAD_BY_CHAIRS.get(chairs, 1.05)


# ---------------------------------------------------------------------------
# Achievability model
# ---------------------------------------------------------------------------

@dataclass
class Achievability:
    """Analyses whether a level is achievable with given chairs and cooking devices."""
    chairs: int
    cooking_devices: int
    avg_active_prep: float    # player active time per customer (quiz + prep + post-serve)
    avg_cook_time: float      # time food occupies a cooking device
    eat_clear_time: float     # time seat is blocked (eating + money + clear)
    throughput_per_min: float  # customers servable per minute
    max_customers_in_7min: int  # max customers in target duration
    bottleneck: str           # what limits throughput: "prep", "cooking", or "chairs"

    def __str__(self):
        return (
            f"  {self.chairs} chairs, {self.cooking_devices} devices: "
            f"throughput={self.throughput_per_min:.1f}/min, "
            f"max={self.max_customers_in_7min} in 7min, "
            f"bottleneck={self.bottleneck}"
        )


def analyse_achievability(
    recipe_pool: list[Recipe],
    chairs: int,
    cooking_devices: int,
    post_active: float,
    is_training: bool = False,
) -> Achievability:
    """Calculate throughput and bottleneck for a given setup.

    The marginal time per customer = max of three bottlenecks:
    1. Player active prep (quiz + pickup + steps + post-serve) — can only do one at a time
    2. Cooking device time / num_devices — each device cooks one thing at a time
    3. Eat + clear time / chairs — seats are occupied while eating

    With overlap: while food cooks, player can prep the next order.
    So effective marginal = max(active_prep, cook_time/devices, eat_clear/chairs)
    """
    if not recipe_pool:
        return Achievability(chairs, cooking_devices, 0, 0, 0, 0, 0, "none")

    # Average active prep per customer (quiz + pickup + steps + mixer overhead)
    avg_active_base = sum(r.active_base for r in recipe_pool) / len(recipe_pool)
    avg_active_prep = avg_active_base + post_active

    # Average cooking time (sum of ingredient cook times)
    avg_cook = sum(r.cook_time for r in recipe_pool) / len(recipe_pool)
    if is_training:
        avg_cook *= 0.5

    # Eat + clear time (seat occupied)
    eat_clear = 6.0 + post_active  # eating (6s) + money/clear/wash taps

    # Three bottlenecks
    prep_bottleneck = avg_active_prep
    cook_bottleneck = avg_cook / max(1, cooking_devices)
    chair_bottleneck = eat_clear / max(1, chairs)

    marginal = max(prep_bottleneck, cook_bottleneck, chair_bottleneck)

    if marginal == prep_bottleneck:
        bottleneck = "prep"
    elif marginal == cook_bottleneck:
        bottleneck = "cooking"
    else:
        bottleneck = "chairs"

    throughput = 60.0 / marginal if marginal > 0 else 0
    max_in_7min = int(7 * 60 / marginal) if marginal > 0 else 0

    return Achievability(
        chairs=chairs,
        cooking_devices=cooking_devices,
        avg_active_prep=avg_active_prep,
        avg_cook_time=avg_cook,
        eat_clear_time=eat_clear,
        throughput_per_min=throughput,
        max_customers_in_7min=max_in_7min,
        bottleneck=bottleneck,
    )


def find_minimum_setup(
    recipe_pool: list[Recipe],
    target_customers: int,
    post_active: float,
    is_training: bool = False,
    max_chairs: int = 5,
    max_devices: int = 3,
) -> list[tuple[int, int, Achievability, bool]]:
    """Find minimum chairs + cooking devices needed to serve target_customers in 7 min.
    Returns (chairs, devices, achievability, is_ok) sorted by total equipment count."""
    results: list[tuple[int, int, Achievability, bool]] = []
    for c in range(1, max_chairs + 1):
        for d in range(1, max_devices + 1):
            a = analyse_achievability(recipe_pool, c, d, post_active, is_training)
            ok = a.max_customers_in_7min >= target_customers
            results.append((c, d, a, ok))

    results.sort(key=lambda x: (not x[3], x[0] + x[1]))
    return results


import math

def expected_concurrent(
    chairs: int,
    arrival_interval: float,
    avg_service_time: float,
) -> int:
    """Calculate expected concurrent customers from Poisson arrival rate.

    If customers arrive every `arrival_interval` seconds and each occupies
    a seat for `avg_service_time` seconds, the expected concurrency is
    how many customers overlap at peak.

    Returns min(chairs, ceil(avg_service_time / arrival_interval)).
    For sequential levels (arrival_interval=0), returns 1.
    """
    if arrival_interval <= 0:
        return 1
    return min(chairs, math.ceil(avg_service_time / arrival_interval))


def calculate_patience(
    base_wait: float,
    chairs: int,
    arrival_interval: float,
    avg_service_time: float,
) -> tuple[float, float]:
    """Calculate customer patience and tip window based on expected concurrency.

    patience = base_wait + (concurrent - 1) × base_wait × 0.2
    tip_window = patience × 0.4 (first 40%)

    Returns (patience, tip_window).
    """
    concurrent = expected_concurrent(chairs, arrival_interval, avg_service_time)
    patience = base_wait + (concurrent - 1) * base_wait * 0.2
    tip_window = patience * 0.4
    return (patience, tip_window)


# ---------------------------------------------------------------------------
# Player profiles
# ---------------------------------------------------------------------------

@dataclass
class PlayerProfile:
    name: str
    missed_per_level: float   # customers missed (0 for strong, 0.5 avg, 2 slow)
    quiz_accuracy: float      # 0-1
    difficulty: int            # 1, 2, or 3
    tip_rate: float            # fraction of serves that get tips
    training_miss: float = 0   # missed during L1-5 training

    @property
    def net_snowflake_per_quiz(self) -> float:
        """Expected snowflakes per quiz attempt."""
        avg_reward = {1: 1.0, 2: 1.5, 3: 2.0}[self.difficulty]
        return self.quiz_accuracy * avg_reward - (1 - self.quiz_accuracy) * 1

    def net_snowflake_per_quiz_at_diff(self, diff: int) -> float:
        avg_reward = {1: 1.0, 2: 1.5, 3: 2.0}[diff]
        return self.quiz_accuracy * avg_reward - (1 - self.quiz_accuracy) * 1

    def avg_pay(self, recipe_pool: list[Recipe]) -> float:
        """Average $ per served customer given the recipe pool."""
        if not recipe_pool:
            return 0
        avg_base = sum(r.base_pay for r in recipe_pool) / len(recipe_pool)
        avg_tip = sum(r.tip_pay for r in recipe_pool) / len(recipe_pool)
        return avg_base * (1 - self.tip_rate) + avg_tip * self.tip_rate


PROFILES = {
    "strong":  PlayerProfile("Strong",  0,   0.90, 3, 0.50, training_miss=0),
    "average": PlayerProfile("Average", 0.5, 0.80, 2, 0.35, training_miss=0),
    "slow":    PlayerProfile("Slow",    2.0, 0.70, 1, 0.20, training_miss=1.0),
}


# ---------------------------------------------------------------------------
# Timing calculations
# ---------------------------------------------------------------------------

@dataclass
class LevelTiming:
    level: int
    chairs: int
    plates: int
    customers: int
    recipes: list[str]
    arrival_interval: float  # seconds, 0 = sequential
    avg_active: float
    avg_passive: float
    avg_sequential: float
    marginal_time: float
    strong_duration_s: float

    @property
    def strong_duration_min(self) -> float:
        return self.strong_duration_s / 60

    def __str__(self):
        arrival = "seq" if self.arrival_interval == 0 else f"{self.arrival_interval:.0f}s"
        return (
            f"L{self.level}: {self.customers} cust, {self.chairs} chairs | "
            f"active={self.avg_active:.1f}s passive={self.avg_passive:.1f}s "
            f"seq={self.avg_sequential:.1f}s marginal={self.marginal_time:.1f}s | "
            f"arrival={arrival} | "
            f"duration={self.strong_duration_min:.1f}min"
        )


def calculate_timing(
    level: int,
    chairs: int,
    plates: int,
    recipe_names: list[str] | None = None,
    customers: int | None = None,
    target_min: tuple[float, float] = (5.0, 7.0),
    has_dishwasher: bool = False,
) -> LevelTiming:
    """Calculate timing for a level. If customers is None, compute optimal count."""

    # Resolve recipe pool
    if recipe_names:
        pool = [RECIPE_BY_NAME[n] for n in recipe_names if n in RECIPE_BY_NAME]
    else:
        pool = recipes_at_level(level)

    if not pool:
        pool = recipes_at_level(level)

    # Average times across recipe pool
    avg_active_base = sum(r.active_base for r in pool) / len(pool)
    avg_passive = sum(r.passive_time for r in pool) / len(pool)
    post = post_active_time(level, has_dishwasher)
    avg_active = avg_active_base + post
    avg_seq = avg_active + avg_passive

    # Parallelism
    of = overhead_factor(chairs)

    if chairs == 1:
        marginal = avg_seq  # no overlap
    else:
        marginal = avg_active * of  # passive overlaps with next customer's active

    # Determine customer count
    if customers is not None:
        n = customers
    else:
        # Training levels (L1-7) have shorter targets
        if level <= 5:
            target_min = (1.5, 2.5)
        elif level <= 7:
            target_min = (3.0, 4.0)
        elif level <= 10:
            target_min = (4.0, 5.0)

        target_s = (target_min[0] * 60, target_min[1] * 60)

        if chairs == 1:
            n = round((target_s[0] + target_s[1]) / 2 / avg_seq)
        else:
            # total = seq + (n-1) * marginal → n = (total - seq) / marginal + 1
            target_mid = (target_s[0] + target_s[1]) / 2
            n = round((target_mid - avg_seq) / marginal + 1)

        n = max(3, n)

    # Calculate duration for strong player
    if chairs == 1:
        duration = n * avg_seq
    else:
        duration = avg_seq + (n - 1) * marginal

    # Arrival interval
    if chairs == 1 and level <= 6:
        arrival = 0  # sequential
    else:
        buffer = avg_seq
        window = duration - buffer
        if n > 1:
            arrival = window / (n - 1)
            arrival = max(20, round(arrival / 5) * 5)  # round to nearest 5s, min 20s
        else:
            arrival = 0

    return LevelTiming(
        level=level,
        chairs=chairs,
        plates=plates,
        customers=n,
        recipes=[r.name for r in pool],
        arrival_interval=arrival,
        avg_active=avg_active,
        avg_passive=avg_passive,
        avg_sequential=avg_seq,
        marginal_time=marginal,
        strong_duration_s=duration,
    )


# ---------------------------------------------------------------------------
# Economy calculations
# ---------------------------------------------------------------------------

@dataclass
class LevelEconomy:
    level: int
    customers: int
    profile: str
    served: float
    avg_pay: float
    money: int
    quiz_snowflakes: int
    level_bonus: int
    total_snowflakes: int   # quiz + bonus; 0 if net negative (must retry)
    quizzes: float
    missed: float

    def __str__(self):
        return (
            f"L{self.level} ({self.profile}): "
            f"served={self.served:.1f}/{self.customers} "
            f"money=${self.money} snowflakes={self.total_snowflakes} "
            f"(quiz={self.quiz_snowflakes} + bonus={self.level_bonus})"
        )


def level_end_bonus(missed: float) -> int:
    """Snowflake bonus at level end based on customers missed.
    0 missed = 3sf, 1 missed = 2sf, 2+ missed = 1sf."""
    if missed < 0.5:
        return 3
    elif missed < 1.5:
        return 2
    else:
        return 1


def calculate_economy(
    level: int,
    customers: int,
    recipe_names: list[str] | None = None,
    profile_name: str = "average",
) -> LevelEconomy:
    """Calculate money and snowflakes earned for a level + profile."""

    profile = PROFILES[profile_name]
    pool = [RECIPE_BY_NAME[n] for n in recipe_names] if recipe_names else recipes_at_level(level)

    # Customers served
    miss = profile.training_miss if level <= 5 else profile.missed_per_level
    served = max(0, customers - miss)
    missed = customers - served

    # Money
    avg_pay = profile.avg_pay(pool)
    money = round(served * avg_pay)

    # Quiz snowflakes — quizzes attempted for ALL customers
    avg_ingredients = sum(r.ingredients for r in pool) / len(pool)
    quizzes = customers * avg_ingredients

    # Net snowflakes from quizzes
    if level <= 3:
        net_per_quiz = profile.net_snowflake_per_quiz_at_diff(1)
    else:
        net_per_quiz = profile.net_snowflake_per_quiz

    quiz_snow = round(quizzes * net_per_quiz - missed * 1)

    # Level-end bonus: 3sf (0 missed), 2sf (1 missed), 1sf (2+ missed)
    bonus = level_end_bonus(missed)

    # Total: if net is negative, level doesn't count (must retry) → 0
    net = quiz_snow + bonus
    total = max(0, net)

    return LevelEconomy(
        level=level,
        customers=customers,
        profile=profile_name,
        served=served,
        avg_pay=avg_pay,
        money=money,
        quiz_snowflakes=quiz_snow,
        level_bonus=bonus,
        total_snowflakes=total,
        quizzes=quizzes,
        missed=missed,
    )


# ---------------------------------------------------------------------------
# Current level configurations (L1-30)
# ---------------------------------------------------------------------------

CURRENT_LEVELS = [
    {"level": 1,  "chairs": 1, "plates": 3, "customers": 2,  "frozen": 0},
    {"level": 2,  "chairs": 1, "plates": 3, "customers": 4,  "frozen": 1},
    {"level": 3,  "chairs": 1, "plates": 3, "customers": 3,  "frozen": 2},
    {"level": 4,  "chairs": 1, "plates": 3, "customers": 3,  "frozen": 1},
    {"level": 5,  "chairs": 1, "plates": 3, "customers": 3,  "frozen": 7},
    {"level": 6,  "chairs": 1, "plates": 2, "customers": 5,  "frozen": 1},
    {"level": 7,  "chairs": 1, "plates": 2, "customers": 5,  "frozen": 1},
    {"level": 8,  "chairs": 2, "plates": 2, "customers": 7,  "frozen": 1},
    {"level": 9,  "chairs": 2, "plates": 3, "customers": 7,  "frozen": 1},
    {"level": 10, "chairs": 2, "plates": 3, "customers": 7,  "frozen": 20},
    {"level": 11, "chairs": 2, "plates": 3, "customers": 10, "frozen": 8},
    {"level": 12, "chairs": 2, "plates": 3, "customers": 9,  "frozen": 1},
    {"level": 13, "chairs": 2, "plates": 3, "customers": 9,  "frozen": 8},
    {"level": 14, "chairs": 2, "plates": 3, "customers": 9,  "frozen": 1},
    {"level": 15, "chairs": 3, "plates": 3, "customers": 9,  "frozen": 32},
    {"level": 16, "chairs": 3, "plates": 3, "customers": 9,  "frozen": 1},
    {"level": 17, "chairs": 3, "plates": 3, "customers": 9,  "frozen": 10},
    {"level": 18, "chairs": 3, "plates": 3, "customers": 8,  "frozen": 1},
    {"level": 19, "chairs": 3, "plates": 2, "customers": 9,  "frozen": 1},
    {"level": 20, "chairs": 3, "plates": 3, "customers": 9,  "frozen": 42},
    {"level": 21, "chairs": 4, "plates": 3, "customers": 11, "frozen": 1},
    {"level": 22, "chairs": 4, "plates": 3, "customers": 10, "frozen": 1},
    {"level": 23, "chairs": 4, "plates": 3, "customers": 10, "frozen": 1},
    {"level": 24, "chairs": 4, "plates": 3, "customers": 10, "frozen": 1},
    {"level": 25, "chairs": 4, "plates": 3, "customers": 10, "frozen": 55},
    {"level": 26, "chairs": 4, "plates": 3, "customers": 10, "frozen": 12},
    {"level": 27, "chairs": 4, "plates": 3, "customers": 10, "frozen": 1},
    {"level": 28, "chairs": 4, "plates": 3, "customers": 10, "frozen": 15},
    {"level": 29, "chairs": 4, "plates": 3, "customers": 10, "frozen": 8},
    {"level": 30, "chairs": 5, "plates": 3, "customers": 11, "frozen": 75},
]

# Money spending milestones
MONEY_SPENDING = [
    {"level": 8,  "item": "2nd Chair",     "cost": 30},
    {"level": 9,  "item": "Extra Plate",   "cost": 15},
    {"level": 11, "item": "Knife",         "cost": 15},
    {"level": 13, "item": "Pot",           "cost": 28},
    {"level": 15, "item": "3rd Chair",     "cost": 58},
    {"level": 17, "item": "Mixer",         "cost": 25},
    {"level": 19, "item": "Dishwasher",    "cost": 42},
    {"level": 20, "item": "Peeler",        "cost": 22},
    {"level": 21, "item": "2nd Induction", "cost": 45},
    {"level": 22, "item": "4th Chair",     "cost": 68},
    {"level": 26, "item": "Toaster",       "cost": 32},
    {"level": 28, "item": "Wok + Gas",     "cost": 58},
    {"level": 29, "item": "Grater",        "cost": 28},
    {"level": 30, "item": "5th Chair",     "cost": 95},
]

# Snowflake spending milestones (tier/ingredient purchases only — unfreeze costs
# are read directly from CURRENT_LEVELS["frozen"] during projection)
SNOWFLAKE_PURCHASES = [
    {"level": 10, "item": "Tier 1",                          "cost": 12},
    {"level": 11, "item": "Produce (potato, onion, tomato)", "cost": 12},
    {"level": 16, "item": "Tier 2",                          "cost": 16},
    {"level": 16, "item": "Bakery (flour, milk, sugar)",     "cost": 15},
    {"level": 25, "item": "Tier 3",                          "cost": 22},
    {"level": 25, "item": "Protein (chicken, bacon)",        "cost": 12},
]


# ---------------------------------------------------------------------------
# Full economy projection
# ---------------------------------------------------------------------------

def run_economy_projection(profile_name: str = "average"):
    """Print full economy projection for a player profile across all levels."""
    profile = PROFILES[profile_name]
    cumul_money = 0
    cumul_snow = 0
    cumul_money_spent = 0
    cumul_snow_spent = 0

    print(f"\n{'='*80}")
    print(f"  Economy Projection: {profile.name} player")
    print(f"  Accuracy={profile.quiz_accuracy*100:.0f}%, Difficulty=+{profile.difficulty}, "
          f"Tip={profile.tip_rate*100:.0f}%, Miss={profile.missed_per_level}/level")
    print(f"{'='*80}\n")

    print(f"{'Lvl':>3} | {'Cust':>4} | {'Served':>6} | {'$/serve':>7} | {'Money':>5} | {'Cumul$':>6} | "
          f"{'Quiz':>4} | {'Bonus':>5} | {'Total':>5} | {'CumulSF':>7} | Notes")
    print("-" * 110)

    for lc in CURRENT_LEVELS:
        lvl = lc["level"]
        econ = calculate_economy(lvl, lc["customers"], profile_name=profile_name)
        cumul_money += econ.money

        # Unfreeze cost (paid BEFORE playing the level)
        frozen = lc.get("frozen", 0)
        notes = []
        if frozen > 0 and lvl > 1:
            cumul_snow_spent += frozen
            avail = cumul_snow - cumul_snow_spent
            status = "OK" if avail >= 0 else f"NEED {-avail}sf"
            notes.append(f"Unfreeze ({frozen}sf) → {avail}sf {status}")

        # Now earn snowflakes from playing
        cumul_snow += econ.total_snowflakes

        # Check money spending at this level
        for ms in MONEY_SPENDING:
            if ms["level"] == lvl:
                cumul_money_spent += ms["cost"]
                avail = cumul_money - cumul_money_spent
                status = "OK" if avail >= 0 else f"SAVE ${-avail}"
                notes.append(f"Buy {ms['item']} (${ms['cost']}) → ${avail} {status}")

        # Check snowflake purchases (tiers, ingredients) — bought AFTER playing
        for sp in SNOWFLAKE_PURCHASES:
            if sp["level"] == lvl:
                cumul_snow_spent += sp["cost"]
                avail = cumul_snow - cumul_snow_spent
                status = "OK" if avail >= 0 else f"NEED {-avail}sf"
                notes.append(f"{sp['item']} ({sp['cost']}sf) → {avail}sf {status}")

        prefix = "**" if frozen > 1 else "* " if frozen == 1 else "  "
        note_str = " | ".join(notes) if notes else ""

        print(f"{prefix}{lvl:>2} | {lc['customers']:>4} | {econ.served:>6.1f} | "
              f"${econ.avg_pay:>5.2f} | ${econ.money:>4} | ${cumul_money:>5} | "
              f"{econ.quiz_snowflakes:>4} | {econ.level_bonus:>5} | {econ.total_snowflakes:>5} | "
              f"{cumul_snow:>6} | {note_str}")

        # Band summary at every 10th level
        if lvl % 10 == 0:
            print(f"  {'─'*108}")
            band_start = lvl - 9
            print(f"  Band L{band_start}-{lvl}: money=${cumul_money} (spent ${cumul_money_spent}, "
                  f"balance ${cumul_money - cumul_money_spent}) | "
                  f"snow={cumul_snow} (spent {cumul_snow_spent}, "
                  f"balance {cumul_snow - cumul_snow_spent})")
            print(f"  {'─'*108}")

    print(f"\n  Total money: ${cumul_money}  (spent ${cumul_money_spent}, balance ${cumul_money - cumul_money_spent})")
    print(f"  Total snowflakes: {cumul_snow}  (spent {cumul_snow_spent}, balance {cumul_snow - cumul_snow_spent})")


# ---------------------------------------------------------------------------
# Single level analysis
# ---------------------------------------------------------------------------

def analyse_level(level: int, chairs: int, plates: int, recipe_names: list[str] | None = None,
                  customers: int | None = None):
    """Full analysis for a single level."""

    has_dw = level >= 19
    timing = calculate_timing(level, chairs, plates, recipe_names, customers, has_dishwasher=has_dw)

    print(f"\n{'='*70}")
    print(f"  Level {level} Analysis")
    print(f"{'='*70}\n")
    print(f"  Chairs: {chairs}  |  Plates: {plates}  |  Customers: {timing.customers}")
    print(f"  Recipes ({len(timing.recipes)}): {', '.join(timing.recipes)}")
    print()

    print("  TIMING MODEL")
    print(f"    Avg active time/customer:     {timing.avg_active:.1f}s")
    print(f"    Avg passive time/customer:    {timing.avg_passive:.1f}s")
    print(f"    Sequential time/customer:     {timing.avg_sequential:.1f}s")
    print(f"    Marginal time (with overlap): {timing.marginal_time:.1f}s")
    print(f"    Overhead factor ({chairs} chairs):    {overhead_factor(chairs)}")
    arr = "sequential" if timing.arrival_interval == 0 else f"{timing.arrival_interval:.0f}s"
    print(f"    Arrival interval:             {arr}")
    print(f"    Strong player duration:       {timing.strong_duration_min:.1f} min ({timing.strong_duration_s:.0f}s)")
    print()

    print("  ECONOMY PROJECTIONS")
    for pname in ["average", "slow", "strong"]:
        econ = calculate_economy(level, timing.customers, timing.recipes, pname)
        print(f"    {pname.capitalize():>8}: served {econ.served:.1f}/{timing.customers}, "
              f"${econ.money} earned, {econ.total_snowflakes}sf "
              f"(quiz={econ.quiz_snowflakes} + bonus={econ.level_bonus}, "
              f"missed={econ.missed:.1f})")
    print()

    # Achievability analysis
    pool = [RECIPE_BY_NAME[n] for n in timing.recipes if n in RECIPE_BY_NAME]
    post = post_active_time(level, has_dw)
    is_train = level <= 10

    print("  ACHIEVABILITY (bottleneck analysis)")
    a = analyse_achievability(pool, chairs, 1, post, is_train)
    print(f"    With {chairs} chairs, 1 cooking device:")
    print(f"      Throughput: {a.throughput_per_min:.1f} customers/min")
    print(f"      Max in 7min: {a.max_customers_in_7min}")
    print(f"      Bottleneck: {a.bottleneck}")
    print(f"      Avg cook time: {a.avg_cook_time:.1f}s")

    # Concurrency + patience
    avg_service = timing.avg_sequential
    interval = timing.arrival_interval
    conc = expected_concurrent(chairs, interval, avg_service)
    if pool:
        avg_base_wait = sum(
            r.cook_time + 13 * r.ingredients + 3 * r.steps + (5 if r.has_mixing else 0)
            for r in pool
        ) / len(pool) * 1.5
    else:
        avg_base_wait = 30
    patience, tip_window = calculate_patience(avg_base_wait, chairs, interval, avg_service)
    print(f"\n    Concurrency: {conc} (chairs={chairs}, interval={interval:.0f}s, service={avg_service:.0f}s)")
    print(f"    Patience: {patience:.0f}s (base {avg_base_wait:.0f}s × {1 + (conc-1)*0.2:.1f})")
    print(f"    Tip window: {tip_window:.0f}s")
    print()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Adorable Bites Level Calculator")
    parser.add_argument("level", nargs="?", type=int, help="Level number to analyse")
    parser.add_argument("--chairs", type=int, help="Number of chairs")
    parser.add_argument("--plates", type=int, help="Number of plates")
    parser.add_argument("--customers", type=int, help="Override customer count (otherwise computed)")
    parser.add_argument("--recipes", type=str, help="Comma-separated recipe names")
    parser.add_argument("--all", action="store_true", help="Show timing for all 30 levels")
    parser.add_argument("--economy", action="store_true", help="Full economy projection")
    parser.add_argument("--profile", type=str, default="average", choices=["average", "slow", "strong"])

    args = parser.parse_args()

    if args.economy:
        for p in ["average", "slow", "strong"]:
            run_economy_projection(p)
        return

    if args.all:
        print(f"\n{'Lvl':>3} | {'Ch':>2} | {'Pl':>2} | {'Cust':>4} | {'Active':>6} | {'Passive':>7} | "
              f"{'Seq':>5} | {'Marginal':>8} | {'Arrival':>7} | {'Duration':>8}")
        print("-" * 85)
        for lc in CURRENT_LEVELS:
            has_dw = lc["level"] >= 19
            t = calculate_timing(lc["level"], lc["chairs"], lc["plates"],
                                 customers=lc["customers"], has_dishwasher=has_dw)
            arr = "seq" if t.arrival_interval == 0 else f"{t.arrival_interval:.0f}s"
            frozen = "*" if lc.get("frozen", 0) > 0 else " "
            print(f"{frozen}{t.level:>2} | {t.chairs:>2} | {t.plates:>2} | {t.customers:>4} | "
                  f"{t.avg_active:>5.1f}s | {t.avg_passive:>6.1f}s | "
                  f"{t.avg_sequential:>4.1f}s | {t.marginal_time:>7.1f}s | "
                  f"{arr:>7} | {t.strong_duration_min:>5.1f} min")
        return

    if args.level is not None:
        recipe_names = [r.strip() for r in args.recipes.split(",")] if args.recipes else None

        # Default to existing config if level <= 30
        chairs = args.chairs
        plates = args.plates
        if args.level <= 30 and not chairs:
            lc = CURRENT_LEVELS[args.level - 1]
            chairs = lc["chairs"]
            plates = plates or lc["plates"]

        chairs = chairs or 4
        plates = plates or 3

        analyse_level(args.level, chairs, plates, recipe_names, args.customers)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
