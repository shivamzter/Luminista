import aperture;
import helpers.util;
import settings;
import lib.tonemap;

Texture2D mainTexture;
StructuredBuffer<float2> exposureBuffer;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {

    float4 color = mainTexture[pos];

    float exposure = exposureBuffer[0].y;

    
        color.rgb = decodeColorRgbm16F(color.rgba);

        color.rgb *= exposure;

        if (userSettings.TONE_MAPPING == ToneMapping.Reinhard) {
            color.rgb = color.rgb / (1.0 + color.rgb);
        } else if (userSettings.TONE_MAPPING == ToneMapping.PBRNeutral) {
            color.rgb = PBRNeutralToneMapping(color.rgb);
        } else if (userSettings.TONE_MAPPING == ToneMapping.ReinhardLuminance) {
            color.rgb = reinhardLuminanceToneMapping(color.rgb);
        }

        // color.rgb = PBRNeutralToneMapping(color.rgb);
        // color.rgb = reinhardLuminanceToneMapping(color.rgb);
    
   
    color.rgb = pow(color.rgb, float3(1.0 / 2.2));

    return color;
}
