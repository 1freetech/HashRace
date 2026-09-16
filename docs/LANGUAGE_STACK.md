# Hash Race language stack research

Updated September 15, 2026.

There is no single universal ranking of "open-source game languages." This list combines direct game-development survey data with broader open-source/GitHub adoption and Godot compatibility. The first six are directly ordered by JetBrains' 2025 game-development survey. The final four are added from game-web, Godot, and broader developer data because the JetBrains public page truncates the lower part of its language chart.

## Practical top 10

1. **C#** — 40% of surveyed game developers reported using it in the prior 12 months. Hash Race already uses C# for the transitional desktop build.
2. **C++** — 29% in the same game-development survey. It is also an officially supported Godot language through GDExtension.
3. **Python** — 19% in the game-development survey. Hash Race already uses Python for smoke and contract tests.
4. **JavaScript** — 17% in the game-development survey and 64.7% in the web-game-focused Gamedev.js 2025 survey.
5. **Java** — 14% in the game-development survey.
6. **TypeScript** — 10% in the game-development survey, 47.5% in the web-game-focused Gamedev.js survey, and GitHub reported TypeScript became its most-used language in August 2025.
7. **Lua** — 9.7% in the Gamedev.js 2025 survey and long established as an embedded game scripting language.
8. **GDScript** — Godot's native gameplay language. Hash Race already uses it as the primary Godot gameplay/UI language.
9. **Rust** — 3.9% in the Gamedev.js 2025 survey; it also has an active open-source Godot 4 GDExtension binding focused on native performance and safety.
10. **C** — still widely used in systems and engine work; the 2025 Stack Overflow-derived global language data reported 22% usage among developers, although the direct game survey's public chart does not expose a C percentage.

## Best three additions for Hash Race

### 1. C++ — native mining/economy core

C++ is the strongest new runtime-oriented addition because Godot officially supports it through GDExtension and describes it as the best choice when native performance is needed. Hash Race now contains `native/cpp/hashrace_core.cpp`, a dependency-free reference core for power, electricity-price, BTC/day, power-cost, and daily-profit calculations. It is compiled and executed in CI. This gives the project a tested native math path without forcing the current Godot prototype to depend on a native library before profiling proves that is necessary.

### 2. Rust — deterministic balance simulation

Rust is a strong fit for offline balance simulation because Hash Race has long-running seasons, compounding economics, rival growth, and many future scenarios that need repeatable testing. `native/rust/hashrace_balance.rs` implements the mining math and a deterministic one-year balance probe with unit tests. CI compiles the tests and the executable. Rust can later move closer to Godot through the community `godot-rust` GDExtension binding if the project needs that path.

### 3. TypeScript — content and rule validation

TypeScript is useful without complicating the Godot runtime. `tools/typescript/hashrace_validate.ts` checks the canonical game contract: ten Bitcoin mining competitors and ten outside NPC partner sectors. This protects the corrected Hash Race concept while providing a typed tooling path for future data files, web dashboards, mod/content pipelines, and browser-facing companion tools.

## Why the other popular choices were not added now

JavaScript overlaps TypeScript but gives up static checking. Java is popular but does not fit the Godot architecture as directly. Lua is excellent for embedded scripting, but GDScript already fills Hash Race's fast gameplay-scripting role. C is useful at the lowest level, but C++ gives Hash Race the same native-performance lane with much better direct Godot support.

## Sources

- JetBrains, *The State of Game Development 2025*: https://lp.jetbrains.com/the-state-of-gamedev-2025/
- Gamedev.js, *Gamedev.js Survey 2025 Report*: https://gamedevjs.com/dl/gamedevjs-survey-2025-report.pdf
- GitHub Octoverse 2025, TypeScript becoming the most-used language on GitHub: https://github.blog/news-insights/octoverse/what-the-fastest-growing-tools-reveal-about-how-software-is-being-built/
- Godot documentation, scripting languages and mixed-language support: https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html
- Godot documentation, community-supported languages: https://docs.godotengine.org/en/stable/tutorials/scripting/other_languages.html
- godot-rust documentation: https://godot-rust.github.io/docs/gdext/
- Stack Overflow 2025 language data: https://survey.stackoverflow.co/2025/technology/
