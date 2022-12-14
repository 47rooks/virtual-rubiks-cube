package;

import haxe.ui.components.OptionBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.ItemRenderer;
import haxe.ui.events.UIEvent;
import haxe.ui.tooltips.ToolTipManager;
import haxe.ui.util.Color;

using StringTools;

/**
 * UI is basically a bean class providing programmatic access to all properties which may set by
 * HaxeUI widgets as defined in ui.xml.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/ui/ui.xml"))
class UI extends VBox
{
	/* Simple Lighting properties */
	@:bind(ambientStrength.pos)
	public var ambientS(default, null):Float = 0.1;

	@:bind(diffuseStrength.pos)
	public var diffuseS(default, null):Float = 1.0;

	@:bind(specularStrength.pos)
	public var specularS(default, null):Float = 0.75;

	@:bind(specularIntensity)
	public var specularI(default, null):Float = 5.0;

	/* 3-component Lighting Properties */
	@:bind(complex.selected)
	public var componentLightEnabled(default, null):Bool;

	@:bind(lightAmbient.value)
	public var lightAmbientColor(default, null):Color;

	@:bind(lightDiffuse.value)
	public var lightDiffuseColor(default, null):Color;

	@:bind(lightSpecular.value)
	public var lightSpecularColor(default, null):Color;

	/* Light Casters */
	/* Directional */
	@:bind(uiDirectional.selected)
	public var directional(default, null):Bool;

	@:bind(uiLightDirectionalAmbientColor.value)
	public var lightDirectionalAmbientColor(default, null):Color;

	@:bind(uiLightDirectionalDiffuseColor.value)
	public var lightDirectionalDiffuseColor(default, null):Color;

	@:bind(uiLightDirectionalSpecularColor.value)
	public var lightDirectionalSpecularColor(default, null):Color;

	/* Point light */
	@:bind(uiPointLight.selected)
	public var pointLight:Bool;

	@:bind(uiPointLightAmbientColor.value)
	public var pointLightAmbientColor(default, null):Color;

	@:bind(uiPointLightDiffuseColor.value)
	public var pointLightDiffuseColor(default, null):Color;

	@:bind(uiPointLightSpecularColor.value)
	public var pointLightSpecularColor(default, null):Color;

	@:bind(uiPointLightKc)
	public var pointLightKc(default, null):Float;

	@:bind(uiPointLightKl.pos)
	public var pointLightKl(default, null):Float;

	@:bind(uiPointLightKq.pos)
	public var pointLightKq(default, null):Float;

	/* Flashlight */
	@:bind(uiFlashlight.selected)
	public var flashlight:Bool;

	@:bind(uiFlashlightAmbientColor.value)
	public var flashlightAmbientColor(default, null):Color;

	@:bind(uiFlashlightDiffuseColor.value)
	public var flashlightDiffuseColor(default, null):Color;

	@:bind(uiFlashlightSpecularColor.value)
	public var flashlightSpecularColor(default, null):Color;

	@:bind(uiFlashlightKc)
	public var flashlightKc(default, null):Float;

	public var flashlightKl(get, null):Float;

	function get_flashlightKl():Float
	{
		// Division by 100 required so that the UI slider movement works because
		// too small a step doesn't work well.
		return uiFlashlightKl.pos / 100.0;
	}

	public var flashlightKq(get, null):Float;

	function get_flashlightKq():Float
	{
		// Division by 1000 required so that the UI slider movement works because
		// too small a step doesn't work well.
		return uiFlashlightKq.pos / 1000.0;
	}

	@:bind(uiFlashlightCutoff.pos)
	public var flashlightCutoff(default, null):Float;

	/* Material Properties */
	@:bind(useTexture.selected)
	public var textureEnabled(default, null):Bool;

	@:bind(useMaterials.selected)
	public var materialsEnabled(default, null):Bool;

	@:bind(useLightMaps.selected)
	public var lightMapsEnabled(default, null):Bool;

	@:bind(ambient.value)
	public var ambientColor(default, null):Color;

	@:bind(diffuse.value)
	public var diffuseColor(default, null):Color;

	@:bind(specular.value)
	public var specularColor(default, null):Color;

	@:bind(shininess.pos)
	public var specularShininess(default, null):Float = 5;

	// Scene properties
	@:bind(uiSceneRubiks.selected)
	public var sceneRubiks(default, null):Bool;

	@:bind(uiSceneRubiksWithLight.selected)
	public var sceneRubiksWithLight(default, null):Bool;

	@:bind(uiSceneCubeCloud.selected)
	public var sceneCubeCloud(default, null):Bool;

	// Mouse properties
	@:bind(uiMouseTargetsCube.selected)
	public var mouseTargetsCube(default, null):Bool;

	/**
	 * In order to handle the type conversion from Float slider position to Int number
	 * cubes we query the current value when the property is requested.
	 */
	public var numOfCubes(get, null):Int;

	function get_numOfCubes():Int
	{
		return Math.ceil(numCubes.pos);
	}

	public function new()
	{
		super();
		controls.visible = false;
		help.visible = false;
		hudKeyMessage.visible = true;
		visible = true;

		// Tooltips
		var tooltipRenderer = new CustomToolTip();
		/* FIXME - This is temporarily commented out as there is a bug in the tooltip support
		 * that results in this vbox level tooltip overriding tooltips present on components within
		 * the vbox.
		 */
		/*
			ToolTipManager.instance.registerTooltip(configurationControls, {
				renderer: tooltipRenderer,
				tipData: {
					title: "Configuration",
					footer: "",
					content: "Choose one of a variety of initial configuration, setting Lighting, Materials and Scene properties appropriately. From this starting point you may then make tweaks to the various properties to see how they change the rendered scene."
				}
		});*/

		ToolTipManager.instance.registerTooltip(rubiksConfig, {
			renderer: tooltipRenderer,
			tipData: {
				title: "Rubik's Cube (Play)",
				footer: "",
				content: "Just play with the virtual Rubik's cube.\n\nNo special lighting or material effects."
			}
		});

		ToolTipManager.instance.registerTooltip(simplePhongConfig, {
			renderer: tooltipRenderer,
			tipData: {
				title: "Simple Phong Lighting",
				footer: "",
				content: "Simple textured surface with ambient, diffuse and specular light, each of a single color (grayscale) based on a strength value."
			}
		});

		ToolTipManager.instance.registerTooltip(phongConfig, {
			renderer: tooltipRenderer,
			tipData: {
				title: "Phong Lighting and Materials",
				footer: "",
				content: "Using three component colors for materials and also for the ambient, diffuse and specular lighting components."
			}
		});

		ToolTipManager.instance.registerTooltip(lightMapsConfig, {
			renderer: tooltipRenderer,
			tipData: {
				title: "Lighting Maps",
				footer: "",
				content: "Texture is switched to use diffuse and specular lighting map textures, with 3 component lighting, for a more realistic material look."
			}
		});
	}

	public function toggleVisibility():Void
	{
		if (keepHelp.selected)
		{
			controls.visible = !controls.visible;
		}
		else
		{
			controls.visible = !controls.visible;
			help.visible = !help.visible;
		}
	}

	/**
	 * Update the 'simple' lighting field to true if it is false and the
	 * useTexture materials option is selected. This is required because
	 * useTexture material (SimpleCubeProgram) will only support simple
	 * lighting.
	 * @param e UIEvent
	 */
	@:bind(useTexture, UIEvent.PROPERTY_CHANGE)
	public function onChangeUseTexture(e:UIEvent):Void
	{
		var o = cast(e.target, OptionBox);
		if (e.data == 'selected' && o.value && !simple.value)
		{
			simple.value = true;
		}
	}

	@:bind(uiSceneCubeCloud, UIEvent.PROPERTY_CHANGE)
	public function onChangeMultipleCubes(e:UIEvent):Void
	{
		var o = cast(e.target, OptionBox);
		if (e.data == 'selected' && o.value && uiLightCasters.disabled)
		{
			uiLightCasters.disabled = false;
		}
	}
}

@:xml('
<item-renderer layoutName="horizontal" width="350">
    <vbox width="100%">
        <label id="title" style="font-size: 20;" />
        <label id="content" width="100%" />
        <rule />
        <label id="footer" width="100%" style="font-style: italic" />
    </vbox>
</item-renderer>
')
private class CustomToolTip extends ItemRenderer {}
