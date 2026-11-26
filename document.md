# Source structure

- src/model: addon namespace and shared speedometer scales.
- src/stores: settings, current checkpoint and account history persistence.
- src/modules: XP, Gold, honor and segmented reputation capture; common status/estimate helpers.
- src/pricing: optional quote providers and session-local FIFO ledger.
- src/core/Session.lua: shared clock, lifecycle, snapshots and continuity.
- src/core/Capture.lua: native event dispatch and one scheduler.
- src/core/MetricFormat.lua: common amounts, rates, flags, dates and truncation.
- src/core/Dashboard.lua: configurable shared activity panel.
- src/core/SessionIndicator.lua: optional reusable active/pause indicator; not instantiated by the dashboard.
- src/core/SettingsPanel.lua: native preferences and metric swapping.
- src/core/SessionPanels.lua: History, Details, Compare, Rename and Delete.
- src/core/Components.lua, Form.lua, Speedometer.lua, Theme.lua: reusable native UI.
- src/core/MinimapButton.lua, CommandLine.lua, Bootstrap.lua: entry points and initialization.
- tests/forever-fixture.lua: simulated native UI/API contracts.
- tests/forever.lua: integration entry point and capture/provider regressions.

See [architecture](docs/stores.md), [interface and test checklist](docs/panels.md)
and the [approved design](docs/revamp.html).
