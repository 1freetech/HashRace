shader_type canvas_item;
render_mode unshaded;

// Lightweight one-sample LCD/pixel-grid post effect for Godot 4.x.
// Optimized for Hash Race's 1440x900 viewport with a 360x225 default logical
// grid (exact 4x integer scale). Set 160x144 only for an intentionally
// letterboxed/authentic handheld presentation.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 target_resolution = vec2(360.0, 225.0);
uniform bool snap_source = true;
uniform float grid_intensity : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float pixel_gap : hint_range(0.0, 0.45, 0.01) = 0.08;
uniform float desaturation : hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float contrast : hint_range(0.5, 1.5, 0.01) = 0.96;
uniform float brightness : hint_range(-0.25, 0.25, 0.01) = 0.015;
uniform float effect_mix : hint_range(0.0, 1.0, 0.01) = 1.0;

vec2 snap_to_cell_center(vec2 uv, vec2 resolution) {
    return (floor(uv * resolution) + vec2(0.5)) / resolution;
}

float lcd_cell_mask(vec2 uv, vec2 resolution, float gap) {
    vec2 cell_uv = fract(uv * resolution);

    // Do not reverse smoothstep edges. edge0 >= edge1 is undefined behavior.
    vec2 enter = smoothstep(vec2(0.0), vec2(gap), cell_uv);
    vec2 leave = vec2(1.0) - smoothstep(vec2(1.0 - gap), vec2(1.0), cell_uv);
    vec2 inside = enter * leave;
    return inside.x * inside.y;
}

void fragment() {
    vec2 resolution = max(target_resolution, vec2(1.0));
    vec2 sample_uv = snap_source ? snap_to_cell_center(SCREEN_UV, resolution) : SCREEN_UV;

    // One source lookup keeps this much cheaper than multi-neighbor LCD/CRT
    // shaders while still giving Hash Race an obvious hardware-pixel structure.
    vec4 original = texture(screen_texture, SCREEN_UV);
    vec4 sampled = snap_source ? texture(screen_texture, sample_uv) : original;

    float luma = dot(sampled.rgb, vec3(0.299, 0.587, 0.114));
    vec3 lcd = mix(sampled.rgb, vec3(luma), desaturation);
    lcd = (lcd - vec3(0.5)) * contrast + vec3(0.5 + brightness);
    lcd = clamp(lcd, vec3(0.0), vec3(1.0));

    float cell = lcd_cell_mask(SCREEN_UV, resolution, pixel_gap);
    float grid = mix(1.0 - grid_intensity, 1.0, cell);
    lcd *= grid;

    vec3 final_rgb = mix(original.rgb, lcd, effect_mix);
    COLOR = vec4(final_rgb, original.a);
}
