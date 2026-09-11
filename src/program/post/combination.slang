import aperture;
import settings;

Texture2D mainTexture;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = mainTexture[uint2(pos)];

    return color;
}
