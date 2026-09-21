import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;

public class Luminista implements ShaderPack {

    public ArrayTexture tex_shadowColor;

    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {

        // Math
        var sizeX_16 = Math.ceilDiv(screen.renderWidth(), 16);
        var sizeY_16 = Math.ceilDiv(screen.renderHeight(), 16);

        Buffer luminanceHistogramBuffer = pipeline.buffer("luminanceHistogramBuffer", Integer.BYTES * 256);
        Buffer exposureBuffer = pipeline.buffer("exposureBuffer", Integer.BYTES * 2);

        // Textures
        tex_shadowColor = pipeline.arrayTexture("tex_shadowColor", TextureFormat.RGBA8_UNORM).shadowSize().create();
    
        var tex_main = pipeline.texture2D("tex_main", TextureFormat.RGBA16_SFLOAT).renderSize().create();
        var tex_normal = pipeline.texture2D("tex_normal", TextureFormat.RGB10A2_UNORM).renderSize().create();
        
        // Pipeline stages
        pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(tex_shadowColor);

        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("deferredLighting", "program/composite/lightOpaqueObjects", "main").dispatch2D(sizeX_16, sizeY_16);
        pipeline.stage(ProgramStage.POST_RENDER).compute("histogram", "program/composite/histogram", "applyHistogram").dispatch3D(sizeX_16, sizeY_16, 1); //Global histogram
        pipeline.stage(ProgramStage.POST_RENDER).compute("histogramAverage", "program/composite/histogramAverage", "applyHistogramAverage").dispatch1D(1); //Calculate average

        // Object passes
        pipeline.object(ProgramUsage.BASIC, "program/object/deferred_opaque", "DeferredOpaqueShader").writes("color", tex_main).writes("normal", tex_normal);
        pipeline.object(ProgramUsage.TRANSLUCENT, "program/object/forward_translucent", "ForwardTranslucentShader").writes("color", tex_main).writes("normal", tex_normal);

        // Shadow passes
        if (pipeline.settings().getBoolValue("SHADOW_ENABLED")) {

            final var translucentShadowUsages = new ProgramUsage[] {
			ProgramUsage.SHADOW_TERRAIN_TRANSLUCENT,
			ProgramUsage.SHADOW_ENTITY_TRANSLUCENT,
			ProgramUsage.SHADOW_BLOCK_ENTITY_TRANSLUCENT,
			ProgramUsage.SHADOW_PARTICLES_TRANSLUCENT
		    };

            pipeline.object(ProgramUsage.SHADOW, "program/object/shadow_opaque", "ShadowOpaqueShader");

            for (var usage : translucentShadowUsages) {
            pipeline.object(usage, "program/object/shadow_translucent", "ShadowTranslucentShader").writes("color", tex_shadowColor, new BlendMode(BlendFactors.SRC_ALPHA, BlendFactors.ONE_MINUS_SRC_ALPHA, BlendFactors.ONE, BlendFactors.ONE_MINUS_SRC_ALPHA));
            }
        }

        // Combination pass
        pipeline.combinationPass("program/post/combination");
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(23.47f);
        rendererConfig.setShadowCascades(rendererConfig.getSettings().getIntValue("SHADOW_CASCADE_COUNT"));
        rendererConfig.setShadowDistance(rendererConfig.getSettings().getIntValue("SHADOW_DISTANCE"));
        rendererConfig.setShadowResolution(rendererConfig.getSettings().getIntValue("SHADOW_RESOLUTION"));
        rendererConfig.enableRT();
    }
}
