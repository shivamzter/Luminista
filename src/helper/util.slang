public static const float PI = 3.14159265359;

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

public float4 encodeColorRgbm16F(float3 color) {
    float magnitude = clamp(max3(color.r, color.g, color.b), 0.0, float16_t::maxValue);

    return float4(select(magnitude > 1e-6, color / magnitude, 0.0), magnitude);
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