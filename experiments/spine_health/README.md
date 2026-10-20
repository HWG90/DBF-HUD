# Spine health experiment

Optional standalone add-on, NOT part of DBF or DBF-HUD's normal build. Its only runtime imports are the four Lua files in its own folder. MCM's public parent_name grouping adds an Experiments tab under Diver's Best Friend; no core mod or MCM file is modified. Without that parent it remains a separate MCM entry. Disable this add-on in LLL, then delete Mods/dbf_spine_health to remove it; a restart also safely completes removal. DBF, DBF-HUD and MCM remain independent. A saved settings entry may remain inert.

Candidate.5 defaults the spine bar Off using a fresh spine_enabled setting, so the old prototype's saved Enabled value cannot opt users in. The tab explicitly says these are unsupported things the author is trying or toying around with. Bone/health/render adapters initialize only after opt-in; the default-Off path performs no player/bone/health reads and creates no rendering resources.

Candidate.4 extends the bar 50 percent beyond the original length (20 percent beyond candidate.3), retaining the lower anchor, eight segments and existing width. No extra bone reads or render primitives.

Standalone LLL candidate maintained in canonical DBF-HUD. Not added to the weapon HUD build order. Existing unrelated texture edits are outside this experiment. Build output is dist/spine-health-<manifest version>; each deployed candidate has installed hashes and a deployment/rollback receipt.

The recorded player rig in DBF_PhotoMode/freecam/assets/subject_pose_frames.lua names spine1, spine2 and chest. Those are scene nodes, not interchangeable with animation bone indices. Resolve by name on each new validated avatar identity; never hard-code the recorded indices.

Eight cyan segments run from the lower spine to chest, with partial segment fill, amber at half health and red at quarter health. Candidate.1's per-bone forward offsets produced the diagonal cyan zipper observed by the user. Candidate.2 derives a common anatomical frame from five spine/clavicle positions and applies the SAME rear normal to every spine anchor. Root facing chooses its sign. A 48 mm housing width surrounds a narrower cyan channel, with metal vertebra plates and a connecting dark rail.

backend.lua implements the build-fingerprinted, read-only player/Unit layout from Photo Mode subject_backend.lua and same-owner health layout from Temporary Unlocks src/freezes.lua. It obtains a genuine engine Unit handle through one World.units enumeration per avatar identity, caches five named nodes on the 107-node rig, and reads five bone positions plus root facing per visible update. There are no gameplay writes, invented native handles, detours, code patches, or page-protection changes.

renderer.lua retains eight GUIs. Changed poses move; health/color changes update bitmap fill. Unchanged state does neither. Main runs through LLL's existing update callback. Disabled state does no avatar/health/render work. LLL's public API has no avatar subscription, so absence/death/active first-person ADS uses bounded 4 Hz reacquisition. The saved FP preference alone does not hide the bar. Unexpected validation errors latch until re-enabled. Cleanup discards retired-world handles without native calls into them.

MCM > Spine Health (Experiment) exposes Enabled and Distance behind spine. Callbacks queue changes for the owning update. Material selection prefers an already-loaded depth_fill, otherwise content/ui/shared/material/gui_fill. The actual material is logged. Fallback depth behavior remains unverified.

DBF-HUD/src/world_probe.lua demonstrates engine world GUI placement, and src/retained_carrier.lua demonstrates retained geometry lifecycle. Neither proves this bar renders correctly. Depth-aware material availability, winding, glow, bone basis direction and cape/backpack occlusion need live validation. A depth-tested bar may be entirely hidden by a cape/backpack; showing through them would require an explicit visual design choice.

Run verify.py using Python with lupa.luajit21, then build.py. Offline checks cover geometry, invalid data, stale health ownership, avatar replacement, death, active first-person ADS, retained-resource reuse, unchanged-state idle, retired-world cleanup, common anatomical offsets, turning and prone orientation.

Candidate.1 live evidence: LLL loaded and submitted eight segments with one enumeration and eight initial ink updates. The first coarse 600-frame CPU sample averaged 0.2233 ms, maximum 2 ms. Loader startup reported 10 ms/about 9 MB, including one-time world enumeration and module initialization. Candidate.2 uses QueryPerformanceCounter elapsed timing for the first 600 updates and then stops instrumentation. Initial acquisition and cumulative 120/600-frame measurements are logged separately from visual acceptance.

Candidate.2 live evidence: supported LLL reload acknowledged true/loaded. Over 600 deployed updates: mean elapsed 0.1815 ms, maximum 0.9869 ms, one Unit enumeration, eight GUI creations and eight ink updates. The explicit cold reload took 22 ms overall; LLL attributed 6 ms/about 8.4 MB to initialization. Initial avatar acquisition plus submission took 0.8523 ms. This separates the manual load/compile allocation spike from per-frame animation. Candidate.2 appearance and gameplay transitions remain unverified.

Acceptance still required: centered placement across armor/cape/backpack combinations; standing, turning, sprinting, crouch, prone, dive/get-up; ADS/first-person hiding; damage/healing; death/respawn; world transition and unload. Measure deployed frame cost and transition spikes before integration. Only the dedicated dbf_spine_health LLL folder is deployed; no game archive or existing mod is replaced.
