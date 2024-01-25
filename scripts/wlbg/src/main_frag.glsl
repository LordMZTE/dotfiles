#version 430

uniform sampler2D bg;

uniform vec2 cursorPos;
uniform float hasCursor;

in vec2 fragCoord;
in vec2 fragUv;

out vec4 fragColor;

void main() {
    vec2 diff = cursorPos - fragUv;
    float light = clamp(.1 - (diff.x * diff.x + diff.y * diff.y), 0.0, 1.0);

    vec2 zoomedUv = fragUv * .9 + (.1 / 2.0);
    fragColor = mix(texture(bg, zoomedUv + (cursorPos - .5) / 10.0), vec4(1.0), light * hasCursor);
}

