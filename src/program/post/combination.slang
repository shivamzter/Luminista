import aperture;
import settings;
import helper.util;

Texture2D tex_main;
StructuredBuffer<float2> exposureBuffer;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = tex_main[uint2(pos)];
    float exposure = exposureBuffer[0].y;

    color.rgb = decodeColorRgbm16F(color);

    color.rgb *= exposure;

    color.rgb = color.rgb / (1.0 + color.rgb);

    return color;
}
