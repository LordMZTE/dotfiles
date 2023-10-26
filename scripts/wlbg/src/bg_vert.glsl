#version 300 es

precision mediump float;

attribute vec4 vPos;
attribute vec2 monitorOffset;

out vec2 fragCoord;

void main() {
    gl_Position = vPos;
    fragCoord = vPos.xy + monitorOffset * 2.0;
}
