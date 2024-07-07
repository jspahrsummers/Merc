shader_type canvas_item;

uniform float margin = 0.0;

void fragment() {
    // Get the size of the texture
    vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
    
    // Calculate the center of the texture
    vec2 center = texture_size * 0.5;
    
    // Calculate the current pixel's distance from the center
    float distance = length(UV * texture_size - center);
    
    // Calculate the radius of the circle (half of the smallest dimension)
    float radius = min(texture_size.x, texture_size.y) * 0.5;
    
    // Sample the texture
    vec4 color = texture(TEXTURE, UV);
    
    // If the distance is greater than the radius, discard the pixel
    if (distance > radius - margin) {
        COLOR = vec4(0.0);
    } else {
        COLOR = color;
    }
}
