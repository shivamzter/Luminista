import aperture;
import settings;
import helper.util;

Texture2D tex_main;
StructuredBuffer<float2> exposureBuffer;

Texture2D tex_skyViewLUT;
Texture2D tex_skyTransmittanceLUT;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = tex_main[uint2(pos)];
    float exposure = exposureBuffer[0].y;

    float2 uv = pos / ap.game.renderSize;

    color.rgb = decodeColorRgbm16F(color);

    float4 sampleSkyScatteringLUT = tex_skyViewLUT.sampleLinear(uv);
    float4 sampleTransmittanceLUT = tex_skyTransmittanceLUT.sampleLinear(uv);

    float3 skyScatteringLUT = decodeColorRgbm16F(sampleSkyScatteringLUT);
    float3 transmittanceLUT = sampleTransmittanceLUT.rgb;

    color.rgb *= exposure;

    color.rgb = color.rgb / (1.0 + color.rgb);

    // return float4(skyScatteringLUT, 1.0);
    return color;
}
