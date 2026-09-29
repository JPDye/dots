vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
    vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;
    vec4 color = texture2D(niri_tex_next, coords_tex_next.st);
    return color;
}
