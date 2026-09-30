# Camera-state investigation

Existing distance/FOV and lateral-offset heuristics still drive placement. No mode flag is verified yet.

The separate MDL Camera Research helper samples only when Debug logging is enabled and a labeled request is queued. It does not draw a HUD or change camera behavior. Build/install using `python tools/build_camera_research.py --install`, then enable DBF-HUD Camera Research in MDL.

Hold a known camera mode with a weapon equipped. Run `python tools/camera_snapshot.py right1` (or another label). The request is acknowledged through DBF-HUD-camera.log and saved under the workspace work directory. Samples cover a bounded camera-state header, camera object, local-player view fields and the avatar's identity-checked selector record. Ownership and camera pointers are rechecked; unreadable or changing state rejects the capture.

Compare repeated samples of right shoulder, left shoulder and first person, then repeat with rapid rotation and multiple weapons. Byte differences alone are candidates, not verified flags. Trace candidate readers/writers before replacing heuristics. Disable the helper after research.

## Controlled samples from September 30

The safe right, left and first-person sets have matching avatar and selected-weapon identity. The local-player manager field at +0x2EC is uint32 zero in both third-person shoulder samples and one in first person, across two samples per mode. This is a candidate only: no placement change uses it. Verify its return when leaving first person, stability during rapid camera rotation, lifecycle across respawn and multiple weapons, and the native reader/writer meaning before adopting it. Earlier samples with mixed identity or uncertain aim holds are excluded.

The shoulder comparison has not established a state flag. Camera-object differences at +0x28 and +0x34 are near clip and vertical FOV, not accepted camera-mode flags. Differing render-state indices and selector floats must not be treated as shoulder enums.

Expanded snapshots include the local-player header and a bounded camera-state tail. The optional trace_code request captures small code regions near already validated player/weapon readers for offline disassembly; camera_apis inventories available namespaces without invoking their engine functions. Neither changes gameplay or placement.
