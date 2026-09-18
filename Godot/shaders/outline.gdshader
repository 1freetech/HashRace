shader_type canvas_item;

// Adapted from the MIT-licensed GDQuest 2D builder outline concept.
uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(0.23, 1.0, 0.50, 1.0);
uniform float thickness : hint_range(0.0, 4.0) = 1.0;

void fragment() {
    vec4 source = texture(TEXTURE, UV) * COLOR;
    if (!enabled || thickness <= 0.0) {
        COLOR = source;
        return;
    }

    vec2 px = TEXTURE_PIXEL_SIZE * thickness;
    float nearby = 0.0;
    nearby = max(nearby, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
    nearby = max(nearby, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
    nearby = max(nearby, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
    nearby = max(nearby, texture(TEXTURE, UV - vec2(0.0, px.y)).a);

    if (source.a < 0.05 && nearby > 0.05) {
        COLOR = outline_color;
    } else {
        COLOR = source;
    }
}
