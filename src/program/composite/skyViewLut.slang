import aperture;
import helper.util;
import lib.atmosphere;
RWTexture2D tex_skyViewScatteringLUT;

[shader("compute")]
[numthreads(16, 8)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < SKY_VIEW_LUT_SIZE)) {

        float2 texcoord = (coord + 0.5) / float2(SKY_VIEW_LUT_SIZE);
        texcoord = fromSubUvsToUnit(texcoord, float2(SKY_VIEW_LUT_SIZE));

        float2 lonLat = getLonLatFromUvNonLinear(texcoord);

        float3 rayDir = getDirFromLonLat(lonLat);
        float3 rayOrigin = playerToAtmosphere(float3(0.0, ap.camera.position.y, 0.0));

        float3 scattering = float3(0.0);

        float3 entryPointPosition;
        float3 exitPointPosition;

        if (getRayMarchEndpoints(rayOrigin, rayDir, entryPointPosition, exitPointPosition)) {
            marchPrimaryRay ray = rayMarch(entryPointPosition, exitPointPosition, SKY_VIEW_LUT_STEPS);
            scattering = ray.scattering;
        }
        
        tex_skyViewScatteringLUT[coord] = encodeColorRgbm16F(scattering);
    }
}