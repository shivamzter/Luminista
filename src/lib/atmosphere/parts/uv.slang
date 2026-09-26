implementing atmos_all;

public float2 fromUnitToSubUvs(float2 unit, float2 resolution) {
    return (unit + 0.5 / resolution) * (resolution / (resolution + 1.0));
}

public float2 fromSubUvsToUnit(float2 unit, float2 resolution) {
    return (unit - 0.5 / resolution) * (resolution / (resolution - 1.0));
}

public void UvToLutTransmittanceParams(out float viewHeight, out float viewZenithCosAngle, in float2 uv)
{
	float x_mu = uv.x;
	float x_r = uv.y;

	float H = sqrt(ATMOSPHERE_TOP_RADIUS_KM * ATMOSPHERE_TOP_RADIUS_KM - ATMOSPHERE_BOTTOM_RADIUS_KM * ATMOSPHERE_BOTTOM_RADIUS_KM);
	float rho = H * x_r;
	viewHeight = sqrt(rho * rho + ATMOSPHERE_BOTTOM_RADIUS_KM * ATMOSPHERE_BOTTOM_RADIUS_KM);

	float d_min = ATMOSPHERE_TOP_RADIUS_KM - viewHeight;
	float d_max = rho + H;
	float d = d_min + x_mu * (d_max - d_min);
	viewZenithCosAngle = d == 0.0 ? 1.0f : (H * H - rho * rho - d * d) / (2.0 * viewHeight * d);
	viewZenithCosAngle = clamp(viewZenithCosAngle, -1.0, 1.0);
}

public void LutTransmittanceParamsToUv(in float viewHeight, in float viewZenithCosAngle, out float2 uv)
{
	float H = sqrt(max(0.0f, ATMOSPHERE_TOP_RADIUS_KM * ATMOSPHERE_TOP_RADIUS_KM - ATMOSPHERE_BOTTOM_RADIUS_KM * ATMOSPHERE_BOTTOM_RADIUS_KM));
	float rho = sqrt(max(0.0f, viewHeight * viewHeight - ATMOSPHERE_BOTTOM_RADIUS_KM * ATMOSPHERE_BOTTOM_RADIUS_KM));

	float discriminant = viewHeight * viewHeight * (viewZenithCosAngle * viewZenithCosAngle - 1.0) + ATMOSPHERE_TOP_RADIUS_KM * ATMOSPHERE_TOP_RADIUS_KM;
	float d = max(0.0, (-viewHeight * viewZenithCosAngle + sqrt(discriminant))); // Distance to atmosphere boundary

	float d_min = ATMOSPHERE_TOP_RADIUS_KM - viewHeight;
	float d_max = rho + H;
	float x_mu = (d - d_min) / (d_max - d_min);
	float x_r = rho / H;

	uv = float2(x_mu, x_r);
}

// MULTI-SCATTER LUT: texel → height & sun angle (the pass WRITES with this)
public void UvToMulScatterParams(out float viewHeight, out float sunZenithCosAngle, in float2 uv) {
    sunZenithCosAngle = uv.x * 2.0 - 1.0;   // 0 = sun straight down, 1 = sun straight up
    viewHeight = lerp(ATMOSPHERE_BOTTOM_RADIUS_KM + PLANET_RADIUS_OFFSET_KM, ATMOSPHERE_TOP_RADIUS_KM, uv.y);
}

// height & sun angle → UV (the ray march READS with this)
public void MulScatterParamsToUv(in float viewHeight, in float sunZenithCosAngle, out float2 uv) {
    uv = saturate(float2(
        sunZenithCosAngle * 0.5 + 0.5,
        (viewHeight - ATMOSPHERE_BOTTOM_RADIUS_KM) / (ATMOSPHERE_TOP_RADIUS_KM - ATMOSPHERE_BOTTOM_RADIUS_KM)
    ));
}

float4 sampleLevel0(Texture2D tex, SamplerState samp, float2 uv)
{
    return tex.SampleLevel(samp, uv, 0.0);
}

// note: entirely stolen from https://gist.github.com/TheRealMJP/c83b8c0f46b63f3a88a5986f4fa982b1
//
// Samples a texture with Catmull-Rom filtering, using 9 texture fetches instead of 16.
// See http://vec3.ca/bicubic-filtering-in-fewer-taps/ for more details
public float4 SampleTextureCatmullRom( Texture2D tex, SamplerState samp, float2 uv, float2 texSize )
{
    // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
    // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
    // location [1, 1] in the grid, where [0, 0] is the top left corner.
    float2 samplePos = uv * texSize;
    float2 texPos1 = floor(samplePos - 0.5) + 0.5;

    // Compute the fractional offset from our starting texel to our original sample location, which we'll
    // feed into the Catmull-Rom spline function to get our filter weights.
    float2 f = samplePos - texPos1;

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    float2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    float2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    float2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
    float2 w3 = f * f * (-0.5 + 0.5 * f);
    
    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    float2 w12 = w1 + w2;
    float2 offset12 = w2 / w12;

    // Compute the final UV coordinates we'll use for sampling the texture
    float2 texPos0 = texPos1 - float2(1.0);
    float2 texPos3 = texPos1 + float2(2.0);
    float2 texPos12 = texPos1 + offset12;

    texPos0 /= texSize;
    texPos3 /= texSize;
    texPos12 /= texSize;

    float4 result = float4(0.0);
    result += sampleLevel0( tex, samp,float2(texPos0.x,  texPos0.y)) * w0.x * w0.y;
    result += sampleLevel0( tex, samp,float2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += sampleLevel0( tex, samp,float2(texPos3.x,  texPos0.y)) * w3.x * w0.y;

    result += sampleLevel0( tex, samp,float2(texPos0.x,  texPos12.y)) * w0.x * w12.y;
    result += sampleLevel0( tex, samp,float2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += sampleLevel0( tex, samp,float2(texPos3.x,  texPos12.y)) * w3.x * w12.y;

    result += sampleLevel0( tex, samp,float2(texPos0.x,  texPos3.y)) * w0.x * w3.y;
    result += sampleLevel0( tex, samp,float2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += sampleLevel0( tex, samp,float2(texPos3.x,  texPos3.y)) * w3.x * w3.y;

    return result;
}