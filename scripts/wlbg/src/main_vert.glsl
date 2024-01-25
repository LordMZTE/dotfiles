#version 430

in vec4 vPos;
in vec2 uv;

out vec2 fragCoord;
out vec2 fragUv;

void main() {
    gl_Position = vPos;
    fragCoord = vPos.xy;
    fragUv = uv;
}
