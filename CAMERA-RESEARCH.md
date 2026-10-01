# Camera-state investigation

First-person placement now reads the validated local-player state. The distance/FOV heuristic is retained only when that read is unavailable. Shoulder placement still uses the lateral-offset heuristic; no authoritative shoulder flag is verified yet.

The separate MDL Camera Research helper samples only when Debug logging is enabled and a labeled request is queued. It does not draw a HUD or change camera behavior. Build/install using `python tools/build_camera_research.py --install`, then enable DBF-HUD Camera Research in MDL.

Hold a known camera mode with a weapon equipped. Run `python tools/camera_snapshot.py right1` (or another label). The request is acknowledged through DBF-HUD-camera.log and saved under the workspace work directory. Samples cover a bounded camera-state header, camera object, local-player view fields and the avatar's identity-checked selector record. Ownership and camera pointers are rechecked; unreadable or changing state rejects the capture.

Compare repeated samples of right shoulder, left shoulder and first person, then repeat with rapid rotation and multiple weapons. Byte differences alone are candidates, not verified flags. Trace candidate readers/writers before replacing heuristics. Disable the helper after research.

## Controlled samples from September 30

The safe right, left and first-person sets have matching avatar and selected-weapon identity. The local-player manager field at +0x2EC is uint32 zero in both third-person shoulder samples and one in first person, across two samples per mode. This is a candidate only: no placement change uses it. Verify its return when leaving first person, stability during rapid camera rotation, lifecycle across respawn and multiple weapons, and the native reader/writer meaning before adopting it. Earlier samples with mixed identity or uncertain aim holds are excluded.

The shoulder comparison has not established a state flag. Camera-object differences at +0x28 and +0x34 are near clip and vertical FOV, not accepted camera-mode flags. Differing render-state indices and selector floats must not be treated as shoulder enums.

Expanded snapshots include the local-player header and a bounded camera-state tail. The optional trace_code request captures small code regions near already validated player/weapon readers for offline disassembly; camera_apis inventories available namespaces without invoking their engine functions. Neither changes gameplay or placement.

The safe return-to-right samples retain weapon 1216 and avatar unit 1076; +0x2EC returns to zero in both. A fresh tutorial sequence retains weapon 4194980 and avatar unit 398 throughout: baseline zero, first-person one twice, and third-person return zero twice after the requested camera movement. This establishes repeatable transitions across two identities/weapons, not the native semantic meaning. Production placement remains unchanged.

The bounded player-control code window was expanded to 25 KiB in 1 KiB reads. Offline disassembly covering the entire window found no direct +0x2EC operand. This rules out a direct access in that inspected window, not indirect access or access elsewhere. The trace is still read-only and below the existing 64 KiB read budget.

Tutorial shoulder captures retained the same identity. Neither aligned words nor individual stable bytes distinguish the shoulders in the local-player header/view or the additional +0x400 through +0xFFF region. The `wide_state` labeled request enables those additional bounded snapshots; production does not read them. Camera transform differences are excluded. A second 25 KiB code window beginning at module +0x603000 also has no direct +0x2EC operand. First-person semantic verification and a different shoulder-state owner remain open.

`camera_links` requests capture 512 bytes from each of the camera-state links at +0x180, +0x188, +0x190 and +0x1A0, rechecking each pointer after reading. All four are readable in the tutorial right-shoulder reference. The +0x1A0 target begins with a registry pointer and consecutive indices, so its values must not be promoted to mode flags. The other links remain unidentified; a pose comparison is needed before treating any difference as a candidate. No methods from these objects are called.

## Native first-person control verification

The protected disk gameplay image has the supported timestamp but does not expose the loaded code signatures. Research therefore used bounded reads from the live, validated module. `code_probe_N` reads one 48 KiB page in twelve 4 KiB reads and emits only blocks containing the candidate displacement, with normal camera/avatar rechecks. The inspected region is module +0x500000 through +0xDFFFFF. Offset matches in unrelated objects are not mode evidence.

