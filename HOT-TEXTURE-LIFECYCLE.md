# Hot texture lifecycle

The current HUD artwork lifecycle and its measured limits are documented in [Hot HUD artwork: loading and reclamation](docs/HOT-PANEL-ART.md).

Repeated successful HUD artwork swaps now retire old native resources after material detachment and renderer completion. The live 32-cycle full-size test returned to the original six-resource baseline; the budget is no longer consumed cumulatively by each edit.

This documentation describes the deployed HUD artwork implementation. The separate world-mesh/scope runtime texture controller retains its own conservative lifetime policy.
