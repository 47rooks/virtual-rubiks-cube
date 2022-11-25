package;

import haxe.ui.containers.VBox;
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
	public var textureEnabled(default, null):Bool = true;

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

	public function new()
	{
		super();
		visible = false;
	}

	public function toggleVisibility():Void
	{
		visible = !visible;
	}
}
