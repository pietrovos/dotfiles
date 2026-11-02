#version 440

// The slanted centre-out wallpaper reveal. Computed per pixel so that advancing
// it costs one uniform write, instead of retessellating a mask every frame.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec2 pixelSize;
};

layout(binding = 1) uniform sampler2D source;

const float slant = -0.18;
const float feather = 1.5;

void main() {
    vec2 pixel = qt_TexCoord0 * pixelSize;
    float center = pixelSize.x / 2.0 + slant * (pixel.y - pixelSize.y / 2.0);
    float reach = pixelSize.x / 2.0 + abs(slant) * pixelSize.y / 2.0;
    float spread = (reach + 2.0 * feather) * progress - feather;
    float mask = 1.0 - smoothstep(spread - feather, spread + feather, abs(pixel.x - center));
    fragColor = texture(source, qt_TexCoord0) * mask * qt_Opacity;
}
