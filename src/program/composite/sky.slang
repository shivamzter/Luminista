import aperture;
// import lib.shadow;
import lib.rt_shadows;
import helper.util;
import lib.atmosphere;

RWTexture2D tex_skyScattering;
RWTexture2D tex_skyTransmittance;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float depth = ap.opaqueDepth[coord];

        // Space conversions
        float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
        float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
        float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

        float3 playerSpaceRayOrigin = float3(0.0, ap.camera.position.y, 0.0);
        float3 playerSpaceRayDirection = normalize(playerPos);

        if (depth == 0.0) {
            marchPrimaryRay ray = rayMarch(playerSpaceRayOrigin, playerSpaceRayDirection);

            tex_skyScattering[coord] = float4(ray.scattering, 1.0);
            tex_skyTransmittance[coord] = float4(ray.transmittance, 1.0);
        }
    }
}