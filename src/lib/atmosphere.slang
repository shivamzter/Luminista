import aperture;
import helper.util;

Texture2D tex_skyTransmittanceLUT;

/*
////////// CREDITS \\\\\\\\\\
Jake Michie | Dev of Continuum - For basically everything with atmosphere;
*/

public static const uint2 SKY_VIEW_LUT_SIZE = uint2(192, 108);
public static const uint2 SKY_TRANSMITTANCE_LUT_SIZE = uint2(256, 64);

public float2 fromUnitToSubUvs(float2 unit, float2 resolution) {
    return (unit + 0.5 / resolution) * (resolution / (resolution + 1.0));
}

public float2 fromSubUvsToUnit(float2 unit, float2 resolution) {
    return (unit - 0.5 / resolution) * (resolution / (resolution - 1.0));
}
/////////////////////////////////////

public static const int SKY_VIEW_LUT_STEPS = 32;
public static const int TRANSMITTANCE_LUT_STEPS = 40;

// coefficients
static const float3 ATMOSPHERE_RAYLEIGH_SCATTERING_COEFFICIENT = float3(0.005802, 0.013558, 0.033100);
static const float3 ATMOSPHERE_RAYLEIGH_ABSORPTION_COEFFICIENT = float3(0.0);
static const float3 ATMOSPHERE_RAYLEIGH_EXTINCTION_COEFFICIENT = ATMOSPHERE_RAYLEIGH_SCATTERING_COEFFICIENT + ATMOSPHERE_RAYLEIGH_ABSORPTION_COEFFICIENT;
static const float ATMOSPHERE_RAYLEIGH_SCALE_HEIGHT = 8.0;
static const float ATMOSPHERE_RAYLEIGH_DENSITY_EXP_SCALE = -1.0 / ATMOSPHERE_RAYLEIGH_SCALE_HEIGHT;

static const float3 ATMOSPHERE_MIE_SCATTERING_COEFFICIENT = float3(0.003996);
static const float3 ATMOSPHERE_MIE_EXTINCTION_COEFFICIENT = float3(0.004440);
static const float ATMOSPHERE_MIE_SCALE_HEIGHT = 1.2;
static const float ATMOSPHERE_MIE_DENSITY_EXP_SCALE = -1.0 / ATMOSPHERE_MIE_SCALE_HEIGHT;

static const float3 ATMOSPHERE_OZONE_SCATTERING_COEFFICIENT = float3(0.0);
static const float3 ATMOSPHERE_OZONE_EXTINCTION_COEFFICIENT = float3(0.000650, 0.001881, 0.000085);
static const float ATMOSPHERE_OZONE_SCALE_HEIGHT = 15.0;
static const float ATMOSPHERE_OZONE_LAYER0_WIDTH = 25.0;
static const float ATMOSPHERE_OZONE_LAYER0_CONSTANT_TERM = -2.0 / 3.0;
static const float ATMOSPHERE_OZONE_LAYER0_LINEAR_TERM = 1.0 / ATMOSPHERE_OZONE_SCALE_HEIGHT;
static const float ATMOSPHERE_OZONE_LAYER1_CONSTANT_TERM =  8.0 / 3.0;
static const float ATMOSPHERE_OZONE_LAYER1_LINEAR_TERM = -1.0 / ATMOSPHERE_OZONE_SCALE_HEIGHT;

// earth stuff
static const float3 CENTER_OF_EARTH = float3(0.0, 0.0, 0.0);

public static const float EARTH_RADIUS_KM = 6400.0;
public static const float CAMERA_ALTITUDE_KM = -100.0 / 1000.0;
public static const float3 CAMERA_OFFSET_KM = float3(0.0, EARTH_RADIUS_KM + CAMERA_ALTITUDE_KM, 0.0);

static const float ATMOSPHERE_THICKNESS_KM = 100.0;
static const float ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM = EARTH_RADIUS_KM;
static const float ATMOSPHERE_TOP_SPHERE_RADIUS_KM = ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM + ATMOSPHERE_THICKNESS_KM;

public static const float SUN_ANGULAR_DIAMETER_DEG = 0.545;
public static const float SUN_ANGULAR_DIAMETER_RAD = radians(SUN_ANGULAR_DIAMETER_DEG);
public static const float SUN_ANGULAR_RADIUS_DEG = SUN_ANGULAR_DIAMETER_DEG / 2.0;
public static const float SUN_ANGULAR_RADIUS_RAD = SUN_ANGULAR_DIAMETER_RAD / 2.0;
public static const float SUN_SOLID_ANGLE = 2.0 * PI * (1.0 - cos(SUN_ANGULAR_RADIUS_DEG * (PI / 180.0)));
public static const float3 SUN_ILLUMINANCE = float3(128000.0);
public static const float3 SUN_LUMINANCE = SUN_ILLUMINANCE / SUN_SOLID_ANGLE;

