#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D colorSource;

void main() {
    vec4 sourceColor = texture(source, qt_TexCoord0);
    vec4 color = texture(colorSource, qt_TexCoord0);
    fragColor = vec4(color.rgb, sourceColor.a * qt_Opacity);
} 