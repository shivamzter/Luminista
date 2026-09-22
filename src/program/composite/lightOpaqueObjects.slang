import aperture;
// import lib.shadow;
import lib.rt_shadows;
import helper.util;

RWTexture2D tex_main;
RWTexture2D tex_normal;
RWTexture2D tex_skyScattering;
RWTexture2D tex_skyTransmittance;
// RWTexture2D tex_skyAmbient;

public static const float3 SUN_ILLUMINANCE = float3(128000.0);
public static const float3 MOON_ILLUMINANCE = float3(0.25);

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float4 color = tex_main[coord];
        color.rgb = decodeColorRgbm16F(color);
        float4 normal = tex_normal[coord];
        normal.xyz = octDecode(normal.xy);

        float depth = ap.opaqueDepth[coord];

        // Space conversions
        float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
        float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
        float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

        if (depth > 0.0) {

            float3 shadow = getShadow(playerPos, normal.xyz);

            float3 sunLighting = shadow * SUN_ILLUMINANCE * max(0.0, dot(normalize(normal.xyz), normalize(ap.celestial.sunPosition))) / PI;
            float3 moonLighting = shadow * MOON_ILLUMINANCE * max(0.0, dot(normalize(normal.xyz), normalize(ap.celestial.moonPosition))) / PI;

            float3 skyLighting = float3(0.25, 0.5, 1.0) * 1000.0;

            color.rgb *= sunLighting + moonLighting + skyLighting;

        } else {
            float3 skyScattering = decodeColorRgbm16F(tex_skyScattering[coord]);
            float3 skyTransmittance = decodeColorRgbm16F(tex_skyTransmittance[coord]);

            color.rgb = color.rgb * skyTransmittance + skyScattering;
        }

        tex_main[coord] = encodeColorRgbm16F(color.rgb);
    }
}