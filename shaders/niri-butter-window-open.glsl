vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;
    float y_offset = mix(0.15, 0.0, p);
    float scale = mix(0.85, 1.0, p);
    vec2 uv = coords_geo.xy;
    vec2 centered = uv - 0.5;
    centered.y -= y_offset;
    centered /= scale;
    vec2 tex_uv = centered + 0.5;
    vec3 coords_tex = niri_geo_to_tex * vec3(tex_uv, coords_geo.z);
    vec4 oColor = texture2D(niri_tex, coords_tex.st);
    float corner_radius = 12.0;
    vec2 pixel_pos = centered * size_geo.xy;
    vec2 box_size = size_geo.xy * 0.5;
    float radius = min(corner_radius, min(box_size.x, box_size.y));
    vec2 q = abs(pixel_pos) - box_size + vec2(radius);
    float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    float mask = 1.0 - smoothstep(-0.5, 0.5, dist);
    float alpha = clamp(p * 2.0, 0.0, 1.0);
    return oColor * mask * alpha;
}
