# Performance validation

Run lua tests/forever.lua with Lua 5.1. tests/performance.lua uses the
shared Forever fixture and real source modules loaded through TOC/XML.

The runtime owns one sampling timer while a session runs. Idle, paused and
out-of-world sessions do not reschedule it. XP/reputation and Gold action handlers
use native events, independent of dashboard visibility. Ordinary timer samples do
not scan bags unless a cast, delivery or inventory loss needs reconciliation.

Dashboard and consultation refreshes coalesce bursts with a deferred callback.
There are no Lua per-frame polling handlers on dashboard/capture frames.
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
visible row pool. Gold event lists expose at most 1,000 entries. Per-character
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
