package h2d.css;

import h2d.css.Defs;

class Style {
	
	public var fontName : Null<String>;
	public var fontSize : Null<Float>;
	public var color : Null<Int>;
	public var backgroundColor : Null<FillStyle>;
	public var borderSize : Null<Float>;
	public var borderColor : Null<FillStyle>;
	public var paddingTop : Null<Float>;
	public var paddingLeft : Null<Float>;
	public var paddingRight : Null<Float>;
	public var paddingBottom : Null<Float>;
	public var width : Null<Float>;
	public var height : Null<Float>;
	public var autoWidth : Null<Bool>;
	public var autoHeight : Null<Bool>;
	public var offsetX : Null<Float>;
	public var offsetY : Null<Float>;
	
	public var layout : Null<Layout>;
	
	/**
	 * Letter spacing is always rounded to nearest Int to prevent texturing issues
	 */
	public var letterSpacing : Null<Int>;
	public var lineSpacing : Null<Int>;
	
	public var horizontalSpacing : Null<Float>;
	public var verticalSpacing : Null<Float>;
	public var marginTop : Null<Float>;
	public var marginLeft : Null<Float>;
	public var marginRight : Null<Float>;
	public var marginBottom : Null<Float>;
	public var increment : Null<Float>;
	public var maxIncrement : Null<Float>;
	public var tickColor : Null<FillStyle>;
	public var tickSpacing : Null<Float>;
	public var dock : Null<DockStyle>;
	public var cursorColor : Null<Int>;
	public var selectionColor : Null<Int>;
	public var overflowHidden : Null<Bool>;
	public var positionAbsolute : Null<Bool>;
	public var icon:Null<hxd.Pixels>;
	public var iconColor : Null<Int>;
	public var iconLeft : Null<Float>;
	public var iconTop : Null<Float>;
	public var display : Null<Bool>;
	
	public var textAlign : Null<TextAlign>;
	public var textVAlign : Null<TextVAlign>;
	public var textTransform : TextTransform;
	public var textPositionX : Null<Float> = null;
	public var textPositionY : Null<Float> = null;
	
	public var backgroundTile : Null<TileStyle>;
	public var backgroundRepeat : Null<RepeatStyle>;
	public var backgroundSize : BackgroundSize;
	
	public var background9sliceTile : Null<TileStyle>;
	public var background9sliceRect : Null<h2d.col.Rect>;
	
	public var backgroundBlend : Null<h2d.BlendMode>;
	public var backgroundFilter : Bool = true;
	public var backgroundColorTransform : Null<Array<ColorTransform>>;
	
	public var textColorTransform : Null<Array<ColorTransform>>;
	
	public var widthIsPercent : Bool=false;
	public var heightIsPercent : Bool = false;
	public var visibility : Bool = true;
	public var opacity : Null<Float> = null;
	public var transform : Null<Array<Transform>> = null;
	
	public var textShadow : h2d.Text.DropShadow = null;
	
	public inline function new() {
	}
	
	public function clone() {
		var s = new Style();
		apply(s);
		return s;
	}
	
