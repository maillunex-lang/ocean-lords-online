shader_type spatial;
render_mode cull_back, diffuse_burley;
uniform vec4 timber : source_color = vec4(0.39, 0.24, 0.13, 1.0);
varying vec3 local_pos;
void vertex() { local_pos = VERTEX; }
void fragment() {
    float grain = sin(local_pos.y * 35.0 + sin(local_pos.x * 7.0) * 0.7) * 0.07;
    float plank = step(0.88, fract(local_pos.y * 2.7)) * 0.10;
    ALBEDO = timber.rgb * (0.93 + grain - plank);
    ROUGHNESS = 0.73;
    SPECULAR = 0.27;
}
