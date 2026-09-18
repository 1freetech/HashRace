from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

scene_script = (ROOT / "Godot/scripts/negotiation_scene.gd").read_text()
manager = (ROOT / "Godot/systems/negotiation_manager.gd").read_text()
world = (ROOT / "Godot/scripts/world_v072.gd").read_text()
scene = (ROOT / "Godot/scenes/NegotiationScene.tscn").read_text()
version = (ROOT / "VERSION").read_text().strip()

def require(text: str, tokens: list[str], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    assert not missing, f"{label} missing: {missing}"

require(scene_script, [
    "class_name HashRaceNegotiationScene",
    "AnimationPlayer",
    "_make_offer",
    "_counter_offer",
    "_threaten",
    "_walk_away",
    "negotiation_finished",
    "player_reputation",
    "opponent_greed",
    "debug_snapshot",
], "Negotiation scene controller")

require(manager, [
    "class_name HashRaceNegotiationManager",
    "NegotiationScene.tscn",
    "negotiation_resolved",
    "func launch",
], "Negotiation manager")

require(world, [
    'extends "res://scripts/world_v070.gd"',
    "NEGOTIATE ACCESS DEAL",
    "func start_negotiation",
    "debug_negotiation_ready",
    "debug_v072_ready",
    "reward_capacity_mw",
], "v0.072 world integration")

require(scene, [
    '[node name="NegotiationScene" type="CanvasLayer"]',
    '[node name="IntroAnimation" type="AnimationPlayer"',
    "MakeOfferButton",
    "CounterOfferButton",
    "ThreatenButton",
    "WalkAwayButton",
], "Negotiation scene tree")

assert version == "v0.072", f"expected v0.072, got {version}"
print("Negotiation contract PASS")
