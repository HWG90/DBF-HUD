# Current dynamic shader layers

Production layer path uses existing mapped native materials as ordered alpha overlays. Four actual rows maximum; add, remove, reorder, enable, opacity, pattern size, animation and speed share HUD configuration and MCM callbacks. No newly compiled shader libraries are installed. Native material availability gates emission; separate bounded GUI instances isolate per-layer parameters and are released with their owner.

The abandoned single-pass compositor and binary-library resizing helpers are retained in the evidence cleanup archive. That package was removed during recovery; crash causality was not isolated. Old references to installed compositor libraries are historical evidence, not current deployment instructions.

Current checks: actual MCM list/edit/persistence tests; existing-material overlay binding/GUI cleanup test; Lua DF state/count bounds and global texture override test. Offline checks do not establish live blending/performance or game color-space equivalence.
