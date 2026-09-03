import aperture;
import settings;

public float3 PBRNeutralToneMapping(float3 color) {
  const float startCompression = 0.8 - 0.04;
  const float desaturation = 0.15;

  float x = min(color.r, min(color.g, color.b));
  float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
  color -= offset;

  float peak = max(color.r, max(color.g, color.b));
  if (peak < startCompression) return color;

  const float d = 1. - startCompression;
  float newPeak = 1. - d * d / (peak + d - startCompression);
  color *= newPeak / peak;

  float g = 1. - 1. / (desaturation * (peak - newPeak) + 1.);
  return lerp(color, newPeak * float3(1, 1, 1), g);
}

public float3 agxDefaultContrastApprox(float3 x)
{
    float3 x2 = x * x;
    float3 x4 = x2 * x2;
    return + 15.5    * x4 * x2
           - 40.14    * x4 * x
           + 31.96    * x4
           - 6.868    * x2 * x
           + 0.4298   * x2
           + 0.1191   * x
           - 0.00232;
}

public float3 agx(float3 val)
{
    const float3x3 agxMat = float3x3(
        0.842479062253094, 0.0423282422610123, 0.0423756549057051,
        0.0784335999999992, 0.878468636469772,  0.0784336,
        0.0792237451477643, 0.0791661274605434,  0.879142973793104);

    const float minEv = -12.47393;
    const float maxEv = 4.026069;

    val = mul(val, agxMat);
    val = clamp(log2(max(val, 1e-6)), minEv, maxEv);
    val = (val - minEv) / (maxEv - minEv);

    return agxDefaultContrastApprox(val);
}

public float3 agxLook(float3 val)
{
    const float3 lw = float3(0.2126, 0.7152, 0.0722);
    float luma = dot(val, lw);

    float3 offset = float3(0.0, 0.0, 0.0);
    float3 slope  = float3(1.0, 1.0, 1.0);
    float3 power  = float3(1.0, 1.0, 1.0);
    float sat = 1.0;

#if AGX_LOOK == 1
    slope = float3(1.0, 0.9, 0.5); power = float3(0.8, 0.8, 0.8); sat = 0.8;
#elif AGX_LOOK == 2
    slope = float3(1.0, 1.0, 1.0); power = float3(1.35, 1.35, 1.35); sat = 1.4;
#endif

    val = pow(val * slope + offset, power);
    return luma + sat * (val - luma);
}

public float3 agxEotf(float3 val)
{
    const float3x3 agxMatInv = float3x3(
         1.19687900512017,  -0.0528968517574562, -0.0529716355144438,
        -0.0980208811401368, 1.15190312990417,   -0.0980434501171241,
        -0.0990297440797205, -0.0989611768448433,  1.15107367264116);

    val = mul(val, agxMatInv);
    val = pow(max(val, 0.0), 2.2); // undoes the perceptual encoding baked into the contrast fit
    return val;
}

public float3 applyAgX(float3 color)
{
    color = agx(color);
    color = agxLook(color);
    color = agxEotf(color);
    return color;
}

// ACES Filmic fit — matrix-based RRT+ODT approximation
// Source: Stephen Hill (https://github.com/selfshadow/ltc_code), widely used as "ACESFitted"

public float3 RRTAndODTFit(float3 v)
{
    float3 a = v * (v + 0.0245786) - 0.000090537;
    float3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

public float3 acesFilmicToneMapping(float3 color)
{
    const float3x3 acesInputMat = float3x3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777);

    const float3x3 acesOutputMat = float3x3(
         1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602);

    color = mul(color, acesInputMat);
    color = RRTAndODTFit(color);
    color = mul(color, acesOutputMat);
    color = clamp(color, 0.0, 1.0);

    return color;
}

public float3 reinhardLuminanceToneMapping(float3 color)
{
    const float3 lw = float3(0.2126, 0.7152, 0.0722); // Rec.709 luminance weights

    float luminance = dot(color, lw);
    float toneMappedLuminance = luminance / (1.0 + luminance);

    // Avoid divide-by-zero on pure black
    float scale = luminance > 0.0 ? toneMappedLuminance / luminance : 0.0;

    return color * scale;
}