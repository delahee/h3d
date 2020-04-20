package h2d;

class HtmlText extends Drawable {

	public var font(default, set) 		: Font;
	public var htmlText(default, set) 	: String;
	public var textColor(default, set) 	: Int;
	
	public var textWidth(get, null) : Int;
	public var textHeight(get, null) : Int;
	
	public var letterSpacing : Float = 0.0;
	public var lineSpacing:Int;
	public var maxWidth(default,set) : Null<Float> = null;
	
	var glyphs : TileColorGroup;
	
	var utf8Text = new hxd.IntStack();
	var xPos : Int;
	var yPos : Int;
	var xMax : Int;
	
	public function new( font : Font, ?parent:h2d.Sprite, ?text : String ="" ) {
		super(parent);
		this.font = font;
		htmlText = text;
		shader = glyphs.shader;
		textColor = 0xFFFFFF;
	}
	
	public inline function nbQuad() {
		return htmlText.length;
	}
	
	override function onAlloc() {
		super.onAlloc();
		if( htmlText != null ) initGlyphs(htmlText);
	}
	
	function set_maxWidth(v:Null<Float>):Null<Float>
	{
		this.maxWidth = v;
		set_htmlText(this.htmlText);
		return v;
	}
	
	function set_font(f) {
		this.font = f;
		
		if ( glyphs != null ) {
			glyphs.remove();
			glyphs = null;
		}
			
		glyphs = new TileColorGroup(font == null ? null : font.tile, this);
		glyphs.name = name+" html glyphs";
		this.htmlText = htmlText;
		return f;
	}
	
	function set_htmlText(t) {
		this.htmlText = (t == null) ? "" : t;
		if ( allocated ) {
			var r = initGlyphs(htmlText);
			tWidth = r.x;
			tHeight = r.y;
		}
		return t;
	}
	
	function initGlyphs( text : String, ?rebuild = true, ?lines : Array<Int> ) {
		if( rebuild ) glyphs.reset();
		
		glyphs.setDefaultColor(textColor);
		xPos = 0;
		yPos = 0;
		xMax = 0;
		//so dirty but i don't get why it infinite loops on "null"
		
		for( e in Xml.parse(text) )
			addNode(e, rebuild);
		var ret = new h2d.col.PointInt( xPos > xMax ? xPos : xMax, xPos > 0 ? yPos + (font.lineHeight + lineSpacing) : yPos );
		return ret;
	}
	
	public function splitText( text : String, ?leftMargin = 0 ) {
		if( maxWidth == null )
			return text;
		var lines = [], rest = text, restPos = 0;
		var x = leftMargin, prevChar = -1;
		
		utf8Text.reset();
		
		#if flash
		for( i in 0...text.length )
			utf8Text.push(StringTools.fastCodeAt(text,i));
		#else
			haxe.Utf8.iter( text, utf8Text.push );
		#end
		
		for( i in 0...utf8Text.length ) {
			var cc = utf8Text.unsafeGet(i);
			var e = font.getChar(cc);
			var newline = cc == '\n'.code;
			var esize = e.width + e.getKerningOffset(prevChar);
			if( font.charset.isBreakChar(cc) ) {
				var size : Float = x + esize + letterSpacing;
				var k = i + 1, max = text.length;
				var prevChar = prevChar;
				while( size <= maxWidth && k < utf8Text.length ) {
					var cc =  utf8Text.unsafeGet(k++);
					if( font.charset.isSpace(cc) || cc == '\n'.code ) break;
					var e = font.getChar(cc);
					size += e.width + letterSpacing + e.getKerningOffset(prevChar);
					prevChar = cc;
				}
				if( size > maxWidth ) {
					newline = true;
					lines.push( haxe.Utf8.sub(text, restPos, i - restPos));
					restPos = i;
					if( font.charset.isSpace(cc) ) {
						e = null;
						restPos++;
					}
				}
			}
			if( e != null )
				x += Math.round(esize + letterSpacing);
			if( newline ) {
				x = 0;
				prevChar = -1;
			} else
				prevChar = cc;
		}
		if( restPos < text.length )
			lines.push( haxe.Utf8.sub(text, restPos, text.length - restPos));
			
		return lines.join("\n");
	}
	
