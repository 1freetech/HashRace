# Hash Race engine direction

Hash Race is moving to **Godot 4.7.2 stable** as the primary open-source game engine while preserving useful simulation logic from the existing C# prototype.

## Corrected company model

Every playable and rival company is a **Bitcoin mining company**. AI, robotics, semiconductor, energy, telecom, infrastructure, real-estate, finance, food/retail, and sports organizations are external NPC partners, suppliers, sponsors, or strategic allies. They do not compete in the Bitcoin mining league unless a future story event explicitly creates a mining subsidiary.

## Engine and language choice

Godot is free and open source under the MIT license, has dedicated 2D and 3D workflows, and exports to major desktop, mobile, and web targets. Godot officially supports GDScript, C#, and C++ through GDExtension, and its documentation explicitly supports mixing languages inside one project.

Hash Race therefore uses:

- **Godot 4.7.2** for the primary game client, scenes, UI, maps, animation, input, and future mobile work.
- **GDScript** for fast gameplay iteration, facility systems, seasons, events, standings, partnership logic, and franchise-mode features.
- **C#** where the already-working mining simulation or desktop prototype saves development time.
- **C++ via GDExtension** only for measured performance bottlenecks or specialized simulation systems that actually benefit from native code.

This is a migration, not a rewrite-for-the-sake-of-rewriting. Working C# logic remains useful until a Godot equivalent is tested and clearly better.

## Sources

- Godot source repository and MIT license: https://github.com/godotengine/godot
- Godot official release archive: https://godotengine.org/download/archive/
- Godot scripting-language guide: https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html
- GDScript reference: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- Godot design philosophy: https://docs.godotengine.org/en/stable/getting_started/introduction/godot_design_philosophy.html
- Academic paper on Godot's relevance in indie development: https://arxiv.org/abs/2401.01909
- 2026 JamSet/JamBench research using 8,133 verified Godot projects: https://arxiv.org/abs/2606.19830

## Evidence note

Godot is clearly a major open-source game engine, but the repo should not claim that it is definitively the single "most cited" engine in academia unless a reproducible bibliometric source establishes that ranking. The stronger, verifiable case is that Godot is MIT-licensed, widely used, actively maintained, supports Hash Race's 2D-first design, and appears in contemporary academic game-engine research.
