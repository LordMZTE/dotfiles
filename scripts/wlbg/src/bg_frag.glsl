#version 430

precision highp float;

uniform float time;

in vec2 fragCoord;

out vec4 fragColor;

// shader: https://www.shadertoy.com/view/4fGBzd

void main()
{
    #define P(v, k) pow(v, k)
    float esc = 6e1, at = .25, sc = .2, it = 40.;
    vec3 hue = vec3(0, .5, 1);
    float B = 0.0, I = 0.0, e = esc, le = log2(e), k = 1. / sc;
    vec2 z = vec2(0), c = fragCoord;
    c = vec2(c.x - .5, c.y);
    int i = 0, h = int(it);
    for (; i < h && B < e;
        z = vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) * exp(.2 * cos(atan(z) * log2(1. + I) + time)) + c,
        I = float(++i),
        B = z.x * z.x + 4. * le * z.y * cos(atan(z.y, z.x) + I + time)
    );
    fragColor = i < h ?
        vec4((.5 + .5 * cos(at * cos(atan(z.y, z.x) + I + time)
                            + I * sc + time + 2. * (hue)))
                * smoothstep(1., 0., P(I, k) / P(float(h), k))
                * smoothstep(-le, le, log2(B / e)), 1) : vec4(0, 0, 0, 1);
}
