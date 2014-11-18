package h2d.css;

enum Unit {
	Pix( v : Float );
	Percent( v : Float );
	EM( v : Float );
}

enum FillStyle {
	Transparent;
	Color( c : Int );
	Gradient( a : Int, b : Int, c : Int, d : Int );
}

enum Layout {
	Horizontal;
	Vertical;
	Absolute;
	Dock;
	Inline;
}

enum DockStyle {
	Top;
	Left;
	Right;
	Bottom;
	Full;
}

enum TextAlign {
	Left;
	Right;
	Center;
}

enum FileMode {
	Assets;
}

enum BackgroundSize{
	Auto; //fit to width and height
	Cover; //crop to width keeping aspect
	Contain; //crop to width keeping aspect
	Percent(w:Float, h:Float);
	Rect(w:Float, h:Float);
}

class TileStyle {
	public var mode 	: FileMode;
	public var file		: String;
	
	public var x 		: Float = 0.0;
	public var y 		: Float = 0.0;
	public var w 		: Float = 0.0;
	public var h 		: Float = 0.0;
	
	public var dx 		: Float = 0.0;
	public var dy 		: Float = 0.0;
	
	public function new() {
		
	}
}

enum RepeatStyle {
	Repeat;
	RepeatX;
	RepeatY;
	NoRepeat;
}

class CssClass {
	public var parent : Null<CssClass>;
	public var node : Null<String>;
	public var className : Null<String>;
	public var pseudoClass : Null<String>;
	public var id : Null<String>;
	public function new() {
	}
}
