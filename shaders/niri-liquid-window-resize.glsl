vec4 resize_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;
    float env = sin(p * 3.14159265);
    vec2 uv = coords_geo.xy;
    vec2 fluid_uv = uv * 8.0;
    float time = p * 15.0;
    for (int i = 1; i < 4; i++) {
        float fi = float(i);
        fluid_uv.x += (0.5 / fi) * sin(fi * fluid_uv.y + time);
        fluid_uv.y += (0.5 / fi) * cos(fi * fluid_uv.x + time);
    }
    vec2 refraction = vec2(sin(fluid_uv.x), cos(fluid_uv.y)) * 0.01 * env;
    vec2 tex_uv = uv + refraction;
    vec3 coords_tex_next = niri_geo_to_tex_next * vec3(tex_uv, coords_geo.z);
    vec4 oColor = texture2D(niri_tex_next, coords_tex_next.st);
    float caustic = max(0.0, sin(fluid_uv.x - fluid_uv.y));
    caustic = pow(caustic, 2.0);
    vec3 water_tint = vec3(0.5, 0.9, 1.0);
    return oColor + vec4(water_tint * caustic * env * 0.25 * oColor.a, 0.0);
}
