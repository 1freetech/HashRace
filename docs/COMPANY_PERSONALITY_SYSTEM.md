# Dynamic Company Personality System

Hash Race companies are fictional Bitcoin miners. Each miner starts with a company history, a past controversy, a strategic posture, and seven ratings on the game's universal 0–100 scale.

The ratings are **Aggression, Risk, Growth, R&D, Treasury, Operations, and Reputation**. Aggression and Risk produce the current Aggressive, Moderate, or Conservative posture. The posture is descriptive, not a permanent class.

## Ratings change over time

Player ratings move from actual player decisions. Buying ASICs, adding MW, buying land, changing the BTC hold policy, taking or repaying debt, advancing chip research, signing partnerships, operating profitably, and recovering from losses can all change the company culture.

Rival ratings move from performance and AI decisions. Roughly once per in-game month, each rival weighs fleet expansion, R&D, infrastructure, and cash discipline. The live ratings influence which strategy it chooses. Rivals can also sign partnerships that fit their company history.

The system uses elapsed time instead of button presses. A one-day turn therefore produces much less company development than a one-month or one-quarter turn.

## Ratings now affect gameplay

Version v0.021 closes the gap between personality text and gameplay. The player's current ratings now create bounded economic effects:

- **Operations** changes effective mining uptime by up to about ±1.2 percentage points.
- **Treasury + Reputation** change borrowing rates by up to about ±1.25 percentage points.
- **Reputation** changes partnership costs within a 0.88×–1.12× range.
- **R&D + Operations** change chip-research costs within a 0.88×–1.12× range.
- **Growth + Operations** improve expansion execution, while very high Aggression + Risk can add a rush premium. Expansion costs stay within a 0.90×–1.12× range.
- **Aggression + Reputation** change merger negotiation costs within a 0.92×–1.08× range.
- **Aggression + Risk** already increase controversy exposure, so fast growth has a real downside as well as potential upside.

These modifiers are deliberately small. Ratings are intended to shape strategy, not override player decisions or make a strong starting company automatically win.

## Controversies

Controversies are dynamic. Higher Aggression and Risk increase the chance of permitting, financing, deployment, or local power-use disputes. Controversies can reduce cash and reputation, while the aftermath may increase Operations or Treasury discipline.

Every company also has a fictional founding controversy tied to its original history. These histories are inspired by common real-world business problems without copying a specific real company.

## Player visibility

The campaign setup screen shows each company's history, founding controversy, starting posture, strengths, and all seven ratings.

During play, the company HQ shows the current posture, ratings, latest action, recent controversy, and a summary of live gameplay modifiers. ASIC, power, land, bank, partnership, R&D, and merger interactions use the adjusted values so the player can see the ratings matter.

Runtime validation checks that all ratings remain inside 0–100, every rival has personality state, gameplay modifiers stay inside their balance limits, and at least one modifier is materially active for the test company.