public static const float MOON_ANGULAR_DIAMETER_DEG = 0.518;
public static const float MOON_ANGULAR_DIAMETER_RAD = radians(MOON_ANGULAR_DIAMETER_DEG);
public static const float MOON_ANGULAR_RADIUS_DEG = MOON_ANGULAR_DIAMETER_DEG / 2.0;
public static const float MOON_ANGULAR_RADIUS_RAD = MOON_ANGULAR_DIAMETER_RAD / 2.0;
public static const float MOON_SOLID_ANGLE = 2.0 * PI * (1.0 - cos(MOON_ANGULAR_RADIUS_DEG * (PI / 180.0)));
public static const float3 MOON_ILLUMINANCE = float3(0.25);
public static const float3 MOON_LUMINANCE = MOON_ILLUMINANCE / MOON_SOLID_ANGLE;

public float3 playerToAtmosphere(float3 playerPos) {
    return fma(playerPos, rcp(1000.0), CAMERA_OFFSET_KM);
}

public float3 atmoshphereToPlayer(float3 atmoshpherePos) {
    return fma(atmoshpherePos, 1000.0, -CAMERA_OFFSET_KM);
}

public float earthShadow(float3 rayPos, float3 lightDir) {
    float3 localUpVec = normalize(rayPos) * 0.01;
    float2 earthShadowIntersection = sphIntersect(rayPos + localUpVec, lightDir, CENTER_OF_EARTH, EARTH_RADIUS_KM + CAMERA_ALTITUDE_KM);
    return earthShadowIntersection.y < 0.0 ? 1.0 : 0.0;
}

public float2 sphIntersect( in float3 ro, in float3 rd, in float3 ce, float ra )
{
    float3 oc = ro - ce;
    float b = dot( oc, rd );
    float3 qc = oc - b*rd;
    float h = ra*ra - dot( qc, qc );
    if( h<0.0 ) return float2(-1.0); // no intersection
    h = sqrt( h );
    return float2( -b-h, -b+h );
}

public struct MediumSample {
    float3 rayleighScattering;
    float3 rayleighExtinction;

    float3 mieScattering;
    float3 mieExtinction;

    float3 ozoneExtinction;

    float3 totalScattering;
    float3 totalExtinction;
}

public float3 computeTransmittanceToCelestialLight(
    float3 atmosphereSpacePos,
    float3 playerSpaceDir,
    Texture2D transmittanceLut
) {
    float altitude = length(atmosphereSpacePos);

    float3 upDir = atmosphereSpacePos / altitude;
    float zenithCosAngle = dot(playerSpaceDir, upDir);

    float2 uv;
    LutTransmittanceParamsToUv(altitude, zenithCosAngle, uv);
    return transmittanceLut.SampleLevel(apt_linearSampler, uv, 0.0).rgb;
}

public MediumSample sampleMedium(float sampleAltitude) {
    sampleAltitude = max(sampleAltitude - ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM, 0.0);

    float rayleighDensity = exp(ATMOSPHERE_RAYLEIGH_DENSITY_EXP_SCALE * sampleAltitude);
    float mieDensity = exp(ATMOSPHERE_MIE_DENSITY_EXP_SCALE * sampleAltitude);
    float ozoneDensity = saturate(select(
        sampleAltitude < ATMOSPHERE_OZONE_LAYER0_WIDTH,
        fma(ATMOSPHERE_OZONE_LAYER0_LINEAR_TERM, sampleAltitude, ATMOSPHERE_OZONE_LAYER0_CONSTANT_TERM),
        fma(ATMOSPHERE_OZONE_LAYER1_LINEAR_TERM, sampleAltitude, ATMOSPHERE_OZONE_LAYER1_CONSTANT_TERM)
    ));

    MediumSample sample;

    sample.rayleighScattering = ATMOSPHERE_RAYLEIGH_SCATTERING_COEFFICIENT * rayleighDensity;
    sample.rayleighExtinction = ATMOSPHERE_RAYLEIGH_EXTINCTION_COEFFICIENT * rayleighDensity;

    sample.mieScattering = ATMOSPHERE_MIE_SCATTERING_COEFFICIENT * mieDensity;
    sample.mieExtinction = ATMOSPHERE_MIE_EXTINCTION_COEFFICIENT * mieDensity;

    sample.ozoneExtinction = ATMOSPHERE_OZONE_EXTINCTION_COEFFICIENT * ozoneDensity;

    sample.totalScattering = sample.rayleighScattering + sample.mieScattering;
    sample.totalExtinction = sample.rayleighExtinction + sample.mieExtinction + sample.ozoneExtinction;

    return sample;
}

