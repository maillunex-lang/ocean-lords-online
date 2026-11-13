# Ocean shader: user's original textures

The four PNGs in this directory came from the user's approved ocean asset archive,
transferred intact to Lunex with Termalin and checked by SHA-256. They replace the
older procedural placeholder PNGs in the project.

| PNG | Shader uniform | Resolution |
| --- | --- | --- |
| ocean_normal_medium.png | normal_medium | 1024x1024 |
| ocean_normal_detail.png | normal_detail | 512x512 |
| ocean_foam_mask.png | foam_mask | 1024x1024 |
| ocean_foam_noise.png | foam_noise | 512x512 |

All four are loaded in scripts/main.gd, checked in tests/test_original_ocean.gd.
The shader in shaders/ocean_mobile.gdshader contains moving normal maps,
foam breakup, Gerstner-style simplified height waves and a cheap dynamic wake.
The sun and moon bearings are fixed in world coordinates.

The screenshots are visual QA on Godot's software-rendering environment, NOT a
substitute for Android hardware testing.
