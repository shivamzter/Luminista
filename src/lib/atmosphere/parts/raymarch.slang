implementing atmos_all;

Texture2D tex_skyTransmittanceLUT;

public struct primaryRayMarch{
    public float3 scattering;
    public float3 transmittance;
}

//// Second raymarch for sky
// bool getDistancesForSecondRay(in float2 atmosLayerTop, in float2 atmosLayerBottom, out float furthestDistance) {

//     // ray existed the top sphere but didn't enter, its origin is inside of the atmosphere
//     if (atmosLayerTop.x < 0.0) {

//     furthestDistance = atmosLayerBottom.x >= 0.0 ? min(atmosLayerTop.y, atmosLayerBottom.x) : atmosLayerTop.y;

//     return true;
//     }

//     return false;
// }

// public float3 rayMarchSecondary(in float3 playerSpaceRayOrigin) {
    
//     float3 transmittance = float3(1.0);

//     float3 rayOrigin = playerSpaceRayOrigin;
    
//     // float3 lightPos = mul(float3x3(ap.camera.viewInv), ap.celestial.sunPosition);
//     float3 lightDir = normalize(ap.celestial.position);

//     float2 atmosLayerBottom = sphIntersect(rayOrigin, lightDir, CENTER_OF_EARTH, ATMOSPHERE_BOTTOM_RADIUS_KM);
//     float2 atmosLayerTop = sphIntersect(rayOrigin, lightDir, CENTER_OF_EARTH, ATMOSPHERE_TOP_RADIUS_KM);

//     ////
//     float closestDistance = 0.0;
//     float furthestDistance = 0.0;

//     // Check if need to raymarch
//     bool needToRayMarch = getDistancesForSecondRay(atmosLayerTop, atmosLayerBottom, furthestDistance);

//     if (!needToRayMarch) {
//         return transmittance;
//     }

//     float3 entryPointPosition = rayOrigin + lightDir * closestDistance;
//     float3 exitPointPosition = rayOrigin + lightDir * furthestDistance;

//     // from entry to exit point in defined number of steps
//     float3 rayStep = (exitPointPosition - entryPointPosition) / float(SKY_VIEW_LUT_STEPS);

//     // Distance between each step;
//     float rayStepLength = length(rayStep);

//     for (int i = 0; i < SKY_VIEW_LUT_STEPS; i++) {
//         float3 rayPos = lerp(entryPointPosition, exitPointPosition, (float(i) + 0.5) / float(SKY_VIEW_LUT_STEPS));

//         float sampleAltitude = length(rayPos);

//         MediumSample mediumSample = sampleMedium(sampleAltitude);
//         float3 sampleTransmittance = exp(-mediumSample.totalExtinction * rayStepLength);

//         transmittance *= sampleTransmittance;
//     }

//     return transmittance;
// }

public float3 computeIntegratedSingleScatteringForCelestialLight(MediumSample mediumSample, float lightRayleighPhase, float lightMiePhase, float3 rayPos, float3 lightDir, float3 sampleTransmittance, float3 lightIlluminance) {

    float3 phaseTimesMediumScattering = mediumSample.rayleighScattering * lightRayleighPhase + mediumSample.mieScattering * lightMiePhase;

    float earthShadow = earthShadow(rayPos, lightDir);
        
    float3 sampleToLightTransmittance = computeTransmittanceToCelestialLight(rayPos, lightDir, tex_skyTransmittanceLUT);

    float3 singleScattering = lightIlluminance * phaseTimesMediumScattering * sampleToLightTransmittance * earthShadow;

    return (singleScattering - singleScattering * sampleTransmittance) / mediumSample.totalExtinction;
}

public primaryRayMarch rayMarch(in float3 entryPointPos, in float3 exitPointPos, in int numSteps) {

    primaryRayMarch ray;
    ray.scattering = float3(0.0);
    ray.transmittance = float3(1.0);

    float3 rayDir = normalize(exitPointPos - entryPointPos);

    float3 sunLightDir = normalize(ap.celestial.sunPosition);
    float3 moonLightDir = normalize(ap.celestial.moonPosition);

    float sunCosTheta = dot(rayDir, sunLightDir);
    float moonCosTheta = dot(rayDir, moonLightDir);

    float sunLightRayleighPhase = rayleighPhase(sunCosTheta);
    float moonLightRayleighPhase = rayleighPhase(moonCosTheta);

    float sunLightMiePhase = miePhaseCornetteShanks(sunCosTheta, MIE_PHASE_G);
    float moonLightMiePhase = miePhaseCornetteShanks(moonCosTheta, MIE_PHASE_G);

    float3 rayStep = (exitPointPos - entryPointPos) / float(numSteps);

    float rayStepLength = length(rayStep);

    for (int i = 0; i < numSteps; i++) {

        float3 rayPos = lerp(entryPointPos, exitPointPos, (float(i) + 0.5) / float(numSteps));

        float sampleRadius = length(rayPos);

        MediumSample mediumSample = sampleMedium(sampleRadius);

        float3 sampleTransmittance = exp(-mediumSample.totalExtinction * rayStepLength);

        float3 sunScattering = computeIntegratedSingleScatteringForCelestialLight(mediumSample, sunLightRayleighPhase, sunLightMiePhase, rayPos, sunLightDir, sampleTransmittance, SUN_ILLUMINANCE);
        float3 moonScattering = computeIntegratedSingleScatteringForCelestialLight(mediumSample, moonLightRayleighPhase, moonLightMiePhase, rayPos, moonLightDir, sampleTransmittance, MOON_ILLUMINANCE);

        ray.scattering += (sunScattering + moonScattering) * ray.transmittance;
        ray.transmittance *= sampleTransmittance;
    }

    return ray;
}