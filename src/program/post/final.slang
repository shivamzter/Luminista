import aperture;
import settings;

Texture2D tex_main;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = tex_main[uint2(pos)];

    color.rgb = pow(color.rgb, float3(1.0 / 2.2));

    return color;
}
