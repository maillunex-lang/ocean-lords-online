# Mobile rendering, physics and performance budget (draft)

## Current implementation
- Godot 4.3 GL Compatibility renderer for broad Android support.
- Ocean: one 65×65 vertex plane, two sine-wave vertex displacements, analytic approximate normals; no texture samples, no expensive transparency or screen-space reflections.
- Ship: low-cost primitive mesh placeholder, visual bob/pitch/roll using three wave samples and smoothed rotation.
- Navigation: kinematic acceleration and yaw; **not** realistic buoyancy, collision or network-authoritative physics.
- HUD: two-finger controls and safe-area offsets, subject to real device tests.

## Future scalability
- Use chunked ocean mesh around camera (current plane is a temporary prototype).
- Keep gameplay collision/position authoritative and independent from purely visual wave shader.
- Mesh LOD tiers, frustum/distance culling, pooled cannonballs, batching and instancing.
- Graphics profiles Low/Medium/High with capped ocean subdivision, shadow resolution, effects and render scale.
- Keep UI at native resolution when dynamically scaling 3D.
- Use adaptive quality based on frame-time and thermal indicators with hysteresis; do not oscillate quality every frame.
- Never run rigid-body simulation for all distant ships: approximate inactive NPC routes on server.
- Profile on low-end Android GPUs before committing to advanced foam, SSR or volumetric fog.

## Proposed measurement gates (not measured)
- Target 30 FPS on baseline devices; optional 60 FPS on capable devices.
- Track median, p95 frame time, draw calls, GPU memory and battery/thermal behavior.
- Profile CPU vs GPU bottlenecks before adding shaders.
- Validate orientation, camera cutout and both portrait/landscape transitions.

## Current known limitations
- Water vertex displacement does not alter gameplay collision.
- Wave shader is visual only; time origin is local, not synchronized across clients.
- No foam, wakes, spray, ship collision, artillery, weather, multiplayer or asset LOD.
- No Android-device performance measurements yet.
