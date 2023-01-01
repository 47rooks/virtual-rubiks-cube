package ui;

import haxe.ui.components.Label;
import haxe.ui.components.OptionBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
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

	/* Point lights */
	@:isVar public var pointLight1(get, null):PointLight;

	function get_pointLight1():PointLight
	{
		return uiPointLight1;
	}

	@:isVar public var pointLight2(get, null):PointLight;

	function get_pointLight2():PointLight
	{
		return uiPointLight2;
	}

	@:isVar public var pointLight3(get, null):PointLight;

	function get_pointLight3():PointLight
	{
		return uiPointLight3;
	}

	@:isVar public var pointLight4(get, null):PointLight;

	function get_pointLight4():PointLight
	{
		return uiPointLight4;
	}

	/**
	 * Get the specific point light. This method allows access to the
	 * lights as if they were in an Array which better suites the array
	 * binding in the shader.
	 * 
	 * @param idx number of the light, 0 to NUM_POINT_LIGHTS - 1
	 * @return PointLight the specified point light.
	 */
	public function pointLight(idx:Int):PointLight
	{
		switch (idx)
		{
			case 0:
				return pointLight1;
			case 1:
				return pointLight2;
			case 2:
				return pointLight3;
			case 3:
				return pointLight4;
			default:
				throw "invalid pointlight";
		}
	}

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

	@:bind(uiFlashlightCutoff.start)
	public var flashlightInnerCutoff(default, null):Float;

	@:bind(uiFlashlightCutoff.end)
	public var flashlightOuterCutoff(default, null):Float;

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

	@:bind(uiSceneModelLoading.selected)
	public var sceneModelLoading(default, null):Bool;

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
		references.visible = false;
		visible = true;

		// Tooltips
		var tooltipRenderer = new CustomToolTip();
		/* FIXME - This is temporarily commented out as there is a bug in the tooltip support
		 * that results in this vbox level tooltip overriding tooltips present on components within
		 * the vbox.
		 */
		ToolTipManager.instance.registerTooltip(configurationControls, {
			renderer: tooltipRenderer,
			tipData: {
				title: "Configuration",
				footer: "",
				content: "Choose one of a variety of initial configuration, setting Lighting, Materials and Scene properties appropriately. From this starting point you may then make tweaks to the various properties to see how they change the rendered scene."
			}
		});

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
		if (!keepHelp.selected)
		{
			help.visible = !help.visible;
		}
		controls.visible = !controls.visible;
		references.visible = !references.visible;
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

	@:bind(configurationGrpId, UIEvent.CHANGE)
	public function onChangeConfiguration(e:UIEvent):Void
	{
		var tgt = cast(e.target, OptionBox);
		if (tgt.userData != null)
		{
			var refLib:ReferenceLibraryDropdown = cast(findComponent('referencesContainer'), ReferenceLibraryDropdown);
			var toc:Label = findComponent('titleId', Label);
			refLib.selectedItem = tgt.userData;
		}
	}

	/* Reset default values for lighting properties. This function deliberately
	 * does not set selected flags. There is an issue where setting the same
	 * flag in a single callback pass leads to odd states. So states like "selected"
	 * are only set in the configuration callback itself.
	 */
	function resetLightingValues(disableNoLight = false, disableSimpleLighting:Bool = false, disableComplexLighting:Bool = false,
			disableLightCasters:Bool = false)
	{
		ambientStrength.pos = 0.1;
		diffuseStrength.pos = 1.0;
		specularStrength.pos = 0.75;
		specularIntensity.pos = 5.0;
		lightAmbient.value = 0x191919;
		lightDiffuse.value = 0x808080;
		lightSpecular.value = 0xffffff;
		noLight.disabled = disableNoLight;
		simple.disabled = disableSimpleLighting;
		complex.disabled = disableComplexLighting;
		uiLightCasters.disabled = disableLightCasters;
	}

	/* Reset the default values for the materials properties. Again state flags
	 * that might also be set in the configuration callback itself are not touched.
	 */
	function resetMaterialsValues(disableNoTexture = false, disableUseTexture:Bool = false, disableUseMaterials:Bool = false, disableUseLightMaps:Bool = false)
	{
		ambient.value = 0x00190f;
		diffuse.value = 0x008181;
		specular.value = 0x7f7f7f;
		shininess.pos = 5.0;
		noTexture.disabled = disableNoTexture;
		useTexture.disabled = disableUseTexture;
		useMaterials.disabled = disableUseMaterials;
		useLightMaps.disabled = disableUseLightMaps;
	}

	function resetSceneValues(disableSceneRubiks:Bool = false, disableSceneRubiksWithLight:Bool = false, disableSceneCubeCloud:Bool = false,
			disableSceneModelLoading:Bool = false)
	{
		uiSceneRubiks.disabled = disableSceneRubiks;
		uiSceneRubiksWithLight.disabled = disableSceneRubiksWithLight;
		uiSceneCubeCloud.disabled = disableSceneCubeCloud;
		uiSceneModelLoading.disabled = disableSceneModelLoading;
	}

	/* Simple Rubik's cube with colored faces only and no light or lighting */
	@:bind(rubiksConfig, UIEvent.CHANGE)
	function rubiksConfigFn(_)
	{
		resetLightingValues(false, true, true, true);
		resetMaterialsValues(false, true, true, true);
		resetSceneValues(false, true, true, true);

		// Set to basic Rubik's cube play mode
		noTexture.selected = true;
		noLight.selected = true;
		uiSceneRubiks.selected = true;
		uiMouseTargetsCube.selected = true;
	}

	/* Rubik's cube with light, textured, colored faces, and simple phong
		lighting */
	@:bind(simplePhongConfig, UIEvent.CHANGE)
	function phongConfigFn(_)
	{
		resetLightingValues(true, false, true, true);
		resetMaterialsValues(true, false, true, true);
		resetSceneValues(true, false, true, true);

		// Lighting
		simple.selected = true;

		// Materials
		useTexture.selected = true;

		// Scene
		uiSceneRubiksWithLight.selected = true;
	}

	/* Rubik's cube with light, textured, colored faces, and three component
	 * phong materials and lighting.
	 */
	@:bind(phongConfig, UIEvent.CHANGE)
	function phongMaterialsConfigFn(_)
	{
		resetLightingValues(true, true, false, true);
		resetMaterialsValues(true, true, false, true);
		resetSceneValues(true, false, true, true);

		// Lighting
		complex.selected = true;

		// Materials
		useMaterials.selected = true;

		// Scene
		uiSceneRubiksWithLight.selected = true;
	}

	/* Rubik's cube with light, lighting maps, and three component phong
		lighting. */
	@:bind(lightMapsConfig, UIEvent.CHANGE)
	function lightMapsConfigFn(_)
	{
		resetLightingValues(true, true, false, true);
		resetMaterialsValues(true, true, true, false);
		resetSceneValues(true, false, true, true);

		// Lighting
		complex.selected = true;

		// Materials
		useLightMaps.selected = true;

		// Scene
		uiSceneRubiksWithLight.selected = true;
	}

	@:bind(lightCastersConfig, UIEvent.CHANGE)
	function lightCastersConfigFn(_)
	{
		resetLightingValues(true, true, true, false);
		resetMaterialsValues(true, true, true, false);
		resetSceneValues(true, true, false, true);

		// Enable light casters and cube cloud
		uiLightCasters.selected = true;

		// Materials
		useLightMaps.selected = true;

		// Scene
		uiSceneCubeCloud.selected = true;
		numCubes.pos = 10;

		uiMouseTargetsCube.selected = false;
	}

	@:bind(modelLoadingConfig, UIEvent.CHANGE)
	function modelLoadingConfigFn(_)
	{
		resetLightingValues(true, true, true, false);
		resetMaterialsValues(true, true, true, false);
		resetSceneValues(true, true, true, false);

		// Enable light casters and cube cloud
		uiLightCasters.selected = true;

		// Materials
		useLightMaps.selected = true;

		// Scene
		uiSceneModelLoading.selected = true;

		uiMouseTargetsCube.selected = false;
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
