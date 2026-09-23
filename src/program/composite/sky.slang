import aperture;
import helper.util;
import lib.atmosphere;

Texture2D tex_skyViewTransmittanceLUT;
Texture2D tex_skyViewScatteringLUT;

// Texture2D tex_skyTransmittanceLUT;

RWTexture2D tex_main;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float4 color = tex_main[coord];
        color.rgb = decodeColorRgbm16F(color);

        float depth = ap.opaqueDepth[coord];

        if (depth == 0.0) {
            // Space conversions
            float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
            float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
            float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

            float3 cameraAtmosPos = playerToAtmosphere(float3(0.0, ap.camera.position.y, 0.0));

            float3 playerSpaceRayDirection = normalize(playerPos);

            float2 skyViewUV = getUvFromLonLatNonLinear(getLonLatFromDir(playerSpaceRayDirection));
            skyViewUV = fromUnitToSubUvs(skyViewUV, float2(SKY_VIEW_LUT_SIZE));

            float3 skyScattering = decodeColorRgbm16F(tex_skyViewScatteringLUT.SampleLevel(apt_linearSampler, skyViewUV, 0.0));
            float3 skyTransmittance = tex_skyViewTransmittanceLUT.SampleLevel(apt_linearSampler, skyViewUV, 0.0).rgb;
            // float3 skyTransmittance = computeTransmittanceToCelestialLight(cameraAtmosPos, playerSpaceRayDirection, tex_skyTransmittanceLUT);

            float sunViewDot = dot(normalize(playerPos), normalize(ap.celestial.sunPosition));
            float moonViewDot = dot(normalize(playerPos), normalize(ap.celestial.moonPosition));

            float3 sunDisc = select(sunViewDot >= cos(SUN_ANGULAR_RADIUS_RAD), SUN_LUMINANCE, float3(0.0));
            float3 moonDisc = select(moonViewDot >= cos(MOON_ANGULAR_RADIUS_RAD), MOON_LUMINANCE, float3(0.0));

            color.rgb = sunDisc + moonDisc;

            color.rgb = color.rgb * skyTransmittance + skyScattering;

            tex_main[coord] = encodeColorRgbm16F(color.rgb);
        }
    }
}