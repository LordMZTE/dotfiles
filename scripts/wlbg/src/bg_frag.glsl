#version 300 es

precision highp float;

uniform float time;

in vec2 fragCoord;

out vec4 fragColor;

// shader: https://www.shadertoy.com/view/fljSDW

float sq(float x) {
    return x*x;
}

void main() {
    vec2 u = fragCoord;
    vec4 o = vec4(0);
    vec2 R = vec2(1);
    ivec4 b = ivec4(o -= o);                   // Initialize b=0
    float t = .1*time, B, h, z;
    vec4 g;

    u =
        (5. + cos(t) * 1.5) *                        // * Camera push in/out 
        (u+u)/R.y                            //   Center coordinates
        * mat2( cos( vec4(0,33,55,0) - .1*t))  // * Rotate camera
    ;

    z = (h = cos(B = floor(atan(u.x, u.y) * 2e2))) / dot(u,u);  //Variables for Rain

    for (; (b.x^b.y^b.z)%199 > b.z-16 ; )        // XOR function for towers
        g += pow(vec4(0., 0., 0., .5*u + .1*sin(t/.1+(o.a*.03)+3.*u) ),g-g+18.), // * Ground ghosts
            b = ivec4(u * o.a + 2e2
                      + vec2(7,30)*t                 // * Move camera (x,y)
                      , o+=.1 );                     // Increment layer

    o =
        //o.a < 8.1 ? .1+sin(t/.1)*vec4(b%32 & b.x%9 & b.z%9) :  // * Blinking lights
        o/80. - .02 *                                          // * Distance fog
        vec4(b%2)                                              // * Building colors
        + .2*(o.a > 17. ? vec4( int(.5+sin(float(b.x/2 + b.y + 2*b.z))) & b.x & b.y & int(.5+sin(4.*o.a-3.4)) ) : g-g) // * Windows
        + (o.a > 50. ? g*vec4(.02,.1,1,0) : g-g)               // * Ground ghosts
        + vec4(1, 0, 0, .06)*sin(g)            // * Moving fog
        + .01*max(exp(fract(h * B - z + t+t) * -1e2) / z,0.)   // * Rain
    ;

    o *= vec4(0.6, 0, 0, 1.0);

    fragColor = o;
}
