import aperture;
import helper.util;
import lib.atmosphere;

RWTexture2D tex_skyMulScatterLUT;

[shader("compute")]
[numthreads(16, 8)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < SKY_MUL_SCATTER_LUT_SIZE)) {

        float2 texcoord = (coord + 0.5) / float2(SKY_MUL_SCATTER_LUT_SIZE);

        texcoord = fromSubUvsToUnit(texcoord, SKY_MUL_SCATTER_LUT_SIZE);

        

        float3 rayPos = float3(0.0, viewHeight, 0.0);
        float3 rayDir = float3(0.0, 1.0, 0.0);

        float SphereSolidAngle = 4.0 * PI;
        float IsotropicPhase = 1.0 / SphereSolidAngle;
        
    }
}