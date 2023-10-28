#version 300 es

precision mediump float;

attribute vec4 vPos;
attribute vec2 uv;

out vec2 fragCoord;
out vec2 fragUv;

void main() {
    gl_Position = vPos;
    fragCoord = vPos.xy;
    fragUv = uv;
}
