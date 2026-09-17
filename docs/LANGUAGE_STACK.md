# Hash Race language stack

Updated September 17, 2026.

Hash Race is a Godot game with a deliberately mixed language stack. The goal is not to add languages for their own sake. Each language has a specific job, and simulation-heavy code should increasingly move into C++ when that gives the project a clearer typed data model, better performance headroom, or a better path for large inventories and long-running calculations.

## Runtime direction

### GDScript — presentation and gameplay orchestration

GDScript remains the primary live Godot layer. It owns scenes, map behavior, character movement, UI, interaction flow, visual presentation, and fast gameplay iteration.

### C++20 — simulation, inventory and high-volume state

C++ is now the preferred growth path for data-heavy Hash Race systems. `native/cpp/` contains a dependency-free simulation core that is compiled and executed in CI.

The current C++ layer includes:

- mining power, BTC/day, electricity cost, and profit math
- machine-generation catalog data
- machine cooling compatibility for air, hydro, and immersion
- fleet inventory by generation, cooling type, count, condition, and utilization
- company profiles and 0–100 strategy settings
- real-unit state for cash, BTC, MW, TH/s, J/TH, research, and acquisitions
- market state for BTC price, network hash rate, subsidy, and power price
- rival-company state and valuation
- daily mining ledger and BTC hold/sell behavior
- machine purchases and site-capacity checks
- R&D and generation unlocks
- partnerships, site expansion, acquisitions, league rank, and season progression

The C++ layer intentionally keeps real measurements in real units. MW, TH/s, BTC, dollars, J/TH, machine counts, and similar physical/economic values are not converted into arbitrary 0–100 ratings. Strategy and qualitative ratings continue to use the universal 0–100 scale.

The project should grow C++ from a very small share toward roughly 10–15% of the codebase only as simulation complexity justifies it. The percentage is a direction, not a quota. New C++ should replace duplicated or computation-heavy logic rather than add parallel implementations that are never used.

A later step can expose this native core to Godot through GDExtension. Keeping the simulation dependency-free first makes it easy to test, profile, and evolve without forcing every Godot build to compile a native extension immediately.

### C# — shrinking legacy prototype code

The large Unity simulation prototype and old standalone C# desktop simulation copies have been removed after their useful data structures and simulation concepts were moved into the C++ core. A small amount of legacy Unity/editor C# may remain temporarily as migration reference material.

New simulation systems should not be added to the retired C# prototype path.

### Rust — deterministic balance experiments

Rust remains useful for deterministic balance probes and isolated simulation experiments. `native/rust/hashrace_balance.rs` is compiled and tested in CI. Rust is not the primary runtime migration target at this stage because C++ has the most direct path into Godot through GDExtension and now owns the typed native simulation model.

### TypeScript — content and rule validation

TypeScript is used for typed validation tooling, content contracts, and potential future web-facing or data-pipeline work. It is not part of the live Godot runtime.

### Python — smoke and contract tests

Python remains useful for repository-level smoke tests and gameplay contract checks. It provides fast validation without competing with the runtime simulation layer.

## Migration rules

Move a system toward C++ when one or more of these are true:

1. It processes large collections of machines, companies, transactions, market records, inventory items, or historical simulation state.
2. It performs the same numeric calculations many times per turn, day, season, AI company, or scenario.
3. It benefits from strict typed structures and explicit ownership of data.
4. It is duplicated in legacy C# or multiple scripts and can become one canonical implementation.
5. Profiling shows the Godot scripting layer is spending meaningful time in the calculation.

Keep a system in GDScript when its main job is scene control, UI, drawing, input, dialogue, map interaction, or other high-iteration gameplay presentation work.

## CI gate

The C++ core is compiled with:

`g++ -std=c++20 -O2 -Wall -Wextra -Werror -pedantic`

The native executable then checks mining math, inventory aggregation, cooling, strategy bounds, purchases, research unlocks, BTC treasury behavior, and season advancement. This keeps the C++ migration measurable and prevents the native layer from becoming untested repository decoration.

## External references

- JetBrains, *The State of Game Development 2025*: https://lp.jetbrains.com/the-state-of-gamedev-2025/
- Godot documentation, scripting languages: https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html
- Godot documentation, GDExtension and native extensions: https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html
- Godot C++ bindings: https://github.com/godotengine/godot-cpp
