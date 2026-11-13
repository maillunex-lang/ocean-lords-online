# Meshy brigantine mobile LOD

Source: approved Meshy preview task 01a1d5b7-0a77-7581-90b7-8b02cef43a67 (56,488,460-byte GLB).
The original file is kept outside GitHub in private NEXUS storage.

Blender 5.0.1 generated three independent static GLB assets from the same source:
- brigantine_lod0.glb for camera distance <=45 world units.
- brigantine_lod1.glb for distance >45 and <=90 units.
- brigantine_lod2.glb for distance >90 units (6,494 triangles; 4,000 target was not achievable without further mesh repair).

All are geometry-only with a simple wood material, no textures or rigged animations.
LOD switches are controlled in scripts/main.gd by toggling visibility, with fallback to
the original primitive vessel if the GLBs cannot be imported.

Important: This is a Meshy preview mesh with no UV map or textures. Do not
represent it as a finished textured AAA model. Review its appearance on Android.
