package h2d;

import h2d.col.Point;
import h3d.anim.Animation;

enum Align {
	Left;
	Right;
	Center;
}

class TextLayoutInfos {
	public var textAlign:Align;
	public var maxWidth:Null<Float>;
	public var lineSpacing:Int;
	public var letterSpacing:Float;
	public var onGlyph:Int->Float->Float->Void;

	public inline function new(t,m,lis,les) {
		textAlign = t;
		maxWidth = m;
		lineSpacing = lis;
		letterSpacing = les;
	}
	
	public inline function reset(t,m,lis,les){
		textAlign = t;
		maxWidth = m;
		lineSpacing = lis;
		letterSpacing = les;
	}
}

interface ITextPos {
	public function reset():Void;
	public function add(x:Int, y:Int, t:h2d.Tile):Void;
}

class TileGroupAsPos implements ITextPos {
	var tg:TileGroup;
	public inline function new(tg) {
		this.tg = tg;
	}

	public inline function reset() {
		tg.reset();
	}

	public inline function add(x:Int,y:Int,t:h2d.Tile) {
		tg.add(x,y,t);
	}
	
	public inline function set( tg){
		this.tg = tg;
	}
}

@:structInit
class DropShadow {
	
	public var dx  		: Float;
	public var dy		: Float;
	public var color 	: Int;
	public var alpha	: Float;
	
	public inline function new(dx, dy, color, alpha){
		this.dx = dx;
		this.dy = dy;
		this.color = color;
		this.alpha = alpha;
	}
}

/**
 * @see h2d.Font for the font initalisation
 *
 * @usage
 * 	fps=new h2d.Text(font, root);
 *	fps.textColor = 0xFFFFFF;
 *	fps.dropShadow = { dx : 0.5, dy : 0.5, color : 0xFF0000, alpha : 0.8 };
 *	fps.text = "";
 *	fps.x = 0;
 *	fps.y = 400;
 *	fps.name = "tf";
 */
class Text extends Drawable implements IText {

	public var font(default, set) : Font;
	public var text(default, set) : String;

	var utf : hxd.IntStack = new hxd.IntStack();
	var utfTemp : hxd.IntStack = new hxd.IntStack();

	/**
	 * Does not take highter bits alpha into account
	 */
	public var textColor(default, set) : Int;
	public var maxWidth(default, set) : Null<Float>;
	
	public var dropShadow : DropShadow;

	public var textWidth(get, null) : Int;
	public var textHeight(get, null) : Int;
	public var textAlign(default, set) : Align;
	public var letterSpacing(default,set) : Float;
	public var lineSpacing(default,set) : Int;

	public var numLines(default, null):Int;
	/**
	 * Glyph is stored as child
	 */
	var glyphs : TileGroup;

	public function new( font : Font,  ?parent = null, ?txt:String=null, ?sh:h2d.Drawable.DrawableShader) {
		super(parent,sh);
		this.font = font;

		textAlign = Left;
		letterSpacing = 1;
		lineSpacing = 0;
		text = txt==null?"":txt;
		textColor = 0xFFFFFFFF;
	}

	public inline function nbQuad() return dropShadow == null ? utf.length : utf.length*2;
	public inline function getGlyphs() return glyphs;

	public override function clone<T>(?s:T) : T {
		var t : Text = (s == null) ? new Text(font, parent) : cast s;

		var g = glyphs;

		var idx = getChildIndex(glyphs);
		glyphs.remove();
		super.clone(t);//skip glyph cloning
		addChildAt(glyphs, idx);

		t.text = text;
		t.textColor = textColor;
		t.maxWidth = maxWidth;

		var ds = dropShadow;
		if(ds!=null)
			t.dropShadow = { dx:ds.dx, dy:ds.dy, color:ds.color, alpha:ds.alpha };

		t.textAlign = textAlign;
		t.letterSpacing = letterSpacing;
		t.lineSpacing = lineSpacing;

		return cast t;
	}
	
	public function calcTextWidth( text : String ) {
		return initGlyphs(textToUtf(text),false).x;
	}
	
	public function calcTextHeight( text : String ) {
		return initGlyphs(textToUtf(text),false).y;
	}
	
	public function centered() textAlign = Center;

	function set_font(font) {
		if( glyphs != null && font == this.font )
			return font;
		this.font = font;
		
		if ( glyphs != null )  { glyphs.remove(); glyphs = null; }
		
		glyphs = new TileGroup(font == null ? null : font.tile, this, shader);
		glyphs.name = name+" subGlyphs";
		shader = glyphs.shader;
		rebuild();
		return font;
	}

