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

float interleavedGradientNoise(float2 uv) {
    const float2 magic = float2(0.06711056, 0.00583715);
    return fract(52.9829189 * fract(dot(uv, magic)));
}

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float2 texcoord = pos / ap.game.renderSize;
    float depth = ap.opaqueDepth[uint2(pos)];

    float4 color = tex_main[uint2(pos)];
    float exposure = exposureBuffer[0].y;

    float2 uv = pos / ap.game.renderSize;

    float2 lutUv = float2(uv.x, uv.y * 0.5 + 0.5);

    float3 skyTransmittanceLUT = tex_skyTransmittanceLUT.SampleLevel(apt_linearSampler, uv, 0).rgb;

    float3 skyViewTransmittanceLUT = tex_skyViewTransmittanceLUT.SampleLevel(apt_linearSampler, uv, 0).rgb;
    float3 skyViewScatteringLUT = tex_skyViewScatteringLUT.SampleLevel(apt_linearSampler, uv, 0).rgb;

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

    // color.rgb = pow(color.rgb, float3(1.0 / 2.2));

    // return float4(skyViewScatteringLUT / 1500, 1.0);
    return color;
}
