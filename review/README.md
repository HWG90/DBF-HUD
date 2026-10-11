# HUD design reviews

The universal HUD direction selected on October 11 is [Split study08](universal-hud-split-08/index.html). Its [family overview](universal-hud-split-08/family-overview.png), [actual-size review](universal-hud-split-08/actual-scale.png), and [brief](universal-hud-split-08/BRIEF.md) document the refined layout. These are design candidates, not universal runtime integration.

[Study07](universal-hud-study-07/index.html) preserves Orbit, Rail, and Split. The earlier primary studies01â€“04 and [accepted slanted digit study06](primary-digit-study-06/index.html) remain available as references.

These galleries use authored vector/bitmap assets and illustrative data. Private gameplay captures are optional local backgrounds; published galleries fall back to a neutral scene. Runtime deployment records, user settings, logs, raw font donors, and backups stay in local ignored outputs.

The current live primary HUD uses the existing HUD Texture renderer. Its new edge controls are width0â€“24%, curve0.5â€“3, dither0â€“100%, and grain1â€“4. [Edge mask comparison](hud-edge-dither-20261011/index.html) shows the generated alpha treatments. Reproducible asset and package instructions are in [BUILD-ASSETS](../docs/BUILD-ASSETS.md).
