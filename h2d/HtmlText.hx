package h2d;

class HtmlText extends Drawable {

	public var font(default, set) : Font;
	public var htmlText(default, set) : String;
	public var textColor(default, set) : Int;
	
	public var textWidth(get, null) : Int;
	public var textHeight(get, null) : Int;
	
	public var letterSpacing : Int;
	public var maxWidth : Null<Float>;
	
	var glyphs : TileColorGroup;
	
	public function new( font : Font, ?parent ) {
		super(parent);
		this.font = font;
		htmlText = "";
		shader = glyphs.shader;
		textColor = 0xFFFFFF;
	}
	
	public inline function nbQuad() {
		return htmlText.length;
	}
	
	override function onAlloc() {
		super.onAlloc();
		if( htmlText != null ) initGlyphs();
	}
	
	function set_font(f) {
		this.font = f;
		
		if ( glyphs != null ) {
			glyphs.remove();
			glyphs = null;
		}
			
		glyphs = new TileColorGroup(font == null ? null : font.tile, this);
		this.htmlText = htmlText;
		return f;
	}
	
	function set_htmlText(t) {
		this.htmlText = t == null ? "null" : t;
		if( allocated ) initGlyphs();
		return t;
	}
	
	function initGlyphs( ?rebuild = true ) {
		if( rebuild ) glyphs.reset();
		glyphs.setDefaultColor(textColor);
		var x = 0, y = 0, xMax = 0;
		function loop( e : Xml ) {
			if( e.nodeType == Xml.Element ) {
				var colorChanged = false;
				switch( e.nodeName.toLowerCase() ) {
				case "font":
					for( a in e.attributes() ) {
						var v = e.get(a);
						switch( a.toLowerCase() ) {
						case "color":
							colorChanged = true;
							glyphs.setDefaultColor(Std.parseInt("0x" + v.substr(1)));
						default:
						}
					}
				case "br":
					if( x > xMax ) xMax = x;
					x = 0;
					y += font.lineHeight;
				default:
				}
				for( child in e )
					loop(child);
				if( colorChanged )
					glyphs.setDefaultColor(textColor);
			} else {
				var t = e.nodeValue;
				var prevChar = -1;
				for( i in 0...haxe.Utf8.length(t) ) {
					var cc = haxe.Utf8.charCodeAt( t,i );
					var e = font.getChar(cc);
					x += e.getKerningOffset(prevChar);
					if( rebuild ) glyphs.add(x, y, e.t);
					x += e.width + letterSpacing;
					if ( maxWidth != null ) {
						if ( x > maxWidth ) {
							if( x > xMax ) xMax = x;	
							x = 0;
							y += font.lineHeight;
						}
					}
					prevChar = cc;
				}
			}
		}
		for( e in Xml.parse(htmlText) )
			loop(e);
		return { width : x > xMax ? x : xMax, height : x > 0 ? y + font.lineHeight : y };
	}
	
	function get_textHeight() {
		return initGlyphs(false).height;
	}
	
	function get_textWidth() {
		return initGlyphs(false).width;
	}
	
	function set_textColor(c) {
		if( textColor != c ) {
			this.textColor = c;
			if( allocated && htmlText != "" ) initGlyphs();
		}
		return c;
	}

}