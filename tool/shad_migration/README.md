# One-time migration audit utilities

`research_panels.dart` audits neutral research-panel Containers and applies only reviewed candidates. The 2026-10-03 applied positions are recorded in `outputs/design/reform/neutral-panels-applied.json`; state fills, diagram geometry and compact badges are excluded. New implementation should use the documented service composition directly.

These scripts were used during the 2026-10-03 Ant → shad transition. They are not the normal UI implementation workflow. Do not rerun blindly on an evolving working tree. `restore_input_labels.dart` consults git HEAD, which cannot recover uncommitted original decorations; review each resulting change. `direct_buttons.py` and `primitives.dart` transform constructor APIs and discard library-specific geometry, so business behavior/error/label/tooltip checks remain required. Current implementation rules live in docs/design-system/shad/agent-skill/SKILL.md.
