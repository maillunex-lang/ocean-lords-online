shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Mobile ocean: scrolling normal maps and foam masks.
uniform sampler2D normal_medium : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_detail : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D foam_mask : repeat_enable, filter_linear_mipmap;
uniform sampler2D foam_noise : repeat_enable, filter_linear_mipmap;
uniform bool use_texture_details = false;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.10;
uniform float foam_amount : hint_range(0.0, 1.0) = 0.82;
uniform vec3 sun_direction = vec3(0.4, 0.8, 0.25);
uniform float sun_glitter : hint_range(0.0, 1.0) = 0.32;
uniform vec4 foam_color : source_color = vec4(0.70, 0.83, 0.83, 1.0);
uniform vec4 deep_color : source_color = vec4(0.025, 0.16, 0.22, 1.0);
uniform vec4 crest_color : source_color = vec4(0.10, 0.38, 0.43, 1.0);
uniform float wave_height : hint_range(0.0, 1.0) = 0.58;
uniform float wave_scale : hint_range(0.01, 1.0) = 0.18;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.75;

uniform vec3 ship_position = vec3(0.0);
uniform vec3 ship_forward = vec3(0.0, 0.0, -1.0);
uniform float ship_speed = 0.0;
varying float wave_signal;
varying vec2 sea_world_xz;

void vertex() {
    sea_world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
    float a = (sea_world_xz.x * 0.87 + sea_world_xz.y * 0.49) * wave_scale + TIME * wave_speed;
    float b = (sea_world_xz.x * -0.43 + sea_world_xz.y * 0.91) * wave_scale * 1.6 - TIME * wave_speed * 0.7;
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
        // Two distinct spatial scales keep the supplied wave patterns readable.
        vec2 uv_a = sea_world_xz * 0.075 + vec2(0.009, 0.006) * TIME;
        vec2 uv_b = sea_world_xz * 0.32 + vec2(-0.018, 0.011) * TIME;
        vec3 n_a = texture(normal_medium, uv_a).rgb * 2.0 - 1.0;
        vec3 n_b = texture(normal_detail, uv_b).rgb * 2.0 - 1.0;
        vec2 surface_normal = (n_a.xy * 0.95 + n_b.xy * 0.55) * normal_strength;
        NORMAL_MAP = normalize(vec3(surface_normal, 1.0)) * 0.5 + 0.5;
        NORMAL_MAP_DEPTH = 1.0;
        float f = texture(foam_mask, sea_world_xz * 0.12 + vec2(0.007, -0.005) * TIME).r;
        float noise_v = texture(foam_noise, sea_world_xz * 0.25 + vec2(-0.012, 0.009) * TIME).r;
        float crest = smoothstep(0.36, 0.77, t);
        float foam_pattern = smoothstep(0.37, 0.66, f * 0.82 + noise_v * 0.18);
        float foam = foam_pattern * (0.20 + crest * 0.80) * foam_amount;
        ALBEDO = mix(ALBEDO, foam_color.rgb, clamp(foam, 0.0, 0.88));
        ROUGHNESS = mix(0.18, 0.65, foam);
        // Visible small-scale wave shading from the actual supplied normal maps.
        float ripple_light = clamp(dot(normalize(vec3(surface_normal, 1.0)), normalize(vec3(0.42, 0.65, 0.53))), 0.0, 1.0);
        ALBEDO *= 0.70 + ripple_light * 0.60;
    }
    // Thin, inexpensive bow and trailing wakes, driven by REAL ship position
    // and speed. Adds no extra texture reads and fades when sails are reefed.
    vec2 forward = normalize(ship_forward.xz + vec2(0.00001));
    vec2 sideways = vec2(-forward.y, forward.x);
    vec2 offset = sea_world_xz - ship_position.xz;
    float behind = -dot(offset, forward);
    float cross_track = abs(dot(offset, sideways));
    float spread = 1.6 + max(behind, 0.0) * 0.14;
    float trail = (1.0 - smoothstep(spread * 0.20, spread, cross_track));
    trail *= smoothstep(-1.0, 3.0, behind) * (1.0 - smoothstep(18.0, 48.0, behind));
    float diverging = exp(-pow((cross_track - (1.3 + max(behind, 0.0) * 0.23)) / 0.85, 2.0));
    diverging *= smoothstep(-2.0, 3.0, behind) * (1.0 - smoothstep(20.0, 45.0, behind));
    float bow_foam = exp(-length(vec2(dot(offset, forward) - 8.0, cross_track * 1.5)) * 0.6);
    float wake = clamp((trail * 0.50 + diverging * 0.48 + bow_foam * 0.9) * clamp(ship_speed / 6.0, 0.0, 1.0), 0.0, 0.8);
    ALBEDO = mix(ALBEDO, foam_color.rgb, wake);
    ROUGHNESS = mix(ROUGHNESS, 0.23, 0.20);
    METALLIC = 0.08;
    // Cheap directional glints, no screen-space reflection or extra texture fetch.
    vec3 light_dir = normalize(sun_direction);
    vec3 view_dir = normalize(VIEW);
    vec3 half_dir = normalize(light_dir + view_dir);
    float sparkle = pow(max(dot(normalize(NORMAL), half_dir), 0.0), 64.0);
    EMISSION = vec3(0.60, 0.72, 0.72) * sparkle * sun_glitter;
}
