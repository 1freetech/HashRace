# Hash Race v0.092 quality pass

This focused maintenance pass keeps the v0.091 interaction and v0.090 strategy systems intact while improving control safety, route clarity, and field readability.

## Fixes

- Space no longer becomes a world interaction when a GUI control owns keyboard focus.
- Clicking normal ground replaces a queued entity interaction instead of leaving a stale target that can open later.
- Nearest-target selection now measures the same front-door interaction point used by range checks, avoiding wrong-target selection around large buildings.

## Gameplay and usability upgrades

- Escape cancels a queued interaction route immediately.
- A route that stops outside interaction range reports a clear recovery message instead of silently disappearing.
- Re-clicking the same distant target reports that routing is still active and explains how to cancel it.

## Readability cleanup

- The interaction prompt is visible only when an actionable target is actually within interaction range.
- Town banners are suppressed while a company interaction is selected because the dialog and building plate already identify the location.
- While auto-routing, only the destination building keeps its name plate, reducing competing labels.

## Additional polish

The turn-control tooltip now documents the unified keyboard model: Q previews a turn, Space interacts nearby, and Escape cancels a queued route or pending turn preview.

## Regression coverage

`tools/test_v092_quality_contract.py` protects the focused-input guard, stale-route replacement, front-door nearest-target geometry, Escape cancellation, stopped-route feedback, repeated-target feedback, prompt gating, town-label suppression, destination-only labels, and control tooltip.
