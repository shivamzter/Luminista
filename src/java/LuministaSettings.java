import dev.irisshaders.aperture.api.PackSettings;
import dev.irisshaders.aperture.api.settings.OptionType;
import dev.irisshaders.aperture.api.settings.SettingsManager;
import dev.irisshaders.aperture.api.settings.SettingsScreen;

public class LuministaSettings implements PackSettings {

    @Override
    public void createSettings(SettingsManager manager, SettingsScreen screen) {
		final var screenResourcePack = screen.child("resourcePack");
		screenResourcePack.option("NORMAL_MAPPING", OptionType.boolType(true), false);
		screenResourcePack.option("MATERIAL_AO", OptionType.boolType(true), false);

		final var screenLighting = screen.child("lighting");

		final var screenIndirectLighting = screenLighting.child("indirectLighting");
		screenIndirectLighting.option("SSAO", OptionType.boolType(true), false);
		screenIndirectLighting.option("VANILLA_AO", OptionType.boolType(true), false);

		final var screenShadow = screenLighting.child("shadow");
        screenShadow.option("SHADOW_ENABLED", OptionType.boolType(true), false);
        screenShadow.option(
			"SHADOW_CASCADE_COUNT",
			OptionType.intType(1, 16, 1, 4),
			false
		);
        screenShadow.option(
			"SHADOW_RESOLUTION",
			OptionType.intType(512, 4096, 512, 2048),
			false
		);
        screenShadow.option(
			"SHADOW_DISTANCE",
			OptionType.intType(16, 1024, 16, 160),
			false
		);

		final var screenPostProcess = screen.child("postProcess");
		screenPostProcess.option("TONE_MAPPING", OptionType.enumType("ToneMapping", 1, "Reinhard", "PBRNeutral", "ReinhardLuminance"), false);

		final var screenDebugView = screen.child("debug");
        screenDebugView.option("DEBUG_VIEW", OptionType.boolType(false), false);
    }
    
}
