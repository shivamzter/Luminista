// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
public float3 aces(float3 x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

public float aces(float x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

// Khronos PBR Neutral Tone Mapper
// https://github.com/KhronosGroup/ToneMapping/tree/main/PBR_Neutral
public float3 PBRNeutralToneMapping(float3 color) {
  const float startCompression = 0.8 - 0.04;
  const float desaturation = 0.15;

  float x = min(color.r, min(color.g, color.b));
  float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
  color -= offset;

  float peak = max(color.r, max(color.g, color.b));
  if (peak < startCompression) return color;

  const float d = 1.0 - startCompression;
  float newPeak = 1.0 - d * d / (peak + d - startCompression);
  color *= newPeak / peak;

  float g = 1.0 - 1.0 / (desaturation * (peak - newPeak) + 1.0);
  return lerp(color, newPeak * float3(1, 1, 1), g);
}

// https://64.github.io/tonemapping/#reinhard-jodie
public float3 reinhardJodie(float3 x) {
  const float3 lw = float3(0.2126, 0.7152, 0.0722);

  float l = dot(x, lw);
  float3 tv = x / (1.0 + x);

  return lerp(x / (1.0 + l), tv, tv);
}

// reinhard2
public float3 reinhard2(float3 x) {
  const float L_white = 4.0;

  return (x * (1.0 + x / (L_white * L_white))) / (1.0 + x);
}

public float reinhard2(float x) {
  const float L_white = 4.0;

  return (x * (1.0 + x / (L_white * L_white))) / (1.0 + x);
}

// reinhard
public float3 reinhard(float3 x) {
  return x / (1.0 + x);
}

public float reinhard(float x) {
  return x / (1.0 + x);
}