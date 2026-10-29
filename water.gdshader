shader_type spatial;

uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.8, 0.6);
uniform float wave_speed = 1.0;
uniform float wave_height = 0.2;
uniform float wave_scale = 0.5;

uniform vec2 impact_pos = vec2(0.0);
uniform float impact_time = -100.0;   // TIME value when the impact happened
uniform float ring_speed = 3.0;
uniform float ring_width = 0.4;
uniform float ring_fade = 2.5;        // seconds until the ring vanishes
uniform float ripple_scale = 2.0;     // higher = smaller ripples
uniform float ripple_speed = 1.5;
uniform float ripple_strength = 0.35; // how strongly ripples bend the normals

varying float h;
varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    float a = world_pos.x * wave_scale + TIME * wave_speed;
    float b = world_pos.z * wave_scale * 1.3 + TIME * wave_speed * 0.8;

    h = sin(a) + sin(b);
    VERTEX.y += h * wave_height * 0.5;

    float dx = cos(a) * wave_scale;
    float dz = cos(b) * wave_scale * 1.3;
    NORMAL = normalize(vec3(-dx * wave_height * 0.5, 1.0, -dz * wave_height * 0.5));
}

// Gradient of a few crossing sine waves = cheap ripple normals
vec2 ripple_gradient(vec2 p, float t) {
    vec2 g = vec2(0.0);
    vec2 d1 = vec2(1.0, 0.6);
    vec2 d2 = vec2(-0.7, 1.0);
    vec2 d3 = vec2(0.4, -1.0);
    g += d1 * cos(dot(p, d1) * 3.0 + t);
    g += d2 * cos(dot(p, d2) * 4.3 - t * 1.2);
    g += d3 * cos(dot(p, d3) * 5.7 + t * 0.8);
    return g;
}

void fragment() {
    vec2 g = ripple_gradient(world_pos.xz * ripple_scale, TIME * ripple_speed);

    // Perturb the normal (in view space, so convert a small tilt)
    vec3 n = normalize(vec3(-g.x * ripple_strength * 0.1, 1.0, -g.y * ripple_strength * 0.1));
    NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

    float sparkle = length(g) * 0.02;
	// Expanding ring from the impact point
    float age = TIME - impact_time;
    float dist = distance(world_pos.xz, impact_pos);
    float ring_radius = age * ring_speed;
    float ring = smoothstep(ring_width, 0.0, abs(dist - ring_radius));
    ring *= clamp(1.0 - age / ring_fade, 0.0, 1.0);
    ALBEDO = water_color.rgb + h * 0.03 + sparkle;
    ALPHA = water_color.a;
    ROUGHNESS = 0.05;
    SPECULAR = 0.8;
}