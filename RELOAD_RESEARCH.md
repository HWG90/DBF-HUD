# Native reload state follow-up

The styling pass does not fabricate reload animation or progress.

Inspected the current ownership-checked reader and the existing separate Camera Research MDL watcher. The watcher can record changed ammo state/runtime records for 20 seconds using the ammo_reload_watch request. It is gated by the research module being enabled and HUD debug logging; it is not currently confirmed running, and its old log contains no AMMO_WATCH samples.

Verified reader semantics already used by the HUD:

* driver flag 0x40 becomes reloadable, a capability flag, not proof of an active reload.
* magazine ammo runtime byte +8 records a pending chamber stage. It is already used to avoid dropping the last magazine round while chambering.
* Autocannon runtime byte +16 marks the corresponding clip/chamber stage. It is weapon-specific.
* owned ammo state/runtime records can be captured without writing game memory.

These establish chamber stages but do not establish a universal reload-active flag or normalized progress field. No general reload fraction has been added.

Next live sample: the regular Machine Gun, once idle, one tactical reload, one empty reload, one interrupted reload, then a weapon swap. Record action timing alongside the bounded watcher so stage values can be labeled. Validate a candidate against idle and interrupted states and require ownership checks before exposing it to the HUD. A duration timer would be an animation estimate, not native progress, so it is not used as a substitute.
