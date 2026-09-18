from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

scene_script = (ROOT / "Godot/scripts/negotiation_scene.gd").read_text()
manager = (ROOT / "Godot/systems/negotiation_manager.gd").read_text()
world = (ROOT / "Godot/scripts/world_v072.gd").read_text()
computer_offer_world = (ROOT / "Godot/scripts/world_v086.gd").read_text()
world_scene = (ROOT / "Godot/scenes/world.tscn").read_text()
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
    "_walk_away",
    "negotiation_finished",
    "player_reputation",
    "opponent_greed",
    "reward_machines",
    "reward_efficiency_bonus",
    "deal_type",
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
], "v0.072 rival negotiation integration")

require(computer_offer_world, [
    'extends "res://scripts/world_v085.gd"',
    "COMPUTER_DEAL_COMPANIES",
    "COMPUTER_OFFER_INITIAL_MIN_SECONDS",
    "COMPUTER_OFFER_REPEAT_MIN_SECONDS",
    "func _launch_computer_company_offer",
    '"deal_type":"computer_supply"',
    '"source_kind":"computer_company"',
    '"reward_machines":reward_machines',
    '"reward_efficiency_bonus":efficiency_bonus',
    "func debug_computer_offer_ready",
], "v0.086 computer-company offer integration")

require(scene, [
    '[node name="NegotiationScene" type="CanvasLayer"]',
    '[node name="IntroAnimation" type="AnimationPlayer"',
    "MakeOfferButton",
    "CounterOfferButton",
    "WalkAwayButton",
], "Negotiation scene tree")

assert "_threaten" not in scene_script, "Threaten action must stay removed from negotiation controller"
assert "ThreatenButton" not in scene, "Threaten button must stay removed from negotiation scene"
assert "THREATEN" not in scene, "Threaten label must stay removed from negotiation scene"

assert "world_v090.gd" in world_scene, "Live world must boot through the current v0.090 layer"
assert re.fullmatch(r"v0\.\d{3}", version), version
assert int(version.split(".")[1]) >= 86, f"computer offers require v0.086+, got {version}"
print("Negotiation contract PASS")
