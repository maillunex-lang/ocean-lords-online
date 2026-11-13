# Ocean texture pack

The shader at `shaders/ocean_mobile.gdshader` supports four textures:

| File | Shader uniform | Source size |
| --- | --- | --- |
| `assets/ocean/ocean_normal_medium.png` | `normal_medium` | 1024×1024 |
| `assets/ocean/ocean_normal_detail.png` | `normal_detail` | 512×512 |
| `assets/ocean/ocean_foam_mask.png` | `foam_mask` | 1024×1024 |
| `assets/ocean/ocean_foam_noise.png` | `foam_noise` | 512×512 |

The user-supplied images have been prepared in a downloadable archive. The PNG binaries have **not yet been committed to this repository**. Extract the archive at the project root, keeping the `assets/ocean/` paths, and commit the PNGs to this feature branch. The game checks all four resources at runtime and enables texture details only when all are present.

For Android, use mipmaps and repeating sampler modes. Verify tangent-space normal direction, edge tiling, and foam threshold in Godot on a real device. The headless CI run does not validate visual appearance or device FPS.

Do not merge to main or label the APK visually validated until the texture binaries are committed and the build has passed.
