vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    if (coords_geo.x < 0.0 || coords_geo.x > 1.0 ||
        coords_geo.y < 0.0 || coords_geo.y > 1.0)
        return vec4(0.0);

    float cell_px = 32.0;
    vec2 grid = floor(size_geo.xy / cell_px);
    grid = max(grid, vec2(1.0));

    vec2 cell  = floor(coords_geo.xy * grid);
    vec2 local = fract(coords_geo.xy * grid);

    // Wavefront from bottom-right.
    float t = ((grid.x - 1.0 - cell.x) / grid.x + (grid.y - 1.0 - cell.y) / grid.y) / 2.0;
    float d = 0.4;
    float cell_progress = clamp((niri_clamped_progress - t * (1.0 - d)) / d, 0.0, 1.0);

    float scale = 1.0 - cell_progress;
    vec2 dist = abs(local - 0.5);
    if (dist.x > scale * 0.5 || dist.y > scale * 0.5)
        return vec4(0.0);

    // Crossfade from real texture to mosaic as cell shrinks.
    vec2 centre     = (cell + 0.5) / grid;
    vec3 centre_geo = vec3(clamp(centre, 0.0, 1.0), 1.0);
    vec3 centre_tex = niri_geo_to_tex * centre_geo;
    vec4 mosaic     = texture2D(niri_tex, centre_tex.st);

    vec3 real_tex = niri_geo_to_tex * coords_geo;
    vec4 real     = texture2D(niri_tex, real_tex.st);

    vec4 color = mix(real, mosaic, cell_progress * cell_progress);

    return color;
}