public void UvToLutTransmittanceParams(out float viewHeight, out float viewZenithCosAngle, in float2 uv)
{
	//uv = float2(fromSubUvsToUnit(uv.x, TRANSMITTANCE_TEXTURE_WIDTH), fromSubUvsToUnit(uv.y, TRANSMITTANCE_TEXTURE_HEIGHT)); // No real impact so off
	float x_mu = uv.x;
	float x_r = uv.y;

	float H = sqrt(ATMOSPHERE_TOP_SPHERE_RADIUS_KM * ATMOSPHERE_TOP_SPHERE_RADIUS_KM - ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM * ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM);
	float rho = H * x_r;
	viewHeight = sqrt(rho * rho + ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM * ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM);

	float d_min = ATMOSPHERE_TOP_SPHERE_RADIUS_KM - viewHeight;
	float d_max = rho + H;
	float d = d_min + x_mu * (d_max - d_min);
	viewZenithCosAngle = d == 0.0 ? 1.0f : (H * H - rho * rho - d * d) / (2.0 * viewHeight * d);
	viewZenithCosAngle = clamp(viewZenithCosAngle, -1.0, 1.0);
}

public void LutTransmittanceParamsToUv(in float viewHeight, in float viewZenithCosAngle, out float2 uv)
{
	float H = sqrt(max(0.0f, ATMOSPHERE_TOP_SPHERE_RADIUS_KM * ATMOSPHERE_TOP_SPHERE_RADIUS_KM - ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM * ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM));
	float rho = sqrt(max(0.0f, viewHeight * viewHeight - ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM * ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM));

	float discriminant = viewHeight * viewHeight * (viewZenithCosAngle * viewZenithCosAngle - 1.0) + ATMOSPHERE_TOP_SPHERE_RADIUS_KM * ATMOSPHERE_TOP_SPHERE_RADIUS_KM;
	float d = max(0.0, (-viewHeight * viewZenithCosAngle + sqrt(discriminant))); // Distance to atmosphere boundary

	float d_min = ATMOSPHERE_TOP_SPHERE_RADIUS_KM - viewHeight;
	float d_max = rho + H;
	float x_mu = (d - d_min) / (d_max - d_min);
	float x_r = rho / H;

	uv = float2(x_mu, x_r);
	//uv = float2(fromUnitToSubUvs(uv.x, TRANSMITTANCE_TEXTURE_WIDTH), fromUnitToSubUvs(uv.y, TRANSMITTANCE_TEXTURE_HEIGHT)); // No real impact so off
}

public float miePhaseCornetteShanks(float cosTheta, float g) {
    float gSqr = g * g;
    float k = 3.0 / (8.0 * PI) * (1.0 - gSqr) / (2.0 + gSqr);
    return k * (1.0 + cosTheta * cosTheta) / pow(1.0 + gSqr - 2.0 * g * -cosTheta, 1.5);
}

public float rayleighPhase(float cosTheta) {
    const static float factor = 3.0 / (16.0 * PI);

    return factor * (1.0 + cosTheta * cosTheta);
}

//// First raymarch for sky
bool getDistances(in float2 atmosLayerTop, in float2 atmosLayerBottom, out float closestDistance, out float furthestDistance) {

    // ray didn't exist the top sphere, it missed the atmosphere entirely
    if (atmosLayerTop.y < 0.0) {
        return false;
    } 

    // ray existed the top sphere but didn't enter, its origin is inside of the atmosphere
    else if (atmosLayerTop.x < 0.0) {
        closestDistance = 0.0;
        furthestDistance = atmosLayerBottom.x >= 0.0 ? min(atmosLayerTop.y, atmosLayerBottom.x) : atmosLayerTop.y;

        return true;
    }

    // ray entered and existed the top, it's origin is outside of the atmosphere
    else {
        closestDistance = atmosLayerTop.x;
        furthestDistance = atmosLayerBottom.x >= 0.0 ? min(atmosLayerTop.y, atmosLayerBottom.x) : atmosLayerTop.y;
    
        return false;
    }

    return true;
}

