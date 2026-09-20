from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_v111_interaction_machine_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.111"

    interaction = (ROOT / "Godot/components/interaction/hashrace_interaction_area.gd").read_text()
    assert "var _candidates: Array[Node2D] = []" in interaction
    assert "body in _candidates" in interaction
    assert "_candidates.erase(body)" in interaction
    assert "_candidate = _candidates.front() if not _candidates.is_empty() else null" in interaction
    assert "actor not in _candidates" in interaction
    assert "_candidates.clear()" in interaction
    assert "maxf(reset_delay, 0.0)" in interaction

    machine = (ROOT / "Godot/components/state_machine/machine_state_controller.gd").read_text()
    assert 'const CRITICAL := &"critical"' in machine
    assert "safe_load := maxf(load_mw, 0.0)" in machine
    assert "safe_available := maxf(available_mw, 0.0)" in machine
    assert "safe_uptime := clampf(uptime, 0.0, 1.0)" in machine
    assert "warning_threshold := minf(heat_warning_c, heat_critical_c)" in machine
    assert "critical_threshold := maxf(heat_warning_c, heat_critical_c)" in machine
    assert "next = CRITICAL" in machine
    assert 'return Color("ff3b30")' in machine


if __name__ == "__main__":
    test_v111_interaction_machine_contract()
    print("v0.111 interaction/machine contract: PASS")
