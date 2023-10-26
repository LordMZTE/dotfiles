#version 300 es

precision mediump float;

uniform float time;
uniform vec2 offset;

in vec2 fragCoord;

/* "Quasar" by @kishimisu (2023) - https://www.shadertoy.com/view/msGyzc
   449 => 443 chars thanks to @Xor
   
   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
*/

#define r(a) mat2(cos(a + asin(vec4(0,1,-1,0)))),
#define X(p) p *= r(round(atan(p.x, p.y) * 4.) / 4.)

void main() {
    vec2 F = fragCoord - offset + .5;
    vec3 p, R = vec3(1.);
    float i, t, d, a, b, T = time * .5 + .5;

    vec4 O = vec4(0.);
             
    for(O  *= i; i++ < 44.;
        O  += .04 * (1. + cos(a + t*.3 - T*.8 + vec4(0,1,2,0))) 
                  / (1. + abs(d)*30.) )
        
        p = t * normalize(vec3(F+F-R.xy, R.y)),
        p.z  -= 4.,
        p.xz *= r(T/4.)
        p.yz *= r(sin(T/4.)*.5)
        X(p.zx)   a = p.x,
        X(p.yx)
        p.x = mod(b = p.x - T, .5) - .25,
        
        t  += d = length(p) - (2. - a - smoothstep(b+2., b, T)*30.)
                            * (cos(T/6.+1.)+1.) / 2e2;

    gl_FragColor = O;
}

