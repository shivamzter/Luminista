import aperture;
import settings;
import helper.util;

Texture2D tex_main;
StructuredBuffer<float2> exposureBuffer;

Texture2D tex_skyViewLUT;
Texture2D tex_skyViewTransmittanceLUT;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = tex_main[uint2(pos)];
    float exposure = exposureBuffer[0].y;

    float2 uv = pos / ap.game.renderSize;

    color.rgb = decodeColorRgbm16F(color);

    float4 sampleSkyScatteringLUT = tex_skyViewLUT.sampleLinear(uv);
    float4 sampleSkyTransmittanceLUT = tex_skyViewTransmittanceLUT.sampleLinear(uv);

    float3 skyScatteringLUT = decodeColorRgbm16F(sampleSkyScatteringLUT);
    float3 skyTransmittanceLUT = decodeColorRgbm16F(sampleSkyTransmittanceLUT);

    color.rgb *= exposure;

    color.rgb = color.rgb / (1.0 + color.rgb);

    // return float4(skyScatteringLUT / 100, 1.0);
    return color;
}
