import aperture;
import settings;

Texture2D tex_main;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = tex_main[uint2(pos)];

    return color;
}
