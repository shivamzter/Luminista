import aperture;
import helper.util;

static const float minLogLum = -4;
static const float maxLogLum = 24;
static const float logLumRange = maxLogLum - minLogLum;
static float timeCoeff = 0.5;

RWTexture2D tex_main;
RWStructuredBuffer<uint> luminanceHistogramBuffer;
RWStructuredBuffer<float2> exposureBuffer;

groupshared uint histogramShared[256];

[shader("compute")]
[numthreads(256, 1, 1)]
void applyHistogramAverage(uint3 globalThreadId: SV_DispatchThreadID, uint localIndex: SV_GroupIndex) {

    // Get the count from the histogram buffer
    uint countForThisBin = luminanceHistogramBuffer[localIndex];
    histogramShared[localIndex] = countForThisBin * localIndex;

    GroupMemoryBarrierWithGroupSync();

    luminanceHistogramBuffer[localIndex] = 0;

    [unroll]
    for (uint cutoff = (256 >> 1); cutoff > 0; cutoff >>= 1) {

        if (uint(localIndex) < cutoff) {

            histogramShared[localIndex] += histogramShared[localIndex + cutoff];
        }

        GroupMemoryBarrierWithGroupSync();
    }

    if (localIndex == 0) {
        float numPixels = (ap.game.renderSize.x * ap.game.renderSize.y);

        float weightedLogAverage = (histogramShared[0] / max(numPixels - float(countForThisBin), 1.0)) - 1.0;

        float weightedAvgLum = exp2(((weightedLogAverage / 254.0) * logLumRange) + minLogLum);

        float lumLastFrame = exposureBuffer[0].x;

        float adaptedLum = 0.0;

        if (ap.timing.frameCounter > 1) {
            adaptedLum = lumLastFrame + (weightedAvgLum - lumLastFrame) * ap.timing.lastFrameTime;
        } else {
            adaptedLum = weightedAvgLum;
        }

        float computeEV100 = computeEV100FromAvgLuminance(adaptedLum);
        computeEV100 = clamp(computeEV100, minLogLum, maxLogLum);
        float exposure = convertEV100ToExposure(computeEV100);

        exposureBuffer[0] = float2(adaptedLum, exposure);
    }
}