	function addNode( e : Xml, rebuild : Bool ) {
		if( e.nodeType == Xml.Element ) {
			var colorChanged = false;
			switch( e.nodeName.toLowerCase() ) {
			case "font":
				for( a in e.attributes() ) {
					var v = e.get(a);
					switch( a.toLowerCase() ) {
					case "color":
						colorChanged = true;
						glyphs.setDefaultColor(Std.parseInt("0x" + v.substr(1)),1.0);
					default:
					}
				}
			case "br":
				if( xPos > xMax ) xMax = xPos;
				xPos = 0;
				yPos += font.lineHeight + lineSpacing;
			
			default:
			}
			for( child in e )
				addNode(child, rebuild);
			if( colorChanged )
				glyphs.setDefaultColor(textColor,1.0);
		} else {
			var t = splitText(e.nodeValue.split("\n").join(" "), xPos);
			var prevChar = -1;
			
			var newLineCode : Int = haxe.Utf8.charCodeAt("\n",0);
			
			for ( i in 0...haxe.Utf8.length(t) ) {
				var cc = haxe.Utf8.charCodeAt( t, i);
				
				if ( cc == newLineCode ) {
					xPos = 0;
					yPos += font.lineHeight + lineSpacing;
					prevChar = -1;
					continue;
				}
				var e = font.getChar(cc);
				xPos += e.getKerningOffset(prevChar);
				if( rebuild ) glyphs.add(xPos, yPos, e.t);
				xPos += Math.round(e.width + letterSpacing);
				prevChar = cc;
			}
		}
	}
	
	var tHeight : Null<Int> = null;
	function get_textHeight() : Int {
		if ( tHeight != null) return tHeight;
		var r = initGlyphs(htmlText, false);
		tWidth = r.x;
		tHeight = r.y;
		return tHeight;
	}

	var tWidth : Null<Int> = null;
	function get_textWidth() : Int {
		if ( tWidth != null) return tWidth;
		var r = initGlyphs(htmlText, false);
		tWidth = r.x;
		tHeight = r.y;
		return tWidth;
	}
	
	function set_textColor(c) {
		if( textColor != c ) {
			this.textColor = c;
			if( allocated && htmlText != "" ) initGlyphs(htmlText);
		}
		return c;
	}
	
	var bulkColor : h3d.Vector 		= new h3d.Vector(1,1,1,1);
	var shadowColor : h3d.Vector 	= new h3d.Vector(1,1,1,1);
	public var useShadowAsOutline = false;
	
	public var dropShadow : { dx : Float, dy : Float, color : Int, alpha : Float };
	
	override function draw(ctx:RenderContext) {
		glyphs.emit = emit;
		glyphs.filter = filter;
		glyphs.blendMode = blendMode;

		if ( dropShadow != null ) {
			
			if( !useShadowAsOutline ){
				glyphs.x += dropShadow.dx;
				glyphs.y += dropShadow.dy;
				glyphs.calcAbsPos();

				bulkColor.load( color );
				shadowColor.setColor( dropShadow.color );
				shadowColor.a = dropShadow.alpha * alpha;

				glyphs.color = shadowColor;

				glyphs.draw(ctx);
				glyphs.x -= dropShadow.dx;
				glyphs.y -= dropShadow.dy;

				glyphs.color = bulkColor;
			}
			else {
				var ox = glyphs.x;
				var oy = glyphs.y;
				
				if( color != null)
					bulkColor.load( color );
					
				shadowColor.setColor( dropShadow.color );
				shadowColor.a = dropShadow.alpha * alpha;
				glyphs.color = shadowColor;
				for ( i in 0...4) {
					var dsx = 0;
					var dsy = 0;
					
					switch(i) {
						case 0: dsx = 1; dsy = 1;
						case 1: dsx = -1; dsy = -1;
						case 2: dsx = 1; dsy = -1;
						case 3: dsx = -1; dsy = 1;
					}
					glyphs.x += dropShadow.dx*dsx;
					glyphs.y += dropShadow.dy * dsy;
					
					glyphs.calcAbsPos();
					glyphs.draw(ctx);
					glyphs.x = ox;
					glyphs.y = oy;
				}
				glyphs.color = bulkColor;
			}
		}
		super.draw(ctx);
	}
	
	public function assignChain( arr : Array<{txt:String,color:Int}> ) {
		htmlText = arr
		.map( function(e) {
			return "<font color='#" + StringTools.hex( e.color ) + "'>" + e.txt + "</font>";
		})
		.join("");
	}
}