public float3 computeIntegratedSingleScatteringForCelestialLight(MediumSample mediumSample, float lightRayleighPhase, float lightMiePhase, float3 rayPos, float3 lightDir, float3 sampleTransmittance, float3 lightIlluminance) {

    float3 phaseTimesMediumScattering = mediumSample.rayleighScattering * lightRayleighPhase + mediumSample.mieScattering * lightMiePhase;

    float3 localUpVec = normalize(rayPos) * 0.01;
    float2 earthShadowIntersection = sphIntersect(rayPos + localUpVec, lightDir, CENTER_OF_EARTH, EARTH_RADIUS_KM);
    float earthShadow = earthShadowIntersection.y < 0.0 ? 1.0 : 0.0;

    float viewHeight = length(rayPos);
    float3 upVector = rayPos / viewHeight;
    float viewZenithCosAngle = dot(lightDir, upVector);
    
    float2 uv;
    LutTransmittanceParamsToUv(viewHeight, viewZenithCosAngle, uv);
    float3 sampleToLightTransmittance = tex_skyTransmittanceLUT.SampleLevel(apt_linearSampler, uv, 0).rgb;

    float3 singleScattering = lightIlluminance * phaseTimesMediumScattering * sampleToLightTransmittance * earthShadow;

    return (singleScattering - singleScattering * sampleTransmittance) / mediumSample.totalExtinction;
}

public struct marchPrimaryRay {
    public float3 scattering;
    public float3 transmittance;
}

public bool getRayMarchEndpoints(float3 rayOrigin, float3 rayDir, out float3 entryPointPosition, out float3 exitPointPosition) {

    float2 atmosLayerBottom = sphIntersect(rayOrigin, rayDir, CENTER_OF_EARTH, ATMOSHPHERE_BOTTOM_SPHERE_RADIUS_KM);
    float2 atmosLayerTop = sphIntersect(rayOrigin, rayDir, CENTER_OF_EARTH, ATMOSPHERE_TOP_SPHERE_RADIUS_KM);

    float closestDistance = 0.0;
    float furthestDistance = 0.0;

    // Check if need to raymarch
    bool needToRayMarch = getDistances(atmosLayerTop, atmosLayerBottom, closestDistance, furthestDistance);

    entryPointPosition = rayOrigin + rayDir * closestDistance;
    exitPointPosition = rayOrigin + rayDir * furthestDistance;

    return needToRayMarch;
}

public marchPrimaryRay rayMarch(in float3 entryPointPosition, in float3 exitPointPosition, in int numSteps) {

    marchPrimaryRay ray;
    ray.scattering = float3(0.0);
    ray.transmittance = float3(1.0);

    float3 rayDir = normalize(exitPointPosition - entryPointPosition);

    float3 sunLightDir = normalize(ap.celestial.sunPosition);
    float3 moonLightDir = normalize(ap.celestial.moonPosition);

    float sunCosTheta = dot(-rayDir, sunLightDir);
    float moonCosTheta = dot(-rayDir, moonLightDir);

    // prerequisites
    float sunLightRayleighPhase = rayleighPhase(sunCosTheta);
    float sunLightMiePhase = miePhaseCornetteShanks(sunCosTheta, 0.8);

    float moonLightRayleighPhase = rayleighPhase(moonCosTheta);
    float moonLightMiePhase = miePhaseCornetteShanks(moonCosTheta, 0.8);

    // from entry to exit point in defined number of steps
    float3 rayStep = (exitPointPosition - entryPointPosition) / float(numSteps);

    // Distance between each step;
    float rayStepLength = length(rayStep);

    for (int i = 0; i < numSteps; i++) {
        float3 rayPos = lerp(entryPointPosition, exitPointPosition, (float(i) + 0.5) / float(numSteps));

        float sampleAltitude = length(rayPos);

        MediumSample mediumSample = sampleMedium(sampleAltitude);
        float3 sampleTransmittance = exp(-mediumSample.totalExtinction * rayStepLength);

        float3 integratedSunSingleScattering = computeIntegratedSingleScatteringForCelestialLight(mediumSample, sunLightRayleighPhase, sunLightMiePhase, rayPos, sunLightDir, sampleTransmittance, SUN_ILLUMINANCE);
        float3 integratedMoonSingleScattering = computeIntegratedSingleScatteringForCelestialLight(mediumSample, moonLightRayleighPhase, moonLightMiePhase, rayPos, moonLightDir, sampleTransmittance, MOON_ILLUMINANCE);

        ray.scattering += (integratedSunSingleScattering + integratedMoonSingleScattering) * ray.transmittance;
        ray.transmittance *= sampleTransmittance;
    }

    return ray;
}