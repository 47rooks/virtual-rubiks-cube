package ui;

import haxe.ui.containers.ListView;
import haxe.ui.containers.TableView;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import openfl.Assets;

typedef LibEntry =
{
	var title:String;
	var description:String;
	var learnopenglReferences:Array<String>;
	var codeReferences:Array<String>;
	var uiReferences:Array<String>;
}

/**
 * A ReferenceLibrary is a custom component to display more expansive help information about the graphics programming in each configuration. It includes reference information for the book, code and the UI.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/ui/reference-library.xml"))
class ReferenceLibrary extends VBox
{
	@:bind(titleId.text) public var title:String;

	@:bind(descriptionId.text) public var description:String;

	var _RefDb:Array<LibEntry>;

	public function new()
	{
		super();
		loadReferenceDb();

		// Enable copying from the labels
		titleId.getTextDisplay().textField.selectable = true;
		titleId.getTextDisplay().textField.mouseEnabled = true;
		descriptionId.getTextDisplay().textField.selectable = true;
		descriptionId.getTextDisplay().textField.mouseEnabled = true;
	}

	function loadReferenceDb():Void
	{
		_RefDb = haxe.Json.parse(Assets.getText("assets/ui/references.json"));

		for (e in _RefDb)
		{
			cast(findComponent('toc'), ListView).dataSource.add(e.title);
		}
	}

	@:bind(toc, UIEvent.CHANGE)
	function displayEntry(e:UIEvent):Void
	{
		var brt:TableView = findComponent('book-references-table');
		var crt:TableView = findComponent('code-references-table');
		for (e in _RefDb)
		{
			if (e.title == toc.selectedItem)
			{
				titleId.text = e.title;
				descriptionId.text = e.description;
				brt.dataSource.clear();
				if (e.learnopenglReferences != null)
				{
					for (r in e.learnopenglReferences)
					{
						brt.dataSource.add({chapter: r});
					}
				}
				crt.dataSource.clear();
				if (e.codeReferences != null)
				{
					for (r in e.codeReferences)
					{
						crt.dataSource.add(r);
					}
				}
			}
		}
	}
}
