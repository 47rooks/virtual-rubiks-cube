package ui;

import haxe.ui.containers.VBox;
import haxe.ui.util.Color;

/**
 * PointLight is a component with all the controls necessary to set point light properties.
 * These include enabling and disabling it, controlling its ambient, diffuse and specular
 * colors and controlling the attenuation. The position is provided separately in code so 
 * this component is really about the light model rather than the light object itself.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/ui/point-light.xml"))
class PointLight extends VBox
{
	@:bind(uiPointLightEnabled.text) public var lightName:String;

	@:bind(uiPointLightEnabled.selected)
	public var pointLight:Bool;

	@:bind(uiPointLightAmbientColor.value)
	public var pointLightAmbientColor(default, null):Color;

	@:bind(uiPointLightDiffuseColor.value)
	public var pointLightDiffuseColor(default, null):Color;

	@:bind(uiPointLightSpecularColor.value)
	public var pointLightSpecularColor(default, null):Color;

	@:bind(uiPointLightKc.pos)
	public var pointLightKc(default, null):Float;

	@:bind(uiPointLightKl.pos)
	public var pointLightKl(default, null):Float;

	@:bind(uiPointLightKq.pos)
	public var pointLightKq(default, null):Float;
}
