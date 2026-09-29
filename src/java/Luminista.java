import org.joml.Vector4f;

import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;

public class Luminista implements ShaderPack {

    public ArrayTexture tex_shadowColor;

    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {

        // MISC ////////////////////
        final var translucentShadowUsages = new ProgramUsage[] {
		    ProgramUsage.SHADOW_TERRAIN_TRANSLUCENT,
		    ProgramUsage.SHADOW_ENTITY_TRANSLUCENT,
		    ProgramUsage.SHADOW_BLOCK_ENTITY_TRANSLUCENT,
		    ProgramUsage.SHADOW_PARTICLES_TRANSLUCENT
		};

        var sizeX_16 = Math.ceilDiv(screen.renderWidth(), 16);
        var sizeY_16 = Math.ceilDiv(screen.renderHeight(), 16);

        // BUFFERS ////////////////////
        pipeline.buffer("luminanceHistogramBuffer", Integer.BYTES * 256);
        pipeline.buffer("exposureBuffer", Integer.BYTES * 2);

        // TEXTURES ////////////////////
        tex_shadowColor = pipeline.arrayTexture("tex_shadowColor", TextureFormat.RGBA8_UNORM).shadowSize().create();
    
        var tex_main = pipeline.texture2D("tex_main", TextureFormat.RGBA16_SFLOAT).renderSize().create();
        var tex_normal = pipeline.texture2D("tex_normal", TextureFormat.RGB10A2_UNORM).renderSize().create();
        var tex_lightMap = pipeline.texture2D("tex_lightMap", TextureFormat.RGBA8_UNORM).renderSize().create();
        var tex_labSpecular = pipeline.texture2D("tex_labSpecular", TextureFormat.RGBA16_SFLOAT).renderSize().create();

        var tex_translucentMain = pipeline.texture2D("tex_translucentMain", TextureFormat.RGBA16_SFLOAT).renderSize().create();
        var tex_translucentNormal = pipeline.texture2D("tex_translucentNormal", TextureFormat.RGB10A2_UNORM).renderSize().create();
        var tex_translucentLightMap = pipeline.texture2D("tex_translucentLightMap", TextureFormat.RGBA8_UNORM).renderSize().create();

        pipeline.texture2D("tex_skyTransmittanceLUT", TextureFormat.RGBA16_SFLOAT).size(256, 64).create();
        // pipeline.texture2D("tex_skyMulScatterLUT", TextureFormat.RGBA16_SFLOAT).size(32, 32).create();
        pipeline.texture2D("tex_skyViewScatteringLUT", TextureFormat.RGBA16_SFLOAT).size(192, 108).create();
        pipeline.texture2D("tex_skyViewTransmittanceLUT", TextureFormat.RGBA16_SFLOAT).size(192, 108).create();
        
        // STAGES AND OBJECT PASSES ////////////////////
        pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(tex_shadowColor);

        pipeline.object(ProgramUsage.SHADOW, "program/object/shadow_opaque", "ShadowOpaqueShader");

        for (var usage : translucentShadowUsages) {
            pipeline.object(usage, "program/object/shadow_translucent", "ShadowTranslucentShader").writes("color", tex_shadowColor, new BlendMode(BlendFactors.SRC_ALPHA, BlendFactors.ONE_MINUS_SRC_ALPHA, BlendFactors.ONE, BlendFactors.ONE_MINUS_SRC_ALPHA));
        }

        pipeline.object(ProgramUsage.SKYBOX, "program/object/skybox", "SkyShader");
        pipeline.object(ProgramUsage.SKY_TEXTURES, "program/object/skybox", "SkyShader");
        pipeline.object(ProgramUsage.BASIC, "program/object/deferred_opaque", "DeferredOpaqueShader")
        .writes("color", tex_main)
        .writes("normal", tex_normal)
        .writes("lightMap", tex_lightMap)
        .writes("labSpecular", tex_labSpecular);
        
        pipeline.object(ProgramUsage.TRANSLUCENT, "program/object/deferred_translucent", "DeferredTranslucentShader")
        .writes("color", tex_translucentMain)
        .writes("normal", tex_translucentNormal)
        .writes("lightMap", tex_translucentLightMap)
        .writes("labSpecular", tex_labSpecular);

        pipeline.stage(ProgramStage.PRE_RENDER).clearTo(new Vector4f(0.0f), tex_translucentMain);
        pipeline.stage(ProgramStage.PRE_RENDER).clearTo(new Vector4f(0.0f), tex_main);

        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("skyTransmittanceLut", "program/composite/skyTransmittanceLut", "main").dispatch2D(Math.ceilDiv(256, 16), Math.ceilDiv(64, 8));
        // pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("skyMulScatterLut", "program/composite/skyMulScatterLut", "main").dispatch2D(Math.ceilDiv(32, 16), Math.ceilDiv(32, 8));
        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("skyViewLut", "program/composite/skyViewLut", "main").dispatch2D(Math.ceilDiv(192, 16), Math.ceilDiv(108, 8));
        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("sky", "program/composite/sky", "main").dispatch2D(sizeX_16, sizeY_16);
        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("opaqueLighting", "program/composite/lightOpaqueObjects", "main").dispatch2D(sizeX_16, sizeY_16);
        pipeline.stage(ProgramStage.POST_RENDER).compute("translucentLighting", "program/composite/lightTranslucentObjects", "main").dispatch2D(sizeX_16, sizeY_16);
        pipeline.stage(ProgramStage.POST_RENDER).compute("histogram", "program/composite/histogram", "applyHistogram").dispatch3D(sizeX_16, sizeY_16, 1); //Global histogram
        pipeline.stage(ProgramStage.POST_RENDER).compute("histogramAverage", "program/composite/histogramAverage", "applyHistogramAverage").dispatch1D(1); //Calculate average

        
        // COMBINATION PASS, A.K.A Final ////////////////////
        pipeline.combinationPass("program/post/combination");
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.enableRT();
        rendererConfig.setSunPathRotation(23.47f);
        rendererConfig.setShadowDistance(rendererConfig.getSettings().getIntValue("SHADOW_DISTANCE"));
    }
}
