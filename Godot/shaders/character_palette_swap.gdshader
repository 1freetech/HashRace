shader_type canvas_item;

// Hash Race high-density palette swap. A base sheet can reserve four 3-color
// ramps (skin, hair, suit, accent). Recoloring all shadow/mid/high values keeps
// the hand-drawn shading instead of flattening each material to one color.

uniform float tolerance : hint_range(0.0, 0.12, 0.001) = 0.018;

uniform vec4 key_skin_dark : source_color = vec4(0.0, 0.45, 0.0, 1.0);
uniform vec4 key_skin_mid  : source_color = vec4(0.0, 0.75, 0.0, 1.0);
uniform vec4 key_skin_high : source_color = vec4(0.2, 1.0, 0.2, 1.0);
uniform vec4 key_hair_dark : source_color = vec4(0.0, 0.0, 0.45, 1.0);
uniform vec4 key_hair_mid  : source_color = vec4(0.0, 0.0, 0.75, 1.0);
uniform vec4 key_hair_high : source_color = vec4(0.2, 0.2, 1.0, 1.0);
uniform vec4 key_suit_dark : source_color = vec4(0.45, 0.0, 0.0, 1.0);
uniform vec4 key_suit_mid  : source_color = vec4(0.75, 0.0, 0.0, 1.0);
uniform vec4 key_suit_high : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform vec4 key_accent_dark : source_color = vec4(0.45, 0.32, 0.0, 1.0);
uniform vec4 key_accent_mid  : source_color = vec4(0.78, 0.58, 0.0, 1.0);
uniform vec4 key_accent_high : source_color = vec4(1.0, 0.88, 0.2, 1.0);

uniform vec4 target_skin_dark : source_color = vec4(0.27, 0.14, 0.09, 1.0);
uniform vec4 target_skin_mid  : source_color = vec4(0.55, 0.31, 0.20, 1.0);
uniform vec4 target_skin_high : source_color = vec4(0.78, 0.50, 0.33, 1.0);
uniform vec4 target_hair_dark : source_color = vec4(0.03, 0.04, 0.06, 1.0);
uniform vec4 target_hair_mid  : source_color = vec4(0.09, 0.10, 0.15, 1.0);
uniform vec4 target_hair_high : source_color = vec4(0.22, 0.21, 0.28, 1.0);
uniform vec4 target_suit_dark : source_color = vec4(0.05, 0.07, 0.09, 1.0);
uniform vec4 target_suit_mid  : source_color = vec4(0.15, 0.19, 0.22, 1.0);
uniform vec4 target_suit_high : source_color = vec4(0.36, 0.42, 0.44, 1.0);
uniform vec4 target_accent_dark : source_color = vec4(0.0, 0.30, 0.12, 1.0);
uniform vec4 target_accent_mid  : source_color = vec4(0.10, 0.82, 0.30, 1.0);
uniform vec4 target_accent_high : source_color = vec4(0.48, 1.0, 0.58, 1.0);

bool near_key(vec3 pixel, vec3 key) {
    return distance(pixel, key) <= tolerance;
}

void fragment() {
    vec4 c = texture(TEXTURE, UV);
    if (c.a <= 0.001) {
        COLOR = c;
        return;
    }

    vec3 p = c.rgb;
    if (near_key(p, key_skin_dark.rgb)) c.rgb = target_skin_dark.rgb;
    else if (near_key(p, key_skin_mid.rgb)) c.rgb = target_skin_mid.rgb;
    else if (near_key(p, key_skin_high.rgb)) c.rgb = target_skin_high.rgb;
    else if (near_key(p, key_hair_dark.rgb)) c.rgb = target_hair_dark.rgb;
    else if (near_key(p, key_hair_mid.rgb)) c.rgb = target_hair_mid.rgb;
    else if (near_key(p, key_hair_high.rgb)) c.rgb = target_hair_high.rgb;
    else if (near_key(p, key_suit_dark.rgb)) c.rgb = target_suit_dark.rgb;
    else if (near_key(p, key_suit_mid.rgb)) c.rgb = target_suit_mid.rgb;
    else if (near_key(p, key_suit_high.rgb)) c.rgb = target_suit_high.rgb;
    else if (near_key(p, key_accent_dark.rgb)) c.rgb = target_accent_dark.rgb;
    else if (near_key(p, key_accent_mid.rgb)) c.rgb = target_accent_mid.rgb;
    else if (near_key(p, key_accent_high.rgb)) c.rgb = target_accent_high.rgb;

    COLOR = c;
}
