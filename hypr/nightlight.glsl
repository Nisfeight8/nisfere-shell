#version 300 es
precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    color.r *= 1.00;
    color.g *= 0.80;
    color.b *= 0.65;
    
    fragColor = color;
}