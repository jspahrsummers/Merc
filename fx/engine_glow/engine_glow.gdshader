shader_type spatial;
render_mode ambient_light_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float strength = 2.0;

void fragment() {
    float dist = distance(UV, vec2(0.5));

    ALBEDO *= color.rgb;
    ALPHA *= smoothstep(color.a, 0.0, dist * 2.0);
    EMISSION += color.rgb * strength;
}
