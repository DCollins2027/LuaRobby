shader_type spatial;
// Godot 4.x, Forward+ or Mobile renderer.
// Needs water_surface.gd on the MeshInstance3D: the script drives `water_time`
// and the ripple list. Keep the MeshInstance3D at scale (1,1,1) and no rotation;
// change the PlaneMesh size instead.

group_uniforms colors;
uniform vec4 shallow_color : source_color = vec4(0.25, 0.75, 0.80, 1.0);
uniform vec4 deep_color : source_color = vec4(0.02, 0.15, 0.30, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.00, 1.0);
uniform vec4 sss_color : source_color = vec4(0.20, 0.90, 0.70, 1.0);
uniform float absorption = 0.35;        // higher = gets dark faster with depth
uniform float edge_softness = 0.15;     // fades water out where it meets geometry
uniform float sss_strength = 0.25;      // light glow through wave crests
group_uniforms;

group_uniforms waves;
// x,y = direction, z = steepness (keep the sum below ~1), w = wavelength (meters)
uniform vec4 wave_a = vec4(1.0, 0.2, 0.20, 12.0);
uniform vec4 wave_b = vec4(0.6, 1.0, 0.16, 7.0);
uniform vec4 wave_c = vec4(-0.7, 0.5, 0.10, 3.5);
uniform vec4 wave_d = vec4(0.3, -1.0, 0.07, 2.0);
uniform float wave_strength = 0.6;
uniform float wave_speed = 0.7;
group_uniforms;

group_uniforms surface_detail;
uniform sampler2D normal_map : hint_normal, repeat_enable, filter_linear_mipmap;
uniform float normal_scale = 0.15;
uniform float normal_speed = 1.0;
uniform float normal_strength = 0.35;
uniform float roughness_water = 0.04;
uniform float refraction_strength = 0.06;
group_uniforms;

group_uniforms foam;
uniform float foam_amount = 1.0;
uniform float foam_scale = 0.8;
uniform float foam_shore_width = 0.6;
uniform float foam_crest_threshold = 0.55;
group_uniforms;

group_uniforms ripples;
uniform float ripple_speed = 2.5;
uniform float ripple_frequency = 5.0;
uniform float ripple_width = 1.2;
uniform float ripple_height = 0.08;
uniform float ripple_lifetime = 4.0;
uniform float ripple_normal_strength = 1.0;
group_uniforms;

// Set from script
uniform float water_time = 0.0;
// x,z = world position, z = start time, w = strength (0 = unused slot)
uniform vec4 impacts[8];

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

varying vec3 world_pos;
varying vec3 base_normal;
varying float crest;

// ---------- noise ----------
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

// ---------- Gerstner waves ----------
vec3 gerstner(vec4 w, vec2 p, float t, inout vec3 tangent, inout vec3 binormal, inout float amp_sum) {
	float steep = w.z * wave_strength;
	float k = TAU / w.w;
	float c = sqrt(9.8 / k) * wave_speed;
	vec2 d = normalize(w.xy);
	float f = k * (dot(d, p) - c * t);
	float a = steep / k;
	float s = sin(f);
	float co = cos(f);

	tangent += vec3(-d.x * d.x * steep * s, d.x * steep * co, -d.x * d.y * steep * s);
	binormal += vec3(-d.x * d.y * steep * s, d.y * steep * co, -d.y * d.y * steep * s);
	amp_sum += a;

	return vec3(d.x * a * co, a * s, d.y * a * co);
}

