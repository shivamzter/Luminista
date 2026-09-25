import aperture;
import helper.util;
import lib.atmosphere.atmos_all;

RWTexture2D tex_skyTransmittanceLUT;

[shader("compute")]
[numthreads(16, 8)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < SKY_TRANSMITTANCE_LUT_SIZE)) {

        float2 texcoord = (coord + 0.5) / float2(SKY_TRANSMITTANCE_LUT_SIZE);

        float viewHeight;
        float viewZenithCosAngle;
        UvToLutTransmittanceParams(viewHeight, viewZenithCosAngle, texcoord);

        float3 rayOrigin = float3(0.0f, viewHeight, 0.0f);
	    float3 rayDir = float3(sqrt(1.0 - viewZenithCosAngle * viewZenithCosAngle), viewZenithCosAngle, 0.0f);

        float3 entryPointPosition;
        float3 exitPointPosition;

        if (getRayMarchEndpoints(rayOrigin, rayDir, entryPointPosition, exitPointPosition)) {

            primaryRayMarch ray = rayMarch(entryPointPosition, exitPointPosition, TRANSMITTANCE_LUT_STEPS);

            tex_skyTransmittanceLUT[coord] = float4(ray.transmittance, 1.0);
        };
    }
}