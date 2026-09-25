implementing atmos_all;

import helper.util;

// LUT ////////////////////

public static const uint2 SKY_TRANSMITTANCE_LUT_SIZE = uint2(256, 64);
public static const uint2 SKY_MUL_SCATTER_LUT_SIZE = uint2(32, 32);
public static const uint2 SKY_VIEW_LUT_SIZE = uint2(192, 108);

public static const int TRANSMITTANCE_LUT_STEPS = 40;
public static const int SKY_MUL_SCATTER_LUT_STEPS = 20;
public static const int SKY_VIEW_LUT_STEPS = 32;

// PLANET EARTH ////////////////////

public static const float3 CENTER_OF_EARTH = float3(0.0, 0.0, 0.0);

public static const float EARTH_RADIUS_KM = 6400.0;
public static const float ATMOSPHERE_THICKNESS_KM = 100.0;

public static const float ATMOSPHERE_BOTTOM_RADIUS_KM = EARTH_RADIUS_KM;
public static const float ATMOSPHERE_TOP_RADIUS_KM = ATMOSPHERE_BOTTOM_RADIUS_KM + ATMOSPHERE_THICKNESS_KM;

public static const float CAMERA_ALTITUDE_KM = 100.0 / 1000.0;
public static const float3 CAMERA_OFFSET_KM = float3(0.0, EARTH_RADIUS_KM + CAMERA_ALTITUDE_KM, 0.0);

// CELESTIALS ////////////////////

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

// COEFFICIENTS ////////////////////

public static const float3 RAYLEIGH_SCATTERING = float3(0.005802, 0.013558, 0.033100);
public static const float3 RAYLEIGH_ABSORPTION = float3(0.0);
public static const float3 RAYLEIGH_EXTINCTION = RAYLEIGH_SCATTERING + RAYLEIGH_ABSORPTION;

public static const float RAYLEIGH_SCALE_HEIGHT = 8.0;
public static const float RAYLEIGH_DENSITY_EXP_SCALE = -1.0 / RAYLEIGH_SCALE_HEIGHT;

public static const float3 MIE_SCATTERING = float3(0.003996);
public static const float3 MIE_EXTINCTION = float3(0.004440);

public static const float MIE_SCALE_HEIGHT = 1.2;
public static const float MIE_DENSITY_EXP_SCALE = -1.0 / MIE_SCALE_HEIGHT;

public static const float3 OZONE_SCATTERING = float3(0.0);
public static const float3 OZONE_EXTINCTION = float3(0.000650, 0.001881, 0.000085);

static const float OZONE_SCALE_HEIGHT = 15.0;
static const float OZONE_LAYER0_WIDTH = 25.0;
static const float OZONE_LAYER0_CONSTANT_TERM = -2.0 / 3.0;
static const float OZONE_LAYER0_LINEAR_TERM = 1.0 / OZONE_SCALE_HEIGHT;
static const float OZONE_LAYER1_CONSTANT_TERM =  8.0 / 3.0;
static const float OZONE_LAYER1_LINEAR_TERM = -1.0 / OZONE_SCALE_HEIGHT;

static const float MIE_PHASE_G = 0.8;

// MULTI SCATTER ////////////////////

// MULTI-SCATTER ////////////////////
static const float ISOTROPIC_PHASE = 1.0 / (4.0 * PI);   // same in every direction
static const float3 GROUND_ALBEDO = float3(0.3);         // how much light the ground bounces back
static const float PLANET_RADIUS_OFFSET_KM = 0.01;       // 10 m lift, so rays starting on the ground don't hit it
public static const float MULTIPLE_SCATTERING_FACTOR = 1.0;     // artistic knob, 1 = physical
public static const int MUL_SCATTER_SQRT_SAMPLE_COUNT = 8;      // 8 × 8 = 64 directions