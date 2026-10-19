#!/usr/bin/env python3
"""Static contract for HashRace's evidence-backed whole-map visual-production law."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LAW = ROOT / "docs" / "HASHRACE_VISUAL_PLAYTEST_ASSET_LAW.md"
CAPTURE = ROOT / "Godot" / "scripts" / "capture_whole_map.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "smoke-test.yml"
HOURLY_WORKFLOW = ROOT / ".github" / "workflows" / "hourly-whole-map-proof.yml"


def require(text: str, markers: list[str], label: str) -> None:
    for marker in markers:
        assert marker in text, f"{label} missing: {marker}"


def main() -> None:
    assert LAW.is_file(), "whole-map visual-playtest law is missing"
    assert CAPTURE.is_file(), "whole-map capture script is missing"
    law = LAW.read_text(encoding="utf-8")
    capture = CAPTURE.read_text(encoding="utf-8")
    workflow = WORKFLOW.read_text(encoding="utf-8")
    assert HOURLY_WORKFLOW.is_file(), "hourly whole-map proof workflow is missing"
    hourly = HOURLY_WORKFLOW.read_text(encoding="utf-8")

    require(
        law,
        [
            "Focused Vertical Slice",
            "whole-map proof",
            "added, reused, repositioned, reduced, or removed",
            "Asset and Sprite-Sheet Rules",
            "Character Rule",
            "Hourly Production Cycle",
            "Standing Authorization",
        ],
        "Visual production law",
    )
    require(
        capture,
        [
            'OUTPUT_PATH := "res://../visual-proof/hashrace-whole-map.png"',
            "PLAYABLE_WORLD_SIZE := Vector2(3000.0, 1900.0)",
            "camera.position = PLAYABLE_WORLD_SIZE * 0.5",
            "camera.zoom = Vector2.ONE * fit_zoom",
            "HASH RACE WHOLE MAP PROOF PASS",
            "HASH RACE WHOLE MAP PROOF FAIL",
        ],
        "Whole-map capture",
    )
    require(
        workflow,
        [
            "Capture whole playable world map",
            "capture_whole_map.gd",
            "hashrace-whole-map.png",
            "hashrace-whole-map-proof",
            "test_visual_playtest_asset_law.py",
        ],
        "CI visual-playtest gate",
    )
    require(
        hourly,
        [
            'cron: "0 * * * *"',
            "ref: main",
            "capture_whole_map.gd",
            "hashrace-hourly-whole-map-proof",
        ],
        "Hourly whole-map proof gate",
    )
    print("HashRace whole-map visual playtest law contract passed.")


if __name__ == "__main__":
    main()
