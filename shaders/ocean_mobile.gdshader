shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Mobile-friendly analytic wave displacement: two waves, no texture fetches.
uniform vec4 deep_color : source_color = vec4(0.025, 0.16, 0.22, 1.0);
uniform vec4 crest_color : source_color = vec4(0.10, 0.38, 0.43, 1.0);
uniform float wave_height : hint_range(0.0, 1.0) = 0.18;
uniform float wave_scale : hint_range(0.01, 1.0) = 0.12;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.75;

varying float wave_signal;

void vertex() {
    float a = (VERTEX.x * 0.87 + VERTEX.z * 0.49) * wave_scale + TIME * wave_speed;
    float b = (VERTEX.x * -0.43 + VERTEX.z * 0.91) * wave_scale * 1.6 - TIME * wave_speed * 0.7;
    float wa = sin(a);
    float wb = sin(b);
    VERTEX.y += wave_height * (wa + 0.45 * wb);
    wave_signal = wa * 0.5 + wb * 0.2;
    float dx = wave_height * wave_scale * (0.87 * cos(a) - 0.45 * 1.6 * 0.43 * cos(b));
    float dz = wave_height * wave_scale * (0.49 * cos(a) + 0.45 * 1.6 * 0.91 * cos(b));
    NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
    float t = clamp(0.5 + wave_signal * 0.45, 0.0, 1.0);
    ALBEDO = mix(deep_color.rgb, crest_color.rgb, t);
    ROUGHNESS = 0.26;
    METALLIC = 0.08;
}
