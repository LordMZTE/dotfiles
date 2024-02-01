#version 430

precision highp float;

uniform float time;

in vec2 fragCoord;

out vec4 fragColor;

// shader: https://www.shadertoy.com/view/XfXXWj

#define iResolution vec3(1.)

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(23,43,21))*.5+.5)

#define OCTAVES 6

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float cheap_star(vec2 uv, float anim) {
    uv = abs(uv);
    vec2 pos = min(uv.xy / uv.yx, anim);
    float p = (2.0 - pos.x - pos.y);
    return (2.0 + p * (p * p - 1.5)) / (uv.x + uv.y);
}

float noise(vec2 p) {
    vec2 s = floor(p);

    float a = random(s);
    float b = random(s + vec2(1.0, 0.0));
    float c = random(s + vec2(0.0, 1.0));
    float d = random(s + vec2(1.0, 1.0));

    vec2 f = smoothstep(0.0, 1.0, fract(p));

    float ab = mix(a, b, f.x);
    float cd = mix(c, d, f.x);

    float o = mix(ab, cd, f.y);

    return o;
}
#define pi    3.14159265358
#define tpi   (2.0*pi)
#define pi_6  pi/6.0

vec3 sebs_colors(float offset, float speed) {
    return 1.0 - sin(offset + speed * time * vec3(3.0, 7.0, 11.0) / pi_6);
}

float circle(vec2 uv, float angle, float radius, vec2 wiggle) {
    return 0.0025 / abs(length(uv) - radius + wiggle[0] * sin(time * 0.1) * sin(10.0 * (angle - 0.5 * time) + wiggle[1]));
}

float fractal(vec2 p) {
    float o = 0.0;
    float strength = 0.5;
    vec2 position = p;

    for (int i = 0; i < OCTAVES; i++) {
        o += noise(position) * strength;
        position *= 2.0;
        strength *= 0.5;
    }

    // attempt to fix darkness issues
    o /= 1.0 - 0.5 * pow(0.5, float(OCTAVES - 1));

    return o;
}

vec2 computeNext(vec2 current, vec2 constant) {
    float zr = (current.x * current.x) - (current.y * current.y);
    float zi = 2.0 * current.x * current.y;

    return vec2(zr, zi) + constant;
}

float mod2(vec2 z) {
    return z.x * z.x + z.y * z.y;
}

float computeIterations(vec2 z0, vec2 constant, float max_iterations) {
    vec2 zn = z0;
    float iteration = 0.;
    while (length(zn) < 2. && iteration < max_iterations) {
        zn = computeNext(zn, constant);
        iteration++;
    }

    float mod2 = length(zn);
    float smoothf = float(iteration) - log2(max(1., log2(mod2)));
    return smoothf;
}

vec3 getColor(float it, float maxIt) {
    return (vec3(it / maxIt));
}

void main() {
    vec2 C = fragCoord + vec2(.5);
    vec4 O = vec4(0);
    O = vec4(0);
    vec2 uv = (2.0 * C - iResolution.xy) / iResolution.y;
    uv *= .1;

    float max_Iterations = 80.;
    float uTime = pow(sin(time * 0.2), 3.) * .03 - 1.313;
    //float uTime = -1.313;
    uv *= sin(time * 0.2) + 2.;
    vec2 uConstant = (vec2(-abs(-sin(uTime)), (cos(uTime))));
    float color = computeIterations(uv, uConstant, max_Iterations);

    vec3 col = vec3(getColor(color, max_Iterations));
    col = vec3(pow(col.x, .7));
    col.z = 0.;

    col += vec3(0, 0, .5);
    col *= vec3(1.3, 1, 1);
    vec3 color2 = vec3(0.0);

    float angle = pi * mod(atan(uv.x, uv.y) / tpi, 1.0);

    for (float i = 1.0; i < 10.0; i++)
    {
        color2 += sebs_colors(0.0, 25.0) * circle(uv, angle + 3.0 * pi_6, i / 7.0, vec2(i, i));
    }
    vec3 natur, q, r = iResolution,
    d = normalize(vec3((C * 2. - r.xy) / r.y, 1));
    for (float i = 0., a, s, e, g = 0.;
        ++i < 110.;
        O.xyz += mix(vec3(1), H(g * .1), sin(.8)) * 1. / e / 8e3
    )
    {
        natur = g * d;
        float c23 = fractal(natur.xy);
        natur.z += time * 0.0;
        a = 30. + c23;
        natur = mod(natur - a, a * 2.) - a;
        s = 3.;
        for (int i = 0; i++ < 8; ) {
            natur = .3 - abs(natur);

            natur.x < natur.z ? natur = natur.zyx : natur;

            natur.y < natur.z ? natur = natur.zyx : natur;
            natur.z < natur.x ? natur = natur.yxz : natur;
            s *= e = 1.4 + sin(time * .234) * .1;
            natur = abs(natur) * e -
                    vec3(
                        5. + atan(time * .3 + .5 * +cos(time * .3)) * 3.,
                        80,
                        3. + atan(time * .5) * 5.
                    ) * col;
        }
        g += e = length(natur.yz) / s;
    }
    uv *= 2.0 * (cos(time * 2.0) - 2.5);

    // anim between 0.9 - 1.1
    float anim = sin(time * 12.0) * 0.1 + 1.0;

    O *= vec4(cheap_star(uv, anim) * vec3(0.55, 0.5, 0.55) * 3., 1.0);
    fragColor = O;
}
