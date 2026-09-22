import aperture;
import settings;
import helper.util;

Texture2D tex_main;
StructuredBuffer<float2> exposureBuffer;

Texture2D tex_skyTransmittanceLUT;
Texture2D tex_skyViewScatteringLUT;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = tex_main[uint2(pos)];
    float exposure = exposureBuffer[0].y;

    float2 uv = pos / ap.game.renderSize;

    color.rgb = decodeColorRgbm16F(color);

    float3 skyTransmittanceLUT = tex_skyTransmittanceLUT.sampleLinear(uv).rgb;
    float3 skyScatteringLUT = decodeColorRgbm16F(tex_skyViewScatteringLUT.sampleLinear(uv));

    color.rgb *= exposure;

    color.rgb = color.rgb / (1.0 + color.rgb);

    color.rgb = pow(color.rgb, float3(1.0 / 2.2));

    // return float4(skyScatteringLUT, 1.0);
    return color;
}
