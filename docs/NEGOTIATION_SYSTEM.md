# Hash Race Negotiation Scene System

Hash Race v0.072 adds a reusable Godot 4 negotiation layer for face-to-face business encounters in the mining economy.

## Runtime flow

1. A rival company or representative exposes **NEGOTIATE ACCESS DEAL**.
2. `world_v072.gd` builds context from the live company personalities, including reputation, leverage, rival power, greed, cash, and tech level.
3. `NegotiationManager` instantiates `NegotiationScene.tscn` above the world as a high-layer `CanvasLayer`.
4. The scene plays a fast battle-style intro, then presents three actions: **MAKE OFFER**, **COUNTER**, and **WALK AWAY**.
5. The scene emits a structured result. The world applies the economic result only after a deal is closed.

The first live deal type is a small flexible-power access contract. A successful agreement transfers cash from the player to the rival and adds the negotiated MW capacity to the player.

## Architecture

- `Godot/scenes/NegotiationScene.tscn` — original Hash Race negotiation UI and battle-style layout.
- `Godot/scripts/negotiation_scene.gd` — intro animation, offers, counteroffers, walk-away path, result state, and debug hooks.
- `Godot/systems/negotiation_manager.gd` — lifecycle manager that launches one negotiation at a time and forwards results.
- `Godot/scripts/world_v072.gd` — converts live rival/company state into negotiation context and applies successful deals.
- `Godot/scripts/validate_negotiation_scene.gd` — headless runtime validation.
- `Godot/scripts/capture_negotiation_scene.gd` — CI-rendered PNG proof.

The scene accepts a context dictionary, so later deal types can reuse the same presentation for mergers, supplier contracts, power PPAs, land purchases, financing, semiconductor supply, faction reputation, and item-based bargaining without duplicating the UI.
