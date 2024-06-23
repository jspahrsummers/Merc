/*
    Based on:
	魔法防御シェーダー 4 by あるる（きのもと 結衣）
	Magical Shield Shader 4 by Yui Kinomoto @arlez80

	MIT License

    Upgraded to support Godot 4 and transparency.
*/

shader_type spatial;
render_mode blend_mix, unshaded, shadows_disabled, ambient_light_disabled, depth_draw_never;

uniform vec2 speed = vec2(0.2, 0.2);
uniform vec4 barrier_color : source_color = vec4(0.05, 0.8, 1.0, 1.0);
uniform float barrier_force = 1.0;
uniform float barrier_noise_force = 0.3;
uniform float barrier_edge_softness = 0.1;
uniform sampler2D barrier_noise : hint_normal;

void fragment() {
    // Calculate rim effect
    float rim = pow(1.0 - dot(NORMAL, VIEW), 4.0) * barrier_force;

    // Generate noise
    vec2 p = texture(barrier_noise, -UV).xy + TIME * speed;
    float noise = texture(barrier_noise, p).r;
    
    // Create shield pattern
    float shield_pattern = sin(noise * 3.1415926535 * 8.0) * 0.5 + 0.5;
    shield_pattern = smoothstep(0.5 - barrier_edge_softness, 0.5 + barrier_edge_softness, shield_pattern);

    // Combine rim effect with shield pattern
    float shield_strength = rim * shield_pattern;

    // Set color and transparency
    ALBEDO = barrier_color.rgb;
    ALPHA *= shield_strength * barrier_color.a;

    // Add some emission for a glowing effect
    EMISSION = barrier_color.rgb * shield_strength * 2.0;
}
