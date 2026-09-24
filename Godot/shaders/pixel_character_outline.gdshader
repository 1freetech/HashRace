shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.03, 0.04, 0.06, 1.0);
uniform float outline_size : hint_range(1.0, 4.0, 1.0) = 1.0;

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    if (current_color.a > 0.1) {
        COLOR = current_color;
    } else {
        vec2 px = TEXTURE_PIXEL_SIZE * outline_size;
        float alpha = texture(TEXTURE, UV + vec2(0.0, -px.y)).a
            + texture(TEXTURE, UV + vec2(0.0, px.y)).a
            + texture(TEXTURE, UV + vec2(-px.x, 0.0)).a
            + texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
        COLOR = alpha > 0.0 ? outline_color : vec4(0.0);
    }
}
