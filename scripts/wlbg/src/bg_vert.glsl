#version 300 es

precision mediump float;

uniform vec2 offset;

in vec4 vPos;

out vec2 fragCoord;

void main() {
    gl_Position = vPos;
    fragCoord = vPos.xy + offset * 2.0;
}
