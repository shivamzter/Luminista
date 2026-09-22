import aperture;
import helper.util;
import lib.atmosphere;

Texture2D tex_skyViewLUT;
Texture2D tex_skyTransmittanceLUT;

RWTexture2D tex_skyScattering;
RWTexture2D tex_skyTransmittance;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float depth = ap.opaqueDepth[coord];

        if (depth == 0.0) {
            // Space conversions
            float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
            float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
            float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

            float3 playerSpaceRayDirection = normalize(playerPos);

            float2 uv = getUvFromLonLatNonLinear(getLonLatFromDir(playerSpaceRayDirection));
            uv = fromUnitToSubUvs(uv, float2(SKY_VIEW_LUT_SIZE));

            float3 skyScattering = decodeColorRgbm16F(tex_skyViewLUT.sampleLinear(uv));
            float3 skyTransmittance = tex_skyTransmittanceLUT.sampleLinear(uv).rgb;

            tex_skyScattering[coord] = encodeColorRgbm16F(skyScattering);
            tex_skyTransmittance[coord] = float4(skyTransmittance, 1.0);
        }
    }
}