float easeOutQuint(float t) {
    return 1.0 - pow(1.0 - t, 5.0);
}

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float p = easeOutQuint(1.0 - niri_clamped_progress);
    vec2 uv = coords_geo.xy;
    vec2 centered_uv = uv - 0.5;
    float aspect = size_geo.x / size_geo.y;
    centered_uv.x *= aspect;
    float d = length(centered_uv) * 2.0;
    float max_radius = length(vec2(aspect, 1.0));
    float current_radius = p * max_radius;
    float blur = 0.05;
    float content_mask = 1.0 - smoothstep(current_radius - blur, current_radius, d);
    float ring_thickness = 0.25 * (1.0 - p);
    float ring_mask = smoothstep(current_radius - blur - ring_thickness, current_radius - blur, d)
                    - smoothstep(current_radius, current_radius + blur, d);
    ring_mask *= (1.0 - p) * 1.5;
    ring_mask = clamp(ring_mask, 0.0, 1.0);
    float angle = atan(centered_uv.y, centered_uv.x);
    vec3 neon_color = 0.5 + 0.5 * cos(angle * 2.0 + p * 15.0 + vec3(0.0, 2.0, 4.0));
    vec2 tex_uv = (uv - 0.5) * (1.0 + (1.0 - p) * 0.3) + 0.5;
    vec3 modified_geo = vec3(tex_uv, coords_geo.z);
    vec3 coords_tex = niri_geo_to_tex * modified_geo;
    vec4 oColor = texture2D(niri_tex, coords_tex.st);
    vec4 final_color = (oColor * content_mask) + (vec4(neon_color, 1.0) * ring_mask);
    return final_color;
}
