shader_type canvas_item;

// Optional fallback for imported high-resolution building sprites.
// The live v0.080 procedural buildings are redrawn on a hard grid instead.
// Use this material only when source art cannot be repainted yet.

uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 2.0;
uniform float palette_steps : hint_range(2.0, 16.0, 1.0) = 8.0;

void fragment() {
    vec2 texel_count = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    vec2 block = vec2(max(pixel_size, 1.0));
    vec2 snapped_uv = (floor(UV * texel_count / block) * block + block * 0.5) / texel_count;
    snapped_uv = clamp(snapped_uv, vec2(0.0), vec2(1.0));

    vec4 color = texture(TEXTURE, snapped_uv);
    float steps = max(palette_steps, 2.0);
    color.rgb = floor(color.rgb * steps + 0.5) / steps;
    COLOR = color;
}
