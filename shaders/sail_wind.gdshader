shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 cloth_color : source_color = vec4(0.82, 0.77, 0.63, 1.0);
uniform float wind_strength : hint_range(0.0, 2.0) = 0.8;
uniform vec2 wind_direction = vec2(0.94, 0.34);
varying float ripple;
void vertex() {
    float flutter = sin(TIME * (2.0 + wind_strength) + UV.y * 9.0 + UV.x * 3.0);
    float billow = sin(UV.x * 3.14159) * (0.35 + 0.20 * flutter);
    VERTEX.z += billow * wind_strength;
    VERTEX.x += wind_direction.x * (UV.y * UV.y) * 0.14 * wind_strength * flutter;
    ripple = flutter;
}
void fragment() {
    float stripe = 0.93 + 0.07 * sin(UV.x * 30.0);
    ALBEDO = cloth_color.rgb * stripe * (0.94 + 0.06 * ripple);
    ROUGHNESS = 0.92;
}
