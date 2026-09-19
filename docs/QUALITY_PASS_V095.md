# Hash Race v0.095 Quality Pass

This pass follows v0.094's world-first interface cleanup and focuses on responsiveness, readability, and low-risk input polish.

## Fixes
- Navigation now stays within narrow/short viewports instead of assuming the full desktop canvas.
- Identical feedback arriving through converging parent paths is suppressed for 500 ms, preventing visible double-toasts.
- Escape now has predictable hierarchy: close NAV first, then return any open workspace to the clean world view.

## Gameplay / usability upgrades
- Direct keyboard access: `O` Mining Ops, `C` Company, `B` Market, `I` Infrastructure, `T` BTC Treasury, `L` League.
- Opening NAV moves keyboard focus to the first navigation choice for immediate keyboard operation.
- The NAV tooltip exposes the shortcut map without adding permanent HUD text.

## Readability / order cleanup
- The currently open non-world workspace is disabled in NAV, clarifying state and preventing redundant reopen clicks.
- NAV width is clamped to a compact 236–288 px range and anchored with consistent margins.
- Escape provides a single, consistent way to collapse interface clutter back to the world.

## Additional high-impact improvement
- Workspace state and navigation focus are now explicit and regression-testable through `debug_v095_quality_ready()` and `tools/test_v095_quality_contract.py`.
