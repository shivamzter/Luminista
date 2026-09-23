import aperture;
import settings;
import helper.util;

Texture2D tex_main;
StructuredBuffer<float2> exposureBuffer;

Texture2D tex_skyTransmittanceLUT;
Texture2D tex_skyViewScatteringLUT;

float3 reinhardLuminanceToneMapping(float3 color) {
    const float3 lw = float3(0.2126, 0.7152, 0.0722);   // Rec.709 luminance weights
    float luminance = dot(color, lw);
    float toneMappedLuminance = luminance / (1.0 + luminance);
    float scale = luminance > 0.0 ? toneMappedLuminance / luminance : 0.0;
    return color * scale;
}

float interleavedGradientNoise(float2 pixel) {
    return frac(52.9829189 * frac(dot(pixel, float2(0.06711056, 0.00583715))));
}

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float2 texcoord = pos / ap.game.renderSize;
    float depth = ap.depth.sampleLinear(texcoord);

    float4 color = tex_main[uint2(pos)];
    float exposure = exposureBuffer[0].y;

    float2 uv = pos / ap.game.renderSize;

    color.rgb = decodeColorRgbm16F(color);

    float3 skyTransmittanceLUT = tex_skyTransmittanceLUT.sampleLinear(uv).rgb;
    float3 skyScatteringLUT = decodeColorRgbm16F(tex_skyViewScatteringLUT.sampleLinear(uv));

    color.rgb *= exposure;

    // color.rgb = color.rgb / (1.0 + color.rgb);
    color.rgb = reinhardLuminanceToneMapping(color.rgb);

    color.rgb = pow(color.rgb, float3(1.0 / 2.2));

    if (depth == 0) {
        float noise = interleavedGradientNoise(pos) - 0.5;
        color.rgb += noise / 255.0;
    }

    // return float4(skyScatteringLUT, 1.0);
    return color;
}
