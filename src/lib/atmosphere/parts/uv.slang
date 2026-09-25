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