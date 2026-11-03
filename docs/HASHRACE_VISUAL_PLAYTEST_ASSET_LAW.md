# HashRace Whole-Map Visual Playtest and Asset Integration Law

**Status:** Binding project law  
**Applies to:** Every HashRace visual, gameplay, map, character, UI, infrastructure, asset, and release change.

## 1. Outcome

HashRace must become a coherent, aesthetically pleasing 2D overhead Bitcoin-mining strategy game. A passing parser, a static test, source art, or an isolated demo scene does not prove that outcome. The active campaign must visibly read as a playable industrial mining world with a clear hierarchy:

1. player and meaningful interaction;
2. generation, transformer/distribution, cooling, and mining load;
3. facilities and service spaces;
4. paths, terrain, water, and sparse environmental detail.

Preserve the mining/strategy identity, the complete playable campaign chain, and all working systems. Do not replace the game with a visual-only proof scene.

## 2. Focused Vertical Slice

A focused vertical slice is one complete, polished section of the real game: one campus district with a legible goal, player movement, collision, at least one useful interaction, a readable interface, coherent infrastructure, and a short satisfying decision loop. It is the quality bar for the rest of the map.

Each visual pass must improve a real vertical slice before expanding the number of locations or features. A new object belongs only when it improves gameplay readability, an interaction, campus hierarchy, or the player’s sense of place.

## 3. Mandatory Visual Evidence

Every change run must obtain fresh evidence from the exact proposed source head after a fresh Godot import:

- **whole-map proof:** `hashrace-whole-map.png`, captured with the live camera zoomed to include the entire 3000 × 1900 playable world;
- **gameplay proof:** the normal live-world screenshot with the player, actual HUD, and real game state;
- **changed-area proof:** a close framing when the change affects a character, object, interaction, or UI;
- **motion/interaction proof:** when a change affects movement, collision, navigation, deployment, or a playable action.

The whole-map proof is mandatory on every GitHub Actions run. It is a compositional review, not merely a file-existence check.

## 4. Whole-Map Review Checklist

Before making a change and after the proof is rendered, inspect the entire map and record the decision in the pull request or an hourly visual audit. Evaluate:

- empty space, crowding, repeated buildings, detached shadows, visual noise, and unintended grids;
- player scale, sprite ground contact, Y-sort, collision footprint, and readable movement routes;
- whether service roads connect useful places without overpowering the terrain;
- clear separation between generation, distribution, cooling, containers/data centers, and mining load;
- water/terrain edges, building boundaries, out-of-bounds placement, and object overlap;
- UI obstruction, labels, nearest-target feedback, and whether the player can understand the next action;
- what should be **added, reused, repositioned, reduced, or removed**.

Prefer removing or relocating an awkward, duplicated, nonfunctional, or visually misleading element over adding filler.

## 5. Asset and Sprite-Sheet Rules

The Library and repository sprite sheets are active production sources. Audit them before creating a duplicate.

- Reuse a valid relevant Library/repository asset when it improves the real map.
- Build new sheets only when the needed role is absent or a coherent character/object family requires it.
- An integrated asset must be a valid transparent or intentionally cleaned source image; use nearest-neighbor scaling, pixel alignment, realistic relative scale, a grounded footprint, correct Y-sort, collision where required, and no duplicate live object.
- Crop/slice a sheet deliberately. Do not treat labels, panels, white/gray staging backgrounds, or concept-poster text as in-game pixels.
- An asset is **not integrated** until a fresh live campaign render shows it at the intended scale and location, with the matching collision/interaction behavior where applicable.
- Preserve the full gameplay chain and existing working assets. Archive rejected sources rather than replacing working gameplay with a demo.

Current audit candidates include the industrial generator/safety/cable sheet, directional cooling-container sheet, and industrial colony facility sheet. Use them deliberately; do not force all of them into one campus.

## 6. Character Rule

New characters must be actual readable game sprites, not palette-only stand-ins or decorative concept sheets.

- Give each new named NPC a distinct silhouette, skin/hair/clothing palette, role, and clear four-direction idle/walk contract.
- Keep character size visibly smaller than buildings and matched to the player’s grounded foot line.
- Use transparent frames or clean them before slicing; no full-sheet background, labels, or border pixels may render in the world.
- Prove the new character in the live campaign with motion, facing, ground contact, and interaction evidence before merge.

## 7. Required Quality Gates

A visual/gameplay change may merge only after all applicable gates pass on the exact source head:

1. fresh Godot import and script-error gate;
2. current campaign boot and playable-world validation;
3. whole-map proof plus normal gameplay proof;
4. relevant close-up, motion, deployment, collision, or UI proof;
5. existing language/test suite and any new targeted test;
6. direct visual inspection of the artifacts.

Static scripts cannot prove beauty, playability, or genuine rendering by themselves. Do not claim a change is complete without the fresh evidence.

## 8. Hourly Production Cycle

At the start of every hourly HashRace cycle:

1. inspect the latest whole-map and gameplay proof;
2. audit available Library/repository sheets and the live map;
3. choose one coherent high-value improvement or a documented removal/repositioning;
4. implement it in the real campaign, using or building a valid sprite sheet when appropriate;
5. create fresh whole-map and changed-area proof, run exact-head validation, and write the audit/change to GitHub;
6. merge only green, evidence-backed work.

Do not create fake activity commits. If the evidence shows no safe improvement for that cycle, record the specific next visual gap rather than degrading the game with filler.

## 9. Standing Authorization

The project owner authorizes HashRace-scoped repository writes, sprite integration, generated asset creation, branch/PR work, and recurring visual audits. This authorization remains within the project’s existing safety and platform constraints.
