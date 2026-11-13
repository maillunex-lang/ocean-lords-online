shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform vec4 glow_color : source_color = vec4(1.0, 0.77, 0.38, 1.0);
uniform float glow_intensity : hint_range(0.0, 4.0) = 1.4;
void fragment() {
    float r = length(UV - vec2(0.5));
    float core = 1.0 - smoothstep(0.055, 0.13, r);
    float halo = pow(max(0.0, 1.0 - r * 2.0), 3.0);
    float rays = pow(abs(cos(atan(UV.y - 0.5, UV.x - 0.5) * 4.0)), 20.0) * pow(max(0.0, 1.0 - r * 2.0), 4.0);
    ALBEDO = glow_color.rgb;
    EMISSION = glow_color.rgb * glow_intensity * (core * 1.6 + halo * 0.7 + rays * 0.2);
    ALPHA = clamp(core + halo * 0.75 + rays * 0.15, 0.0, 1.0);
}
