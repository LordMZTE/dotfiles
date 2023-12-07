#version 300 es

precision highp float;

uniform float time;

in vec2 fragCoord;

out vec4 fragColor;

// shader: https://www.shadertoy.com/view/mtGBzm

float sq(float x) {
    return x*x;
}

void main() {
    vec2 p = fragCoord;
    vec3 col;
    for(float j = 0.0; j < 3.0; j++){
        for(float i = 1.0; i < 10.0; i++){
            p.x += 0.2 / (i + j) * cos(i * 5.0 * p.y + time );
            p.y += 0.2 / (i + j)* cos(i * 5.0 * p.x + time );
        }
        col[int(j)] = sin(.5 * 7.0*sq(p.x)) + sin(7.0*sq(p.y));
    }
    fragColor = vec4(1.) - vec4(col, 1.);
}