// ---------- Interactive ripples ----------
// returns (height, d/dx, d/dz)
vec3 ripples(vec2 p) {
	vec3 r = vec3(0.0);
	float w2 = ripple_width * ripple_width;
	for (int i = 0; i < 8; i++) {
		vec4 im = impacts[i];
		float age = water_time - im.z;
		if (im.w <= 0.0 || age < 0.0 || age > ripple_lifetime) {
			continue;
		}
		vec2 diff = p - im.xy;
		float dist = max(length(diff), 0.001);
		float x = dist - age * ripple_speed;
		float env = exp(-(x * x) / w2);
		float life = 1.0 - age / ripple_lifetime;
		float amp = im.w * ripple_height * life * life / (1.0 + dist * 0.5);
		float ph = x * ripple_frequency;
		float h = amp * env * sin(ph);
		float dh = amp * env * (ripple_frequency * cos(ph) - 2.0 * x / w2 * sin(ph));
		r.x += h;
		r.yz += (diff / dist) * dh;
	}
	return r;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	float amp_sum = 0.0;

	vec3 disp = vec3(0.0);
	disp += gerstner(wave_a, wp.xz, water_time, tangent, binormal, amp_sum);
	disp += gerstner(wave_b, wp.xz, water_time, tangent, binormal, amp_sum);
	disp += gerstner(wave_c, wp.xz, water_time, tangent, binormal, amp_sum);
	disp += gerstner(wave_d, wp.xz, water_time, tangent, binormal, amp_sum);

	crest = disp.y / max(amp_sum, 0.001);

	vec3 rip = ripples(wp.xz);
	VERTEX += disp + vec3(0.0, rip.x, 0.0);

	vec3 n = normalize(cross(binormal, tangent));
	base_normal = normalize((MODEL_MATRIX * vec4(n, 0.0)).xyz);
	world_pos = wp;
	NORMAL = n;
}

void fragment() {
	vec2 p = world_pos.xz;
	float t = water_time;

	// --- Surface detail normals (two scrolling layers) + ripples ---
	vec2 uv1 = p * normal_scale + vec2(0.030, 0.020) * t * normal_speed;
	vec2 uv2 = p * normal_scale * 2.3 + vec2(-0.022, 0.034) * t * normal_speed;
	vec3 n1 = texture(normal_map, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(normal_map, uv2).xyz * 2.0 - 1.0;
	vec2 detail = (n1.xy + n2.xy * 0.6) * normal_strength;

	vec3 rip = ripples(p);
	vec2 bend = detail - rip.yz * ripple_normal_strength;

	vec3 nw = normalize(normalize(base_normal) + vec3(bend.x, 0.0, bend.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);

	// --- Water depth from the depth buffer ---
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 scene_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	scene_pos.xyz /= scene_pos.w;
	float water_depth = max(-scene_pos.z + VERTEX.z, 0.0);

	// --- Refraction (ignore things in front of the water) ---
	vec2 off = (VIEW_MATRIX * vec4(bend.x, 0.0, bend.y, 0.0)).xy * refraction_strength;
	vec2 ruv = SCREEN_UV + off;
	float rdepth = texture(depth_texture, ruv).r;
	vec4 rpos = INV_PROJECTION_MATRIX * vec4(ruv * 2.0 - 1.0, rdepth, 1.0);
	rpos.xyz /= rpos.w;
	if (-rpos.z < -VERTEX.z) {
		ruv = SCREEN_UV;
	}
	ruv = clamp(ruv, vec2(0.001), vec2(0.999));

	// --- Color: absorbs light and gets murkier with depth ---
	float fade = 1.0 - exp(-water_depth * absorption);
	vec3 scene = textureLod(screen_texture, ruv, fade * 3.0).rgb;
	vec3 under = mix(scene * shallow_color.rgb, deep_color.rgb, fade);

	// --- Foam: shoreline + wave crests ---
	float nz = fbm(p * foam_scale + vec2(t * 0.03, -t * 0.02));
	float sd = water_depth + (nz - 0.5) * foam_shore_width + sin(t * 1.4 - water_depth * 6.0) * 0.04;
	float shore_foam = 1.0 - smoothstep(0.0, foam_shore_width, sd);
	float crest_foam = smoothstep(foam_crest_threshold, foam_crest_threshold + 0.2, crest + (nz - 0.5) * 0.4);
	float speckle = smoothstep(0.30, 0.65, fbm(p * foam_scale * 2.5 - vec2(t * 0.05)));
	float foam = clamp(shore_foam * (0.45 + 0.55 * speckle) + crest_foam * speckle, 0.0, 1.0) * foam_amount;

	// --- Final shading ---
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 5.0);
	vec3 sss = sss_color.rgb * pow(clamp(crest, 0.0, 1.0), 2.0) * sss_strength;

	ALBEDO = mix(deep_color.rgb * 0.15, foam_color.rgb, foam);
	EMISSION = mix(under * (1.0 - fresnel * 0.6) + sss, foam_color.rgb * 0.35, foam);
	ROUGHNESS = mix(roughness_water, 0.9, foam);
	SPECULAR = 0.6;
	METALLIC = 0.0;
	ALPHA = clamp(max(water_depth / edge_softness, foam), 0.0, 1.0);
}
