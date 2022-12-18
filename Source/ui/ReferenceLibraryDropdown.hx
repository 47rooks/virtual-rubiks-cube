package ui;

import haxe.ui.components.DropDown;
import haxe.ui.containers.ListView;
import haxe.ui.core.Component;

@:xml('
<dropdown type="referenceLibraryDropdownHandler" width="100%" />
')
class ReferenceLibraryDropdown extends DropDown
{
	public function new()
	{
		super();
		DropDownBuilder.HANDLER_MAP.set("referenceLibraryDropdownHandler", Type.getClassName(ReferenceLibraryDropdownHandler));
	}
}

@:access(haxe.ui.core.Component)
class ReferenceLibraryDropdownHandler extends DropDownHandler
{
	private var _view:ReferenceLibraryDropdownView = null;

	private override function get_component():Component
	{
		if (_view == null)
		{
			_view = new ReferenceLibraryDropdownView();
			var tgt:ListView = cast(_view.findComponent('toc', ListView));
			tgt.onChange = function(e)
			{
				_dropdown.text = "Reference Library: " + cast(_view.findComponent('toc', ListView)).selectedItem;
			}
		}
		return _view;
	}
}

@:xml('
<reference-library styleName="referencesBox"></reference-library>
')
class ReferenceLibraryDropdownView extends ReferenceLibrary
{
	public function new()
	{
		super();
	}
}
