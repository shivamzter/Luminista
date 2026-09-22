import org.joml.Vector4f;

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

        pipeline.buffer("luminanceHistogramBuffer", Integer.BYTES * 256);
        pipeline.buffer("exposureBuffer", Integer.BYTES * 2);

        // Textures
        tex_shadowColor = pipeline.arrayTexture("tex_shadowColor", TextureFormat.RGBA8_UNORM).shadowSize().create();
    
        var tex_main = pipeline.texture2D("tex_main", TextureFormat.RGBA16_SFLOAT).renderSize().create();
        var tex_normal = pipeline.texture2D("tex_normal", TextureFormat.RGB10A2_UNORM).renderSize().create();

        pipeline.texture2D("tex_skyTransmittanceLUT", TextureFormat.RGBA16_SFLOAT).size(256, 64).create();
        pipeline.texture2D("tex_skyViewLUT", TextureFormat.RGBA16_SFLOAT).size(192, 108).create();
        pipeline.texture2D("tex_skyViewTransmittanceLUT", TextureFormat.RGBA16_SFLOAT).size(192, 108).create();
        // pipeline.texture2D("tex_mulScatterLUT", TextureFormat.RGBA16_SFLOAT).size(32, 32).create();

        pipeline.texture2D("tex_skyScattering", TextureFormat.RGBA16_SFLOAT).size(screen.renderWidth(), screen.renderHeight()).create();
        pipeline.texture2D("tex_skyTransmittance", TextureFormat.RGBA16_SFLOAT).size(screen.renderWidth(), screen.renderHeight()).create();
        
        // Pipeline stages
        pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(tex_shadowColor);

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

        // Object passes
        pipeline.object(ProgramUsage.SKYBOX, "program/object/skybox", "SkyShader");
        pipeline.object(ProgramUsage.SKY_TEXTURES, "program/object/skybox", "SkyShader");
        pipeline.object(ProgramUsage.BASIC, "program/object/deferred_opaque", "DeferredOpaqueShader").writes("color", tex_main).writes("normal", tex_normal);
        pipeline.object(ProgramUsage.TRANSLUCENT, "program/object/forward_translucent", "ForwardTranslucentShader").writes("color", tex_main).writes("normal", tex_normal);


        pipeline.stage(ProgramStage.PRE_RENDER).clearTo(new Vector4f(0.0f), tex_main);
        // Sky
        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("skyTransmittanceLut", "program/composite/skyTransmittanceLut", "main").dispatch2D(Math.ceilDiv(256, 16), Math.ceilDiv(64, 8));
        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("skyViewLut", "program/composite/skyViewLut", "main").dispatch2D(Math.ceilDiv(192, 16), Math.ceilDiv(108, 8));
        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("sky", "program/composite/sky", "main").dispatch2D(sizeX_16, sizeY_16);
        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("deferredLighting", "program/composite/lightOpaqueObjects", "main").dispatch2D(sizeX_16, sizeY_16);
        pipeline.stage(ProgramStage.POST_RENDER).compute("histogram", "program/composite/histogram", "applyHistogram").dispatch3D(sizeX_16, sizeY_16, 1); //Global histogram
        pipeline.stage(ProgramStage.POST_RENDER).compute("histogramAverage", "program/composite/histogramAverage", "applyHistogramAverage").dispatch1D(1); //Calculate average

        
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
