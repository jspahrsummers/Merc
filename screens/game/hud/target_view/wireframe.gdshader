shader_type spatial;

render_mode unshaded, wireframe;

uniform vec4 wireframe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float wireframe_thickness : hint_range(0.0, 10.0) = 1.0;
uniform float wireframe_smoothness : hint_range(0.0, 10.0) = 1.0;

varying vec3 barycentric_coords;

void vertex() {
    // Calculate barycentric coordinates
    float base = float(VERTEX_ID % 3);
    barycentric_coords = vec3(0.0);
    barycentric_coords[int(base)] = 1.0;
}

void fragment() {
    // Calculate the minimum distance to an edge
    vec3 deltas = fwidth(barycentric_coords);
    vec3 smoothing = deltas * wireframe_smoothness;
    vec3 thickness = deltas * wireframe_thickness;
    
    vec3 barycentric = smoothstep(thickness, thickness + smoothing, barycentric_coords);
    float min_distance = min(min(barycentric.x, barycentric.y), barycentric.z);
    
    // Mix the wireframe color with transparency based on the distance
    ALBEDO = wireframe_color.rgb;
    ALPHA = 1.0 - min_distance;
}
