package;

import haxe.ui.components.OptionBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.ItemRenderer;
import haxe.ui.events.UIEvent;
import haxe.ui.tooltips.ToolTipManager;
import haxe.ui.util.Color;

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
		// current custom tooltips must be assigned in code
		ToolTipManager.instance.registerTooltip(rubiksConfig, {
			renderer: tooltipRenderer,
			tipData: {
				title: "Rubik's Cube (Play)",
				footer: "",
				content: "Just play with the virtual Rubik's cube.\n\nNo special lighting or material effects."
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
		if (e.data == 'selected' && o.value && directional.disabled)
		{
			directional.disabled = false;
		}
	}
}

@:xml('
<item-renderer layoutName="horizontal" width="350">
    <vbox width="100%">
        <label id="title" style="font-size: 20;text-decoration:underline" />
        <label id="content" width="100%" />
        <rule />
        <label id="footer" width="100%" style="font-style: italic" />
    </vbox>
</item-renderer>
')
private class CustomToolTip extends ItemRenderer {}
