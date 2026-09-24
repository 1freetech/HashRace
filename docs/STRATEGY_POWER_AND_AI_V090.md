# Hash Race v0.090 — Strategy, Power Dispatch, and Rival Intent

## Why these changes exist

v0.090 only adopts mechanics that change decisions or improve simulation correctness. It does not add strategy-themed decoration or extra permanent HUD text.

The power model is conceptually informed by the uploaded **Power System Sample** by Luiz Fernando Silva (2026), distributed under the MIT License. Hash Race adapts the reusable idea of separating generation, storage, and consumption into an original data-oriented Godot implementation; no sample artwork, scenes, or game-specific assets are copied.

## Finite energy storage

A deployed Grid Battery Container is now a real finite storage asset instead of a passive uptime percentage. One unit provides **4 MWh** of storage, **2 MW** of charge/discharge power, and **90% round-trip efficiency**.

The dispatcher serves critical site controls first and mining load second. Surplus generation charges storage. During a shortage, stored energy can cover critical load and then mining load subject to power limits, state of charge, efficiency losses, and the player's reserve target.

The strategic turn preview uses the same finite MWh budget across the selected turn duration. A four-MWh battery therefore cannot mathematically behave like an unlimited generator during a month or year turn. Charging input is included in source-energy cost so storage cannot create free energy through accounting.

## Battery reserve policy: 0–100

The Energy menu exposes a direct **0–100 battery reserve target**. Lower reserve prioritizes present hashrate; higher reserve protects stored energy for critical operations and future shortages.

## Visible rival intent and utility AI

Each mining rival scores five strategic actions: fleet expansion, ASIC research, power buildout, land banking, and cash defense. Scores use live 0–100 culture ratings plus cash reserve, power headroom, and site density.

The selected action becomes the rival's **next intent** and is shown when the player inspects or talks to that rival. The intent executes on the next monthly AI cycle, after which a new intent is calculated.

## Native route solving

The overworld's primary route solver now uses Godot's native AStarGrid2D with four-direction movement and a Manhattan heuristic. Hash Race keeps its bounded local scanner search for reachable-cell visualization, but normal point-to-point routes no longer run the previous linear-scan GDScript A* loop.
