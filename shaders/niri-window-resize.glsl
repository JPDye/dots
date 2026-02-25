// Exponential Easing
float easeInExpo(float t) {
    return t == 0.0 ? 0.0 : pow(2.0, 10.0 * (t - 1.0));
}
float easeOutExpo(float t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}
float easeInOutExpo(float t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;
    return t < 0.5 ? 0.5 * pow(2.0, 20.0 * t - 10.0) : 1.0 - 0.5 * pow(2.0, -20.0 * t + 10.0);
}
// Sine Easing
float easeInSine(float t) {
    return 1.0 - cos((t * 3.141592653589793) / 2.0);
}
float easeOutSine(float t) {
    return sin((t * 3.141592653589793) / 2.0);
}
float easeInOutSine(float t) {
    return -0.5 * (cos(3.141592653589793 * t) - 1.0);
}
// Quartic Easing
float easeInQuart(float t) {
    return t * t * t * t;
}
float easeOutQuart(float t) {
    float f = t - 1.0;
    return 1.0 - f * f * f * f;
}
float easeInOutQuart(float t) {
    return t < 0.5 ? 8.0 * t * t * t * t : 1.0 - 8.0 * (t - 1.0) * (t - 1.0) * (t - 1.0) * (t - 1.0);
}

vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {

    float p = niri_clamped_progress;
    vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;

    float distance = 0.0075;

    vec4 outColor = vec4(0.0);

    vec2 rXY = mix(
        vec2(-distance),
        vec2(0.0),
        easeInQuart(p)
    );

    vec2 gXY = mix(
        vec2(0.0,0.0),
        vec2(0.0),
        easeInQuart(p)
    );

    vec2 bXY = mix(
        vec2(distance),
        vec2(0.0),
        easeInSine(p)
    );

    outColor.r = texture2D(niri_tex_next, coords_tex_next.st + rXY).r;
    outColor.g = texture2D(niri_tex_next, coords_tex_next.st + gXY).g;
    outColor.b = texture2D(niri_tex_next, coords_tex_next.st + bXY).b;
    outColor.a = texture2D(niri_tex_next, coords_tex_next.st ).a;

    return outColor;
}
