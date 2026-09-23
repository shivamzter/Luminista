import aperture;
import settings;
import helper.util;
import lib.tonemap;

Texture2D tex_main;
StructuredBuffer<float2> exposureBuffer;

Texture2D tex_skyTransmittanceLUT;

Texture2D tex_skyViewTransmittanceLUT;
Texture2D tex_skyViewScatteringLUT;

// float3 reinhardLuminanceToneMapping(float3 color) {
//     const float3 lw = float3(0.2126, 0.7152, 0.0722);   // Rec.709 luminance weights
//     float luminance = dot(color, lw);
//     float toneMappedLuminance = luminance / (1.0 + luminance);
//     float scale = luminance > 0.0 ? toneMappedLuminance / luminance : 0.0;
//     return color * scale;
// }

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float2 texcoord = pos / ap.game.renderSize;
    float depth = ap.depth.sampleLinear(texcoord);

    float4 color = tex_main[uint2(pos)];
    float exposure = exposureBuffer[0].y;

    float2 uv = pos / ap.game.renderSize;

    color.rgb = decodeColorRgbm16F(color);

    float3 skyTransmittanceLUT = tex_skyTransmittanceLUT.SampleLevel(apt_linearSampler, uv, 0).rgb;

    float3 skyViewTransmittanceLUT = tex_skyViewTransmittanceLUT.SampleLevel(apt_linearSampler, uv, 0).rgb;
    float3 skyViewScatteringLUT = decodeColorRgbm16F(tex_skyViewScatteringLUT.SampleLevel(apt_linearSampler, uv, 0));

    if (!userSettings.AUTO_EXPOSURE) {
        color.rgb *= userSettings.MANUAL_EXPOSURE;
    } else {
        color.rgb *= exposure;
    }

    if (userSettings.TONE_MAPPING == ToneMapping.Reinhard) {
        color.rgb = reinhard(color.rgb);
    } else if (userSettings.TONE_MAPPING == ToneMapping.Reinhard2) {
        color.rgb = reinhard2(color.rgb);
    } else if (userSettings.TONE_MAPPING == ToneMapping.ReinhardJodie) {
        color.rgb = reinhardJodie(color.rgb);
    } else if (userSettings.TONE_MAPPING == ToneMapping.ACES) {
        color.rgb = aces(color.rgb);
    } else if (userSettings.TONE_MAPPING == ToneMapping.Neutral) {
        color.rgb = PBRNeutralToneMapping(color.rgb);
    }

    color.rgb = pow(color.rgb, float3(1.0 / 2.2));

    // return float4(skyViewScatteringLUT / 100, 1.0);
    return color;
}