	public function apply( s : Style ) {
		if( s.fontName != null ) fontName = s.fontName;
		if( s.fontSize != null ) fontSize = s.fontSize;
		if( s.color != null ) color = s.color;
		if( s.backgroundColor != null ) backgroundColor = s.backgroundColor;
		if( s.backgroundTile != null ) backgroundTile = s.backgroundTile;
		if( s.backgroundRepeat != null ) backgroundRepeat = s.backgroundRepeat;
		if( s.background9sliceTile != null ) background9sliceTile = s.background9sliceTile;
		if( s.background9sliceRect != null ) background9sliceRect = s.background9sliceRect;
		if( s.backgroundBlend != null ) backgroundBlend = s.backgroundBlend;
		if( !s.backgroundFilter) backgroundFilter = s.backgroundFilter;
		if( s.backgroundSize != null ) backgroundSize = s.backgroundSize;
		if( s.borderSize != null ) borderSize = s.borderSize;
		if( s.borderColor != null ) borderColor = s.borderColor;
		if( s.paddingLeft != null ) paddingLeft = s.paddingLeft;
		if( s.paddingRight != null ) paddingRight = s.paddingRight;
		if( s.paddingTop != null ) paddingTop = s.paddingTop;
		if( s.paddingBottom != null ) paddingBottom = s.paddingBottom;
		if( s.offsetX != null ) offsetX = s.offsetX;
		if( s.offsetY != null ) offsetY = s.offsetY;
		if( s.width != null ) width = s.width;
		if( s.height != null ) height = s.height;
		if( s.layout != null ) layout = s.layout;
		if( s.horizontalSpacing != null ) horizontalSpacing = s.horizontalSpacing;
		if( s.verticalSpacing != null ) verticalSpacing = s.verticalSpacing;
		if( s.marginLeft != null ) marginLeft = s.marginLeft;
		if( s.marginRight != null ) marginRight = s.marginRight;
		if( s.marginTop != null ) marginTop = s.marginTop;
		if( s.marginBottom != null ) marginBottom = s.marginBottom;
		if( s.increment != null ) increment = s.increment;
		if( s.maxIncrement != null ) maxIncrement = s.maxIncrement;
		if( s.tickColor != null ) tickColor = s.tickColor;
		if( s.tickSpacing != null ) tickSpacing = s.tickSpacing;
		if( s.dock != null ) dock = s.dock;
		if( s.cursorColor != null ) cursorColor = s.cursorColor;
		if( s.selectionColor != null ) selectionColor = s.selectionColor;
		if ( s.overflowHidden != null ) overflowHidden = s.overflowHidden;
		if( s.icon != null ) icon = s.icon;
		if( s.iconColor != null ) iconColor = s.iconColor;
		if( s.iconLeft != null ) iconLeft = s.iconLeft;
		if( s.iconTop != null ) iconTop = s.iconTop;
		if( s.positionAbsolute != null ) positionAbsolute = s.positionAbsolute;
		if( s.autoWidth != null ) {
			autoWidth = s.autoWidth;
			width = s.width;
		}
		if( s.autoHeight != null ) {
			autoHeight = s.autoHeight;
			height = s.height;
		}
		if( s.textAlign != null ) textAlign = s.textAlign;
		if( s.textVAlign != null ) textVAlign = s.textVAlign;
		if( s.textTransform != null ) textTransform = s.textTransform;
		if( s.textPositionX!=null ) textPositionX = s.textPositionX;
		if( s.textPositionY!=null ) textPositionY = s.textPositionY;
		if( s.textColorTransform != null ) textColorTransform = s.textColorTransform;
		if( s.textShadow != null ) textShadow = s.textShadow;
		if( s.backgroundColorTransform != null ) backgroundColorTransform = s.backgroundColorTransform;
		
		if( s.display != null ) display = s.display;
		
		if( s.widthIsPercent) 		widthIsPercent = s.widthIsPercent;
		if( s.heightIsPercent) 		heightIsPercent = s.heightIsPercent;
		if( s.letterSpacing != null)	letterSpacing = s.letterSpacing;
		if( s.lineSpacing != null)		lineSpacing = s.lineSpacing;
		
		visibility = s.visibility;
		if( s.opacity != null)	opacity = s.opacity;
		if( s.transform != null ) transform = s.transform;
	}
	
	public function padding( v : Float ) {
		this.paddingTop = v;
		this.paddingLeft = v;
		this.paddingRight = v;
		this.paddingBottom = v;
	}

	public function margin( v : Float ) {
		this.marginTop = v;
		this.marginLeft = v;
		this.marginRight = v;
		this.marginBottom = v;
	}
	
	public function get(name:String):Dynamic{
		var cssName = name.split("-").join("");
		for( f in Type.getInstanceFields(Style) ) {
			var v : Dynamic = Reflect.getProperty(this, f);
			if( Reflect.isFunction(v) || f == "toString" || f == "apply" )
				continue;
			if ( f == cssName )
				return v;
		}
		return null;
	}
	
	public function toString() {
		var fields = [];
		for( f in Type.getInstanceFields(Style) ) {
			var v : Dynamic = Reflect.getProperty(this, f);
			if( v == null || Reflect.isFunction(v) || f == "toString" || f == "apply" )
				continue;
			if( f.toLowerCase().indexOf("color") >= 0 && Std.is(v,Int) )
				v = "#" + StringTools.hex(v, 6);
			fields.push(f + ": " + v);
		}
		return "{" + fields.join(", ") + "}";
	}
		
}