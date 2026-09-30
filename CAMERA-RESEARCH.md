# Camera-state investigation

Existing distance/FOV and lateral-offset heuristics still drive placement. No mode flag is verified yet.

The separate MDL Camera Research helper samples only when Debug logging is enabled and a labeled request is queued. It does not draw a HUD or change camera behavior. Build/install using `python tools/build_camera_research.py --install`, then enable DBF-HUD Camera Research in MDL.

Hold a known camera mode with a weapon equipped. Run `python tools/camera_snapshot.py right1` (or another label). The request is acknowledged through DBF-HUD-camera.log and saved under the workspace work directory. Samples cover a bounded camera-state header, camera object, local-player view fields and the avatar's identity-checked selector record. Ownership and camera pointers are rechecked; unreadable or changing state rejects the capture.

Compare repeated samples of right shoulder, left shoulder and first person, then repeat with rapid rotation and multiple weapons. Byte differences alone are candidates, not verified flags. Trace candidate readers/writers before replacing heuristics. Disable the helper after research.
