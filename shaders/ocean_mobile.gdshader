shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Mobile ocean: scrolling normal maps and foam masks.
uniform sampler2D normal_medium : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_detail : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D foam_mask : repeat_enable, filter_linear_mipmap;
uniform sampler2D foam_noise : repeat_enable, filter_linear_mipmap;
uniform bool use_texture_details = false;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.35;
uniform float foam_amount : hint_range(0.0, 1.0) = 0.25;
uniform vec4 foam_color : source_color = vec4(0.70, 0.83, 0.83, 1.0);
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
    if (use_texture_details) {
        vec2 uv_a = UV * 14.0 + vec2(0.013, 0.008) * TIME;
        vec2 uv_b = UV * 38.0 + vec2(-0.019, 0.011) * TIME;
        vec3 n_a = texture(normal_medium, uv_a).rgb * 2.0 - 1.0;
        vec3 n_b = texture(normal_detail, uv_b).rgb * 2.0 - 1.0;
        NORMAL_MAP = normalize(vec3((n_a.xy + n_b.xy * 0.45) * normal_strength, 1.0)) * 0.5 + 0.5;
        NORMAL_MAP_DEPTH = 1.0;
        float f = texture(foam_mask, UV * 5.0 + vec2(0.006, -0.004) * TIME).r;
        float noise_v = texture(foam_noise, UV * 9.0 + vec2(-0.004, 0.007) * TIME).r;
        float crest = smoothstep(0.50, 0.88, t);
        float foam = smoothstep(0.50, 0.78, f * 0.7 + noise_v * 0.3) * crest * foam_amount;
        ALBEDO = mix(ALBEDO, foam_color.rgb, foam);
    }
    ROUGHNESS = 0.26;
    METALLIC = 0.08;
}
