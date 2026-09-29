vec4 resize_color(vec3 coords_geo, vec3 size_geo) {
    vec2 uv = coords_geo.xy;
    float p = sin(niri_clamped_progress * 3.14159);
    float sweep = sin(uv.x * 15.0 + uv.y * 15.0 - niri_clamped_progress * 20.0);
    vec3 holo_color = 0.5 + 0.5 * cos(sweep + vec3(0.0, 1.5, 3.0));
    vec3 coords_tex_next = niri_geo_to_tex_next * coords_geo;
    vec4 oColor = texture2D(niri_tex_next, coords_tex_next.st);
    vec4 color_overlay = vec4(holo_color, 1.0) * p * 0.15;
    return oColor + color_overlay;
}
