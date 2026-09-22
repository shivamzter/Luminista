import aperture;
import helper.util;
import lib.atmosphere;

RWTexture2D tex_skyViewLUT;
RWTexture2D tex_skyViewTransmittanceLUT;
Texture2D tex_skyTransmittanceLUT;

[shader("compute")]
[numthreads(16, 8)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < SKY_VIEW_LUT_SIZE)) {

        float2 texcoord = (coord + 0.5) / float2(SKY_VIEW_LUT_SIZE);
        texcoord = fromSubUvsToUnit(texcoord, float2(SKY_VIEW_LUT_SIZE));

        float2 lonLat = getLonLatFromUvNonLinear(texcoord);

        float3 rayDir = getDirFromLonLat(lonLat);
        float3 rayOrigin = float3(0.0, ap.camera.position.y, 0.0);

        marchPrimaryRay ray = rayMarch(rayOrigin, rayDir); 
        
        tex_skyViewLUT[coord] = encodeColorRgbm16F(ray.scattering);
        // tex_skyViewTransmittanceLUT[coord] = encodeColorRgbm16F(ray.transmittance);
    }
}