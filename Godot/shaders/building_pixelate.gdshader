shader_type canvas_item;
render_mode unshaded;

// Fallback for imported high-resolution building art.
// Preferred path remains source art authored on Hash Race's hard pixel grid.
//
// Refactor notes:
// - snaps sampling to the center of source texel blocks
// - clamps away from texture edges to prevent bleed
// - uses exactly N palette levels instead of accidentally producing N+1
// - adds optional deterministic ordered-style dithering without extra samples

uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 2.0;
uniform float palette_steps : hint_range(2.0, 16.0, 1.0) = 8.0;
uniform float dither_strength : hint_range(0.0, 1.0, 0.05) = 0.15;

float pixel_dither(vec2 block_coord) {
    // Tiny deterministic 2x2 threshold pattern. It is stable in world art and
    // avoids temporal shimmer because it is based only on source block index.
    vec2 p = mod(block_coord, 2.0);
    float index = p.x + p.y * 2.0;
    if (index < 0.5) {
        return 0.125;
    }
    if (index < 1.5) {
        return 0.625;
    }
    if (index < 2.5) {
        return 0.875;
    }
    return 0.375;
}

void fragment() {
    vec2 source_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    vec2 block = vec2(max(pixel_size, 1.0));
    vec2 source_px = UV * source_size;
    vec2 block_coord = floor(source_px / block);

    // Sample the middle of each block. SameBoy's texel-center strategy is the
    // key idea here: sampling boundaries creates unstable or blended results.
    vec2 snapped_px = block_coord * block + block * 0.5;
    vec2 snapped_uv = snapped_px / source_size;
    vec2 half_texel = TEXTURE_PIXEL_SIZE * 0.5;
    snapped_uv = clamp(snapped_uv, half_texel, vec2(1.0) - half_texel);

    vec4 source_color = texture(TEXTURE, snapped_uv) * COLOR;

    float levels = max(palette_steps, 2.0);
    float denominator = levels - 1.0;
    float threshold = pixel_dither(block_coord) - 0.5;
    vec3 shifted = clamp(
        source_color.rgb + vec3(threshold * dither_strength / denominator),
        vec3(0.0),
        vec3(1.0)
    );
    source_color.rgb = floor(shifted * denominator + 0.5) / denominator;

    COLOR = source_color;
}
