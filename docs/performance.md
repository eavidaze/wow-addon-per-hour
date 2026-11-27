# Performance validation

Run lua tests/forever.lua with Lua 5.1. tests/performance.lua uses the
shared Forever fixture and real source modules loaded through TOC/XML.

The runtime owns one sampling timer while a session runs. Idle, paused and
out-of-world sessions do not reschedule it. XP/reputation and Gold action handlers
use native events, independent of dashboard visibility. Ordinary timer samples do
not scan bags unless a cast, delivery or inventory loss needs reconciliation.

Dashboard and consultation refreshes coalesce bursts with a deferred callback.
There are no Lua per-frame polling handlers on dashboard/capture frames.
Standard-window placement runs on first show and fitting reacts to show/size
changes. Native toplevel/render-layer flattening handles window stacking; there
is no Lua per-frame window manager or custom frame-level counter.
History/Details lists remain virtualized with native extent calculators. Gold
events use 26 px, sessions 28 px, ordinary headers 24 px, Compare headers 28 px
and Compare metric rows 32 px. Renderers lazily
create controls by row type; event rows do not allocate History action controls.
Refreshes map stable row IDs to pixel offsets once to retain the viewport, including
partial rows. Cached item metadata affects presentation only and performs no quote lookup.
Details keeps its fixed session metadata in a reusable frame pool outside the
ScrollBox. Native Options tabs share one virtualized metric viewport; switching
tabs replaces its data provider, without creating separate lists or new timers.
History, Compare and Details extract their leading headers into a small reusable
frame pool outside the ScrollBox; Gold also pins its Sum row. Only body rows enter
the provider and stable-ID viewport calculations. Reputation builds one aggregate
row per faction plus untracked time, without a second interval grid. Gold Sum
reuses the grouped recorded amounts and never queries providers or changes totals.
Details computes wrapped property/table row heights from native font metrics
while building its small summary model. It reuses hidden measuring font strings;
event rows keep fixed extents and do not require text measurement. There is no
unbounded text-size cache or additional polling timer.
Native speedometer animation groups handle overload. Minimap dragging stays
owned by LibDBIcon. Checkpoints/deep ledger copies happen at explicit lifecycle
and client save boundaries, not ordinary timer ticks.
Duration renders status-colored text without an animation. It changes every
second only during the first minute, then at minute boundaries. Identical text
is not rewritten. The optional active indicator remains a reusable component:
its native FlipBook plays 84 frames over 1.4 seconds, with no OnUpdate, and stops
when hidden or inactive. The dashboard does not instantiate it or load its atlas.
Regenerate the atlas with scripts/generate-session-indicator.py; its geometry
comes from SessionIndicator.lua.

The speedometer recalculates geometry only when its width or scale labels change.
Its 10 px fonts remain unscaled. scripts/generate-speedometer-assets.py reads the
same geometry and palette as Lua. It computes distance-based edge coverage
directly into the final 512 px alpha channel, preserving opaque stroke centers
without a blurred low-resolution intermediate. SpeedometerArc.tga and
SpeedometerPointer.tga use linear sampling. Label rectangles remain outside
the arc and inside the gauge bounds. dist/SpeedometerPreview.png compares sizes
and angles using bilinear sampling; it is a local
texture/font preview, not native-client validation. Check edge smoothness at the
actual game resolution/UI scale and restart the client after replacing textures.

History/Details/Compare use native virtualized ScrollBoxes, reusing a bounded
visible row pool. Gold rows group at most 1,000 retained events. Aggregation is linear in events
and quote parts, followed by sorting the groups; stable IDs retain the viewport.
Only the selected flow is built, with no market-price queries.
Quote parts consolidate by recorded price/source/stock origin, with at most six
parts drawn in a tooltip. Per-character
history keeps 100 summaries and details for 20; runtime FIFO and pending data are
preserved for the current session independently from consultable limits.

## In-game comparison

1. Use the same UI scale, resolution, FPS and farming route for before/after runs.
2. Observe idle, running, paused, hidden dashboard and visible long Details.
3. Compare CPU and memory with addon profiling enabled, recording conditions.
4. Exercise repeated loot, provider callbacks, scrolling, metric dragging and gauge overload.
5. Reload between independent measurements; check growth across several sessions.

Do not present fixture timer counts or object reuse as in-game CPU measurements.
The native-client comparison remains pending.
