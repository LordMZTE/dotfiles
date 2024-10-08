#version 430

precision highp float;

uniform float time;

in vec2 fragCoord;

out vec4 fragColor;

// shader: https://www.shadertoy.com/view/43lfRN

#define iterations 15
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

#define zoom   0.800
#define tile   0.850
#define speed  0.000

#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

float focus = 0.;
float focus2 = 0.;
#define pi  3.14159265

float random(vec2 p) {
    //a random modification of the one and only random() func
    return fract(sin(dot(p, vec2(12., 90.))) * 1e6);
}

float noise(vec3 p) {
    vec2 i = floor(p.yz);
    vec2 f = fract(p.yz);
    float a = random(i + vec2(0., 0.));
    float b = random(i + vec2(1., 0.));
    float c = random(i + vec2(0., 1.));
    float d = random(i + vec2(1., 1.));
    vec2 u = f * f * (3. - 2. * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
}

const int octaves = 6;

vec2 random2(vec2 st) {
    return vec2(0);
}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(dot(random2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
            dot(random2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
        mix(dot(random2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
            dot(random2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

float fbm1(in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
            -sin(0.5), cos(0.50));
    for (int i = 0; i < octaves; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.4;
    }
    return v;
}

float pattern(vec2 uv, float time, inout vec2 q, inout vec2 r) {
    q = vec2(fbm1(uv * .1 + vec2(0.0, 0.0)),
            fbm1(uv + vec2(5.2, 1.3)));

    r = vec2(fbm1(uv * .1 + 4.0 * q + vec2(1.7 - time / 2., 9.2)),
            fbm1(uv + 4.0 * q + vec2(8.3 - time / 2., 2.8)));

    vec2 s = vec2(fbm1(uv + 5.0 * r + vec2(21.7 - time / 2., 90.2)),
            fbm1(uv * .05 + 5.0 * r + vec2(80.3 - time / 2., 20.8))) * .25;

    return fbm1(uv * .05 + 4.0 * s);
}

vec2 getScreenSpace() {
    vec2 uv = (gl_FragCoord.xy - 0.5);

    return uv;
}
float fbm3d(vec3 p) {
    float v = 0.;
    float a = .5;
    vec3 shift = vec3(focus - focus2); //play with this

    float angle = pi / 7.;
    float cc = cos(angle), ss = sin(angle);
    mat3 rot = mat3(cc, 0., ss,
            0., 1., 0.,
            -ss, 0., cc);

    for (float i = 0.; i < 4.; i++) {
        v += a * noise(p);
        p = rot * p * 2. + shift;
        a *= .6 * (1. + 4. * (focus + focus2)); //changed from the usual .5
    }
    return v;
}

void mainVR(out vec4 fragColor, in vec2 fragCoord, in vec3 ro, in vec3 rd)
{
    vec3 dir = rd;
    vec3 from = ro;

    //volumetric rendering
    float s = 0.1, fade = 1.;
    vec3 v = vec3(0.);
    for (int r = 0; r < volsteps; r++) {
        vec3 p = from + s * dir * .5;
        p = abs(vec3(tile) - mod(p, vec3(tile * 2.))); // tiling fold
        float pa, a = pa = 0.;
        for (int i = 0; i < iterations; i++) {
            p = abs(p) / dot(p, p) - formuparam;
            p.xy *= mat2(cos(time * 0.03), sin(time * 0.03), -sin(time * 0.03), cos(time * 0.03)); // the magic formula
            a += abs(length(p) - pa); // absolute sum of average change
            pa = length(p);
        }
        float dm = max(0., darkmatter - a * a * .001); //dark matter
        a *= a * a; // add contrast
        if (r > 6) fade *= 1.2 - dm; // dark matter, don't render near
        //v+=vec3(dm,dm*.5,0.);
        v += fade;
        v += vec3(s, s * s, s * s * s * s) * a * brightness * fade; // coloring based on distance
        fade *= distfading; // distance fading
        s += stepsize;
    }
    v = mix(vec3(length(v)), v, saturation); //color adjust
    fragColor = vec4(v * .03, 1.);
}

float happy_star(vec2 uv, float anim)
{
    uv = abs(uv);
    vec2 pos = min(uv.xy / uv.yx, anim);
    float p = (2.0 - pos.x - pos.y);
    return (2.0 + p * (p * p - 1.5)) / (uv.x + uv.y);
}

#define O(x,a,b) (smoothstep(0., 1., cos(x*6.2832)*.5+.5)*(a-b)+b)  // oscillate x between a & b
#define A(v) mat2(cos((v*3.1416) + vec4(0, -1.5708, 1.5708, 0)))          // rotate
#define s(a, b) c = max(c, .006/abs(L( u, K(a, v, h), K(b, v, h) )+.02)); // segment

// line
float L(vec2 p, vec3 A, vec3 B)
{
    vec2 a = A.xy,
    b = B.xy - a;
    p -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0., 1.);
    return length(p - b * h) + .01 * mix(A.z, B.z, h);
}

// cam
vec3 K(vec3 p, mat2 v, mat2 h)
{
    p.zy *= v; // pitch
    p.zx *= h; // yaw
    p *= 5. / (p.z + 5.); // perspective view
    return p;
}
void main()
{
    //get coords and direction
    vec2 uv = fragCoord.xy + 0.5;
    vec3 dir = vec3(uv * zoom, 1.);

    float coord_scale = 1.;

    vec2 mm = vec2(2. * time);

    vec2 uv2 = (2. * fragCoord + 0.5);
    uv2 *= coord_scale;
    mm *= coord_scale;

    vec3 rd = normalize(vec3(uv2, -2.));
    vec3 ro = vec3(0);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv3 = getScreenSpace();

    float time3 = time / 10.;

    mat2 rot = mat2(cos(time3 / 10.), sin(time3 / 10.),
            -sin(time3 / 10.), cos(time3 / 10.));

    float t3 = time * .1 + ((.25 + .05 * sin(time * .1)) / (length(uv.xy) + .07)) * 2.2;
    float si = sin(t3);
    float co = cos(t3);
    mat2 ma = mat2(co, si, -si, co);
    uv3 *= ma;
    uv3 = rot * uv3;
    uv3 *= 0.9 * (sin(time)) + 3.;
    uv3.x -= time / 5.;

    vec2 q = vec2(0., 0.);
    vec2 r = vec2(0., 0.);

    float _pattern = 0.;

    _pattern = pattern(uv3, time, q, r);

    vec3 colour = vec3(_pattern) * 2.;
    colour.r -= dot(q, r) * 15.;
    colour = mix(colour, vec3(pattern(r, time, q, r), dot(q, r) * 15., -0.1), .5);
    colour -= q.y * 1.5;
    colour = mix(colour, vec3(.2, .2, .2), (clamp(q.x, -1., 0.)) * 3.);
    ro.z -= time * .4;

    vec3 q2;

    float i = 0., stepsize2 = 1.;
    vec3 cc = vec3(0);
    vec3 p = ro;
    for (; i < 20.; i++) {
        p += rd * stepsize2;

        focus = length(p - vec3(8. * mm.x, 6. * mm.y, ro.z - 20.));
        focus = exp(-focus / 7.);

        focus2 = length(p - vec3(-8. * mm.x, -6. * mm.y, ro.z - 20.));
        focus2 = exp(-focus2 / 7.);

        q2.x = fbm3d(p);
        q2.y = fbm3d(p.yzx);
        q2.z = fbm3d(p.zxy);

        float f = fbm3d(p + q2);

        cc += q2 * f * exp(-i * i * 1000.);
    }

    cc.r += 3. * focus * focus;
    cc.g += 2. * focus;
    cc.b += 2.5 * focus2;
    cc.r += 3. * focus2;
    cc /= 2.;
    vec2 U = fragCoord + 0.5;
    vec2 R = vec2(1),
    u = (U - R / 2.) / R.y * 5.,
    m = (time * 200. - R) / R.y;

    float t = time / 180.,
    o = t * 8., // shape shift timer
    x, y, z;

    mat2 v = A(m.y), // pitch
    h = A(m.x); // yaw

    vec3 c = vec3(0), p3;

    if (mod(o, 4.) < 2.) // swap between polyhedra
    {
        p3 = vec3(.382, -.618, 1); // dodecahedron
        //p = vec3(1, .618, .382);  // stellated icosahedron
        x = p3.x;
        y = p3.y;
        z = p3.z;

        s(vec3(-z, x, 0), vec3(-z, -x, 0))
        s(vec3(z, x, 0), vec3(z, -x, 0))
        s(vec3(-z, x, 0), vec3(y, -y, -y))
        s(vec3(-z, x, 0), vec3(y, -y, y))
        s(vec3(-z, -x, 0), vec3(y, y, -y))
        s(vec3(-z, -x, 0), vec3(y, y, y))
        s(vec3(z, x, 0), vec3(-y, -y, y))
        s(vec3(z, x, 0), vec3(-y, -y, -y))
        s(vec3(z, -x, 0), vec3(-y, y, y))
        s(vec3(z, -x, 0), vec3(-y, y, -y))
        s(vec3(x, 0, -z), vec3(-x, 0, -z))
        s(vec3(x, 0, z), vec3(-x, 0, z))
        s(vec3(x, 0, -z), vec3(-y, y, y))
        s(vec3(x, 0, -z), vec3(-y, -y, y))
        s(vec3(-x, 0, -z), vec3(y, -y, y))
        s(vec3(-x, 0, -z), vec3(y, y, y))
        s(vec3(x, 0, z), vec3(-y, y, -y))
        s(vec3(x, 0, z), vec3(-y, -y, -y))
        s(vec3(-x, 0, z), vec3(y, y, -y))
        s(vec3(-x, 0, z), vec3(y, -y, -y))
        s(vec3(0, z, x), vec3(0, z, -x))
        s(vec3(0, -z, x), vec3(0, -z, -x))
        s(vec3(0, z, x), vec3(y, -y, -y))
        s(vec3(0, z, x), vec3(-y, -y, -y))
        s(vec3(0, z, -x), vec3(y, -y, y))
        s(vec3(0, z, -x), vec3(-y, -y, y))
        s(vec3(0, -z, x), vec3(y, y, -y))
        s(vec3(0, -z, x), vec3(-y, y, -y))
        s(vec3(0, -z, -x), vec3(-y, y, y))
        s(vec3(0, -z, -x), vec3(y, y, y))
    }
    else
    {
        //o += .5;
        p3 = vec3(0,
                O(o, 1., .618),
                O(o, -.618, 1.));

        x = p3.x;
        y = p3.y;
        z = p3.z;

        s(vec3(-y, z, 0), vec3(0, -y, -z))
        s(vec3(-y, z, 0), vec3(0, -y, z))
        s(vec3(y, z, 0), vec3(0, -y, -z))
        s(vec3(y, z, 0), vec3(0, -y, z))
        s(vec3(-y, -z, 0), vec3(0, y, -z))
        s(vec3(-y, -z, 0), vec3(0, y, z))
        s(vec3(y, -z, 0), vec3(0, y, -z))
        s(vec3(y, -z, 0), vec3(0, y, z))
        s(vec3(-y, z, 0), vec3(z, 0, -y))
        s(vec3(-y, z, 0), vec3(z, 0, y))
        s(vec3(y, z, 0), vec3(-z, 0, -y))
        s(vec3(y, z, 0), vec3(-z, 0, y))
        s(vec3(-y, -z, 0), vec3(z, 0, -y))
        s(vec3(-y, -z, 0), vec3(z, 0, y))
        s(vec3(y, -z, 0), vec3(-z, 0, -y))
        s(vec3(y, -z, 0), vec3(-z, 0, y))
        s(vec3(y, z, 0), vec3(y, -z, 0))
        s(vec3(-y, -z, 0), vec3(-y, z, 0))
        s(vec3(0, -y, -z), vec3(0, -y, z))
        s(vec3(0, y, -z), vec3(0, y, z))
        s(vec3(0, y, -z), vec3(z, 0, y))
        s(vec3(0, y, -z), vec3(-z, 0, y))
        s(vec3(0, -y, -z), vec3(z, 0, y))
        s(vec3(0, -y, -z), vec3(-z, 0, y))
        s(vec3(-z, 0, -y), vec3(z, 0, -y))
        s(vec3(-z, 0, y), vec3(z, 0, y))
        s(vec3(-z, 0, -y), vec3(0, y, z))
        s(vec3(-z, 0, -y), vec3(0, -y, z))
        s(vec3(z, 0, -y), vec3(0, y, z))
        s(vec3(z, 0, -y), vec3(0, -y, z))
    }
    c *= pow(O(t * 4., 0., 1.), .1); // darken at shape swap
    vec3 from = vec3(1., .5, 0.5) + cc * colour + c;

    mainVR(fragColor, fragCoord + 0.5, from, dir);
    uv *= 2.0 * (cos(time * 2.0) - 2.5); // scale
    float anim = sin(time * 12.0) * 0.1 + 1.0; // anim between 0.9 - 1.1
    fragColor *= vec4(happy_star(rd.xy, anim) * vec3(0.35, 0.2, 0.35) * 0.2, 1.0);
    fragColor += vec4(cc * c * 10., 1.);
}
