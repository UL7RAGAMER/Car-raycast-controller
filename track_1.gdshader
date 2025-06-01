shader_type spatial;
render_mode cull_disabled;

uniform float sway = 1.14;
uniform float sway_ = 0.34;
uniform float sway_pow = 1.3;
uniform float grass_roughness = 0.3;
uniform float sway_noise_sampeling_scale = 0.12;
uniform float sway_time_scale = 0.2;
uniform vec3 sway_dir = vec3(1.0, 0.0, 1.0);
uniform sampler2D sway_noise : source_color;
uniform float color_scale = 0.3;
uniform float color_grad_height = -0.5;
uniform vec4 top_color : source_color;
uniform vec4 bot_color : source_color;
uniform vec3 grass_scale = vec3(1.0, 1.0, 1.0);

varying vec3 vert;
varying float current_wind;

float sclamp(float f, float sc) {
    return clamp(((f - 0.5) * sc) + 0.5, 0.0, 1.0);
}

void vertex() {
    VERTEX *= grass_scale;
    vert = VERTEX;

    // World matrix replacement
    mat4 world_transform = MODEL_MATRIX;
    vec4 sway_dir_local = vec4(sway_dir, 0.0) * world_transform;

    vec3 world_vertex = (world_transform * vec4(VERTEX, 1.0)).xyz;

    vec2 noise_uv = normalize(sway_dir.xz) * (-TIME * sway_time_scale) + world_vertex.xz * vec2(sway_noise_sampeling_scale);
    current_wind = texture(sway_noise, noise_uv).x;

    VERTEX += normalize(sway_dir_local.xyz) * sway * VERTEX.y * sclamp(current_wind, 1.5);
    VERTEX.y -= sway_ * abs(pow(VERTEX.x, sway_pow));

    NORMAL = vec3(0.0, 1.0, 0.0); // Flat normal
}

void fragment() {
    ALBEDO = mix(bot_color.rgb, top_color.rgb, (vert.y + color_grad_height) * color_scale);
    if (!FRONT_FACING) {
        NORMAL *= -1.0;
    }

    SPECULAR = 0.5;
    ROUGHNESS = clamp(1.0 - (sclamp(current_wind, 0.8) * grass_roughness), 0.2, 1.0);
}