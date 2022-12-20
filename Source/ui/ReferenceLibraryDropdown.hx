package ui;

import haxe.ui.components.DropDown;
import haxe.ui.containers.ListView;
import haxe.ui.core.Component;

/**
 * Reference library dropdown support.
 * 
 * To create a HaxeUI dropdown three pieces are needed:
 * 
 *  1. a subclass of DropDown which registers a handler with a symbolic (string) name for the handler.
 *     The class name converted to snake-case is derived from the name of this class.
 *  2. the handler registered above which is referred to in the XML fragment. This handler provides
 *     a method to create an instance of the dropdown view defined below.
 *  3. a view which is a very simple (or not) XML fragment which defines the content of the dropdown
 *     when rendered. In this case ReferenceLibraryDropdownView is the base ReferenceLibrary element.
 */
@:xml('
<dropdown type="referenceLibraryDropdownHandler" width="100%" />
')
class ReferenceLibraryDropdown extends DropDown
{
	public var _selectionMailbox:String = null;

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
	private var _cachedSelectedItem:String = null;

	final REFERENCE_LIBRARY_BASE_TEXT = "Reference Library: ";

	private override function get_component():Component
	{
		if (_view == null)
		{
			_view = new ReferenceLibraryDropdownView();
			var tgt:ListView = cast(_view.findComponent('toc', ListView));
			tgt.onChange = function(e)
			{
				_dropdown.text = REFERENCE_LIBRARY_BASE_TEXT + cast(_view.findComponent('toc', ListView)).selectedItem;
			}
			if (_cachedSelectedItem != null)
			{
				tgt.selectedIndex = getIndex(_cachedSelectedItem);
				_cachedSelectedItem = null;
			}
		}

		var postedSelection = cast(_dropdown, ReferenceLibraryDropdown)._selectionMailbox;
		if (postedSelection != null)
		{
			var tgt:ListView = cast(_view.findComponent('toc', ListView));

			for (i in 0...tgt.dataSource.size)
			{
				trace('d${i}=${cast (tgt.dataSource, Array<Dynamic>)[i]}');
			}

			cast(_dropdown, ReferenceLibraryDropdown)._selectionMailbox = null;
		}
		return _view;
	}

	private override function set_selectedItem(value:Dynamic):Dynamic
	{
		if (_view != null)
		{
			_view.toc.selectedIndex = getIndex(value);
		}
		else
		{
			_cachedSelectedItem = cast(value, String);
			_dropdown.text = REFERENCE_LIBRARY_BASE_TEXT + _cachedSelectedItem;
		}
		return value;
	}

	private function getIndex(v:String):Int
	{
		for (i in 0..._view.toc.dataSource.size)
		{
			var item:String = cast(_view.toc.dataSource.get(i), String);
			if (item == v)
			{
				return i;
			}
		}
		return 0;
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
