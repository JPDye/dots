vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float p = 1.0 - niri_clamped_progress;
    vec2 uv = coords_geo.xy;
    float settle = 1.0 - p;
    float settle_curve = pow(settle, 3.0);
    vec2 fluid_uv = uv * 6.0;
    float time = p * -12.0; // Reverse flow direction
    for (int i = 1; i < 4; i++) {
        float fi = float(i);
        fluid_uv.x += (0.6 / fi) * sin(fi * fluid_uv.y + time);
        fluid_uv.y += (0.6 / fi) * cos(fi * fluid_uv.x + time);
    }
    vec2 wobbly_uv = uv;
    wobbly_uv.x += sin(fluid_uv.y) * 0.06 * settle_curve;
    wobbly_uv.y += cos(fluid_uv.x) * 0.06 * settle_curve;
    vec2 pixel_pos = (wobbly_uv - 0.5) * size_geo.xy;
    vec2 box_size = (size_geo.xy * 0.5) * (p * 1.15);
    float corner_radius = 16.0;
    float radius = min(corner_radius, min(box_size.x, box_size.y));
    vec2 q = abs(pixel_pos) - box_size + vec2(radius);
    float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    float edge_blur = mix(15.0, 1.0, p);
    float alpha_mask = 1.0 - smoothstep(-edge_blur, edge_blur, dist);
    vec2 refraction = vec2(sin(fluid_uv.x), cos(fluid_uv.y)) * 0.03 * settle_curve;
    vec2 tex_uv = uv + (refraction * alpha_mask);
    vec3 coords_tex = niri_geo_to_tex * vec3(tex_uv, coords_geo.z);
    vec4 oColor = texture2D(niri_tex, coords_tex.st);
    vec4 final_color = oColor * alpha_mask;
    float caustic = max(0.0, sin(fluid_uv.x - fluid_uv.y));
    caustic = pow(caustic, 3.0);
    vec3 water_tint = vec3(0.5, 0.9, 1.0);
    final_color.rgb += water_tint * caustic * alpha_mask * settle_curve * 1.2;
    return final_color;
}
