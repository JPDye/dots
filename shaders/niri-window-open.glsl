vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    if (coords_geo.x < 0.0 || coords_geo.x > 1.0 ||
        coords_geo.y < 0.0 || coords_geo.y > 1.0)
        return vec4(0.0);

    // Square cells: pick a cell size in pixels, derive grid from window size.
    float cell_px = 32.0;
    vec2 grid = floor(size_geo.xy / cell_px);
    grid = max(grid, vec2(1.0));

    vec2 cell  = floor(coords_geo.xy * grid);
    vec2 local = fract(coords_geo.xy * grid);

    // Wavefront from top-left.
    float t = (cell.x / grid.x + cell.y / grid.y) / 2.0;
    float d = 0.4;
    float cell_progress = clamp((niri_clamped_progress - t * (1.0 - d)) / d, 0.0, 1.0);

    // Grow from cell centre.
    vec2 dist = abs(local - 0.5);
    if (dist.x > cell_progress * 0.5 || dist.y > cell_progress * 0.5)
        return vec4(0.0);

    // Blend from cell-centre sample to real texel to avoid end-of-anim jump.
    vec2 centre     = (cell + 0.5) / grid;
    vec3 centre_geo = vec3(clamp(centre, 0.0, 1.0), 1.0);
    vec3 centre_tex = niri_geo_to_tex * centre_geo;
    vec4 mosaic     = texture2D(niri_tex, centre_tex.st);

    vec3 real_tex = niri_geo_to_tex * coords_geo;
    vec4 real     = texture2D(niri_tex, real_tex.st);

    // Crossfade: mosaic at the start, real texture as cell fills.
    vec4 color = mix(mosaic, real, cell_progress * cell_progress);

    return color;
}
