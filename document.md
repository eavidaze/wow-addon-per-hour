# Source structure

- src/model: addon namespace and shared speedometer scales.
- src/stores: settings, current checkpoint and account history persistence.
- src/modules: XP, Gold, honor and segmented reputation capture; common status/estimate helpers.
- src/pricing: optional quote providers and session-local FIFO ledger.
- src/core/Session.lua: shared clock, lifecycle, snapshots and continuity.
- src/core/Capture.lua: native event dispatch and one scheduler.
- src/core/MetricFormat.lua: common amounts, native coin strings, rates, flags, dates, measured durations and truncation.
- src/core/Dashboard.lua: configurable shared activity panel.
- src/core/SessionIndicator.lua: optional reusable active/pause indicator; not instantiated by the dashboard.
- src/core/PanelWindows.lua: shared cascade placement and screen fitting for standard windows.
- src/core/SettingsPanel.lua: native preferences and metric swapping.
- src/core/SessionPanels.lua: History, Details, Compare, Rename and Delete.
- src/core/SessionList.lua: fixed reusable table headers, native variable-height body lists and stable viewport anchoring.
- src/core/SessionRows.lua: separate compact session, Gold event, header and summary renderers.
- src/core/GoldGroups.lua: read-only item/source aggregation, quantities, last occurrence and value ordering for Income/Expenses.
- src/core/Tabs.lua: reusable native Options tabs and radio selection.
- src/core/DetailsView.lua: grouped session card with inline Rename, Gold sums/events and one aggregate Reputation grid with measured wrapping.
- src/core/ComparisonView.lua: compact hourly comparison with centered vs., per-metric winners and percentage advantages.
- src/core/DetailsPanel.lua: fixed card/header pools, native Income/Expenses/Reputation tabs and body-only virtualized scrolling.
- src/core/Components.lua, Form.lua, Speedometer.lua, Theme.lua: reusable native UI.
- src/core/MinimapButton.lua, CommandLine.lua, Bootstrap.lua: entry points and initialization.
- tests/forever-fixture.lua: simulated native UI/API contracts.
- tests/forever.lua: integration entry point and capture/provider regressions.
- tests/finish-confirmation.lua: shared Finish confirmation, cancellation, footer visibility and stale-target protection.
- tests/comparison.lua: hourly rates, faction union, winners, percentages, complete readings and compact scrolling layout.
- tests/gold-groups.lua: grouped values/counts, pending/frozen prices, stable identities, variants and Income/Expenses navigation.
- tests/table-layout.lua: pinned headers/sums, body-only scrolling, card ordering and aggregate Reputation presentation.

See [architecture](docs/stores.md), [interface and test checklist](docs/panels.md)
and the [approved design](docs/revamp.html).