The toggle path at +0xA42890 resolves the local-player manager at +0xA42A74: its RIP-relative load targets +0x3326468. It resolves the local player's index and computes a 0x38-byte record stride, then compares and flips the byte at record +0x2EC at +0xA42B1F/+0xA42B2A. The existing ownership reader establishes local slot zero. This ties the sampled field to accepted player-control code. The tutorial released-aim samples retain weapon 4194980 and avatar unit 398, and both clear the byte to zero after first-person aim is released.

Production `camera_mode.lua` validates those three native signatures, the local-player slot and controlled-avatar unit, a strict zero/one byte, and pointer/identity stability. It never calls the toggle function or writes game memory. Runtime prefers the explicit boolean, including false, and falls back to the previous first-person heuristic if validation fails. The local-player entity and avatar entity are distinct in game; ownership uses the player's own record rather than the avatar ID. Live logs confirm `source=game first-person state` after deployment. Visual placement testing with this new path is still pending.

Camera-link and player-link shoulder comparisons retained identity but yielded only coordinate/float differences. No new shoulder logic was deployed.

## Character-control owner investigation

Neighboring command code at +0xA43418 resolves manager +0x3326D20. Its +0xF8 identity map selects the controlled avatar, +0x110 holds inline identity pointers, and the native code uses a +0xA7AEC record stride. The helper now verifies the mapped record pointer against the ammo reader's avatar record before reading this candidate owner. The initial +0x1800/+0x1C00/+0x3000/+0x3400 snapshots produced no stable shoulder difference.

`avatar_page_N_LABEL` captures this same record in fourteen bounded pages, each with at most twelve 4 KiB reads, constrained to the observed record extent and rechecking camera/avatar/control ownership. Two full left and two full right captures all retain weapon 4194980 and avatar unit 398. Their comparison found zero stable differing whole bytes or aligned words. A bit-level comparison produced 950 positions with differing masks, but changing numeric data can create these coincidences; none is accepted as a flag. A rotated right-shoulder sequence is the next elimination check. Contract tests cover page/read budgets, final-page bounds, invalid page rejection, and ownership changes during reads.

The rotated-right and return-left full-record captures reduced coincidental bit matches from 950 to 517, then 125. The clearest survivors are float-like data; none is accepted as shoulder state. The first-person command also references settings manager +0x347CDD8 and preference byte +0x897BC. Two left and two right captures of +0x89000 through +0x8A7FF retained weapon 4194980 and avatar unit 398 and yielded zero stable differing bytes. This settings region therefore supplies no shoulder-state candidate. Production shoulder placement remains unchanged.

Command-linked flags probe uses identity map +0xF8 under manager +0x3326D20, verified inline avatar pointer +0x110, and separate native record +0x53E880 with stride +0x1238. Right1/right2, left1/left2, return-right3/right4 and rotated-right5/right6 retain weapon 4194980/avatar 398. Byte +0xD mask 4 (qword +8 bit 42) is off in all right captures and on in both left captures. Other changing bits failed the return check. Native getter +0xA46030 resolves this manager and at +0xA460E1 reads qword +0x53E888, shifts by 42 at +0xA460E9, and masks one. This proves a native flag getter exists for the candidate; shoulder semantics and left-rotation stability remain unverified. No production shoulder logic changed.

Rotated left3/left4 retained candidate=true; rotated right5/right6 retained false. Released aim cleared the candidate in both samples; left re-aim without swapping restored true in both. Identity stayed weapon 4194980/avatar 398. Native +0xA464B0 setter constructs bit42 at +0xA46589 and ORs it into the flag word at +0xA465D4; +0xA46720 clearer constructs the same mask at +0xA46807 and clears it at +0xA4685C. Thus the candidate is an active state rather than persistent shoulder preference. First-person negative control and additional-weapon validation remain pending before production adoption.