	override function set_color(v:h3d.Vector) : h3d.Vector {
		alpha = v.w;
		set_textColor( v.toColor() );
		return v;
	}

	override function set_alpha(v) {
		super.alpha = v;
		set_textColor(textColor);
		return v;
	}

	function set_textAlign(a) {
		if( a == this.textAlign )
			return a;
		textAlign = a;
		rebuild();
		return a;
	}

	function set_letterSpacing(s:Float) {
		if( s == letterSpacing )
			return s;
		letterSpacing = s;
		rebuild();
		return s;
	}

	function set_lineSpacing(s) {
		if( s == this.lineSpacing )
			return s;
		lineSpacing = s;
		rebuild();
		return s;
	}

	override function onAlloc() {
		super.onAlloc();
		rebuild();
	}

	var bulkColor : h3d.Vector = new h3d.Vector(1,1,1,1);
	var shadowColor : h3d.Vector = new h3d.Vector(1,1,1,1);

	public var useShadowAsOutline = false;
	override function draw(ctx:RenderContext) {
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
				
				bulkColor.load( color );
				shadowColor.setColor( dropShadow.color );
				shadowColor.a = dropShadow.alpha * alpha;
				glyphs.color = shadowColor;
				for ( i in 0...4) {
					var dsx = 0;
					var dsy = 0;
					switch(i) {
						case 0: dsx = 1; dsy = 0;
						case 1: dsx = -1; dsy = 0;
						case 2: dsx = 0; dsy = -1;
						case 3: dsx = 0; dsy = 1;
					}
					var ddx = dropShadow.dx * dsx;
					var ddy = dropShadow.dy * dsy;
					glyphs.x += ddx;
					glyphs.y += ddy;
					
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

	function set_text(t:String) {
		var t = t == null ? "null" : t;
		if( t == this.text ) return t;
		this.text = t;

		utf.reset();
		#if flash
		for( i in 0...t.length )
			utf.push(StringTools.fastCodeAt(t,i));
		#else
			haxe.Utf8.iter( text, utf.push );
		#end

		//rebuild();
		if ( !allocated ) 	onAlloc();
		else 				rebuild();
		return t;
	}
	
	/**
	 * @return the 
	 */
	public 
	function getGlyphsPosition( pos:Int ) : h2d.Vector {
		var v = new h2d.Vector(0,0);
		initGlyphs(utf, true, null, function(idx:Int, x:Float, y:Float){
			if( idx <= pos ){
				v.x = x;
				v.y = y;
			}
		});
		return v;
	}
	
	public 
	function getAllGlyphsPositions() : Array<h2d.Vector> {
		var a = [];
		initGlyphs(utf, true, null, function(idx:Int, x:Float, y:Float){
			a.push( new h2d.Vector( x, y ));
		});
		return a;
	}

	function rebuild() {
		if ( allocated && text != null && font != null ) {
			var r = initGlyphs(utf);
			tWidth = r.x;
			tHeight = r.y;
		}
	}

	private function textToUtf(str:String) { //and never touch this
		var s = utfTemp;
		s.reset();
		#if flash
		for( i in 0...str.length )
			s.push(StringTools.fastCodeAt(str,i));
		#else 
			haxe.Utf8.iter( str, s.push );
		#end
		return s;
	}
	
	var _info : TextLayoutInfos;
	var _absPos : TileGroupAsPos;
	

	@:noDebug
	function initGlyphs( utf : hxd.IntStack, rebuild = true, lines : Array<Int> = null , ?onGlyph:Int->Float->Float->Void) : h2d.col.PointInt {
		if( _info == null )
			_info = new TextLayoutInfos(textAlign, maxWidth, lineSpacing, letterSpacing);
		else 
			_info.reset(textAlign, maxWidth, lineSpacing, letterSpacing);
			
		var info = _info;
		info.onGlyph = onGlyph;
		
		if ( _absPos == null)
			_absPos = new TileGroupAsPos(glyphs);
		else 
			_absPos.set(glyphs);
			
		var absPos  =  _absPos;
		var r : h2d.col.PointInt = _initGlyphs( absPos, font, info, utf, rebuild, lines);
		numLines = 	if( font == null || r == null || info == null ) 1
					else Std.int(r.y / (font.lineHeight + info.lineSpacing));
		return r;
	}
	
	@:noDebug
	static
	function _initGlyphs( glyphs :ITextPos, font:h2d.Font,info : TextLayoutInfos, utf : hxd.IntStack, rebuild = true, lines : Array<Int> = null ) : h2d.col.PointInt {
		if ( rebuild ) glyphs.reset();
		var x = 0, y = 0, xMax = 0, prevChar = -1;
		var calcY = 0.0;
		var align = rebuild ? info.textAlign : Left;
		switch( align ) {
		case Center, Right:
			lines = [];
			var inf = _initGlyphs(glyphs,font,info,utf, false, lines);
			var max = (info.maxWidth == null) ? inf.x : Std.int(info.maxWidth);
			var k = align == Center ? 1 : 0;
			for( i in 0...lines.length )
				lines[i] = (max - lines[i]) >> k;
			x = lines.shift();
		
		default:
		}
		var dl = font.lineHeight + info.lineSpacing;
		var calcLines = !rebuild && lines != null;

		for ( i in 0...utf.length ) {
			var cc = utf.unsafeGet(i);
			
			//trace( "code: 0x" + StringTools.hex(cc) );
			
			var e = font.getChar(cc);
			var newline = cc == '\n'.code;
			var esize : Int = e.width + e.getKerningOffset(prevChar);
			// if the next word goes past the max width, change it into a newline
			if( font.charset.isBreakChar(cc) && info.maxWidth != null ) {
				var size = x + esize + info.letterSpacing;
				var k = i + 1, max = utf.length;
				var prevChar = prevChar;
				while( size <= info.maxWidth && k < utf.length ) {
					var cc = utf.unsafeGet(k++);
					if( font.charset.isSpace(cc) || cc == '\n'.code ) break;
					var e = font.getChar(cc);
					size += e.width + font.defaultLetterSpacing + info.letterSpacing + e.getKerningOffset(prevChar);
					prevChar = cc;
				}
				if( size > info.maxWidth ) {
					newline = true;
					if( font.charset.isSpace(cc) ) e = null;
				}
			}
			if( e != null ) {
				if ( rebuild ) {
					if ( info.onGlyph != null) info.onGlyph(i, x, y);
					glyphs.add(x, y, e.t);
				}
				x += Math.round(esize + info.letterSpacing);
			}
			if ( newline ) {
				if( x > xMax ) xMax = x;
				if( calcLines ) lines.push(x);
				if( rebuild )
					switch( align ) {
					case Left:
						x = 0;
					case Right, Center:
						x = lines.shift();
					}
				else
					x = 0;
				y += dl;
				calcY += (dl < font.baseLine + info.lineSpacing) ? (font.baseLine+ info.lineSpacing) : dl;//may serve one day
				prevChar = -1;
			} else
				prevChar = cc;
		}
		if ( calcLines ) lines.push(x);
		
		if ( info.onGlyph != null) info.onGlyph( utf.length, x, y);

		//todo replace y by calcY?
		var ret = new h2d.col.PointInt(
			x > xMax ? x : xMax,
			x > 0 ? y + dl : y > 0 ? y : dl );
		return ret;
	}

	var tHeight : Null<Int> = null;
	function get_textHeight() : Int {
		if ( tHeight != null) return tHeight;
		if ( font == null ) return 0;
		var r = initGlyphs(utf, false);
		tWidth = r.x;
		tHeight = r.y;
		return tHeight;
	}

	var tWidth : Null<Int> = null;
	function get_textWidth() : Int {
		if ( tWidth != null) return tWidth;
		if ( font == null ) return 0;
		var r = initGlyphs(utf, false);
		tWidth = r.x;
		tHeight = r.y;
		return tWidth;
	}

	function set_maxWidth(w) {
		if( w == this.maxWidth )
			return w;
		maxWidth = w;
		rebuild();
		return w;
	}

	function set_textColor(c) {
		this.textColor = c;
		if ( glyphs != null) {
			if ( glyphs.color == null) 	glyphs.color = h3d.Vector.fromColor(c);
			else						glyphs.color.setColor(c);
			glyphs.color.w = alpha;
		}
		return c;
	}
	
	override function getBoundsRec( relativeTo:h2d.Sprite, out : h2d.col.Bounds, forSize : Bool ) {
		super.getBoundsRec(relativeTo, out, forSize);
		
		var x : Float;
		var y : Float;
		var w : Float;
		var h : Float;
		if ( forSize ) {
			x = 0;
			y = 0;
			w = textWidth;
			h = (tHeight<font.baseLine)? font.baseLine : tHeight;
		}
		else {
			x = 0;
			y = 0;
			w = textWidth;
			h = textHeight;
		}
		addBounds(relativeTo, out, x, y, w, h);
	}

}
