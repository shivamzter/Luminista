public static const float PI = 3.14159265359;
static const float HALF_PI = PI * 0.5;
static const float RCP_HALF_PI = 1.0 / HALF_PI;

// https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
public float2 octWrap(float2 v)
{
    return (1.0 - abs(v.yx)) * select(v.xy >= 0.0, 1.0, -1.0);
}
 
public float2 octEncode(float3 n)
{
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    n.xy = n.z >= 0.0 ? n.xy : octWrap(n.xy);
    n.xy = n.xy * 0.5 + 0.5;
    return n.xy;
}
 
public float3 octDecode(float2 f)
{
    f = f * 2.0 - 1.0;
 
    // https://twitter.com/Stubbesaurus/status/937994790553227264
    float3 n = float3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
    float t = saturate(-n.z);
    n.xy += select(n.xy >= 0.0, -t, t);
    return normalize(n);
}

public float srgbToLinear(float c) {
    return select(
        c <= float(0.04045),
        c / 12.92,
        pow((c + 0.055) / 1.055, float(2.4))
    );
}

public float3 srgbToLinear(float3 c) {
    return select(
        c <= float3(0.04045),
        c / 12.92,
        pow((c + 0.055) / 1.055, float3(2.4))
    );
}

public float3 linearToSRGB(float3 l) {
    return select(
        l <= float3(0.0031308),
        12.92 * l,
        (1.055) * pow(l, float3(1.0 / 2.4)) - 0.055
    );
}

public float4 encodeColorRgbm16F(float3 color) {
    float maxChannel = max3(color.r, color.g, color.b);
    float norm = clamp(maxChannel / float16_t::maxValue, 1.0, float16_t::maxValue);

    return float4(select(maxChannel > 1e-6, color / norm, 0.0), norm);
}

public float3 decodeColorRgbm16F(float4 colorAndMagnitude) {
    return colorAndMagnitude.rgb * colorAndMagnitude.a;
}

public float3 projectAndDivide(float4x4 invProj, float3 pos) {
    float4 homePos = mul(invProj, float4(pos, 1.0));
    return homePos.xyz / homePos.w;
}

public float pow2(float x) {
    return (x * x);
}

public float2 getLonLatFromUv(float2 uv) {
    uv.y = uv.y * 2.0 - 1.0;
    float s = uv.y >= 0.0 ? 1.0 : -1.0;

    float lat = abs(uv.y) * s * HALF_PI;

    return float2(uv.x, lat);
}

public float2 getUvFromLonLat(float2 lonLat) {
    float s = lonLat.y >= 0.0 ? 1.0 : -1.0;
    float v = abs(lonLat.y) * RCP_HALF_PI * s * 0.5 + 0.5;

    return float2(lonLat.x, v);
}

public float2 getLonLatFromUvNonLinear(float2 uv) {
    uv.y = uv.y * 2.0 - 1.0;
    float s = uv.y >= 0.0 ? 1.0 : -1.0;

    float lat = pow2(abs(uv.y)) * s * HALF_PI;

    return float2(uv.x, lat);
}

public float2 getUvFromLonLatNonLinear(float2 lonLat) {
    float s = lonLat.y >= 0.0 ? 1.0 : -1.0;
    float v = sqrt(abs(lonLat.y) * RCP_HALF_PI) * s * 0.5 + 0.5;

    return float2(lonLat.x, v);
}

public float2 getLonLatFromDir(float3 dir) {
    return float2(atan2(dir.x, -dir.z) / (PI * 2.0) + 0.5, asin(clamp(dir.y, -1.0, 1.0)));
}

public float3 getDirFromLonLat(float2 lonLat) {
    float angle = (lonLat.x - 0.5) * PI * 2.0;
    float cosLat = cos(lonLat.y);

    return float3(sin(angle) * cosLat, sin(lonLat.y), -cos(angle) * cosLat);
}