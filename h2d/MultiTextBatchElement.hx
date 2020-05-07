package h2d;

import h2d.MultiSpriteBatch;
import h2d.Text.TextLayoutInfos;
import hxd.Math;


class MTBLayout implements h2d.Text.ITextPos{
	var t : MultiTextBatchElement;

	public inline function new(t:h2d.MultiTextBatchElement) {
		this.t = t;
	}

	public inline function reset() {
		var te = @:privateAccess t.elements;
		if ( te.length <= 0 ) return;
		for ( e in @:privateAccess te)
			e.remove();
		@:privateAccess t.elements.splice(0,t.elements.length);
	}

	public inline function add(x:Int , y:Int, tile:h2d.Tile) {
		var es = @:privateAccess t.elements;
		if(t.dropShadow != null) {
			var d = t.dropShadow;
			var e = t.sp.alloc(tile);
			es.push(e);
			e.x = t.x + ((x + d.dx) * t.scaleX);
			e.y = t.y + ((y + d.dy) * t.scaleY);
			e.tile = tile;
			e.setColor( d.color );
			e.alpha = t.alpha * d.alpha;
			e.scaleX = t.scaleX;
			e.scaleY = t.scaleY;
		}

		var e = t.sp.alloc(tile);
		es.push(e);
		e.x = x* t.scaleX + t.x;
		e.y = y * t.scaleY + t.y;
		e.scaleX = t.scaleX;
		e.scaleY = t.scaleY;
		e.tile = tile;
		e.setColor( t.textColor );
		e.alpha = t.alpha;
	}
}

/**
 * Allow heavy text rendering with adding some minor constraints
 * scale and rot are do not make sense
 * init is usually faster and whold code generates a lot less draw calls
 */
@:allow(h2d.TextBatchElement.MTBLayout)
class MultiTextBatchElement implements IText {
	public var font(default,null) 		: Font;
	public var sp 						: h2d.MultiSpriteBatch;

	public var text(default, set) 		: String;
	var utf : hxd.IntStack = new hxd.IntStack();

	//only lower bits rgb significant
	public var textColor(default, set) 	: Int;
	public var maxWidth(default, set) 	: Null<Float>;
	public var dropShadow(default,set)	: Null<{ dx : Float, dy : Float, color : Int, alpha : Float }>;

	public var textWidth(get, null) 		: Int;
	public var textHeight(get, null)	 	: Int;
	public var textAlign(default, set) 		: h2d.Text.Align;
	public var letterSpacing(default,set) 	: Float;
	public var lineSpacing(default, set) 	: Int;

	var elements : Array<MultiBatchElement>=[];
	var layout : MTBLayout;

	public var x(default,set) 	: Float = 0.0;
	public var y(default, set)	: Float = 0.0;

	public var alpha(default, set)		: Float 	= 1.0;
	public var scaleX(default, set) 	: Float 	= 1.0;
	public var scaleY(default, set) 	: Float 	= 1.0;
	public var visible(default, set) 	: Bool 		= true;
	public var name						: String	= null;

	public function new(font:h2d.Font, master:MultiSpriteBatch, ?t:String="") {
		this.font = font;
		this.sp = master;
		layout = new MTBLayout(this);

		textAlign = Left;
		letterSpacing = 1.0;
		textColor = 0xFFFFFF;
		alpha = 1.0;
		
		text = t;
	}

	public inline function scale(v:hxd.Float32) {
		scaleX*=v;
		scaleY*=v;
	}

	public inline function setScale(v:hxd.Float32) {
		scaleX = v;
		scaleY = v;
	}

	public inline function nbQuad() {
		return dropShadow == null ? text.length : text.length * 2;
	}

	inline function set_scaleX(v) 	{
		scaleX = v;
		rebuild();
		return v;
	}

	inline function set_scaleY(v) {
		scaleY = v;
		rebuild();
		return scaleY;
	}

	inline function set_dropShadow(v) 	{
		dropShadow = v;
		rebuild();
		return v;
	}

	inline function set_visible(v) 	{
		visible = v;
		for ( i in 0...elements.length)
			elements[i].visible = v;
		return v;
	}

	inline function set_alpha(v:Float) 	{
		alpha = v;
		var hasDropShadow = dropShadow != null;
		var i = 0;
		for ( i in 0...elements.length) {
			var e = elements[i];
			if( !hasDropShadow)
				e.alpha = v;
			else
				e.alpha = ( (i & 1) == 0 )?(dropShadow.alpha * alpha):alpha;
		}
		return v;
	}

	inline function set_x(v:Float) {
		var ox = x;
		x = v;
		if( elements.length>0 )
		for ( e in elements)
			e.x += x-ox;
		return x;
	}

	inline function set_y(v:Float) {
		var oy = y;
		y = v;

		if( elements.length>0 )
		for ( e in elements)
			e.y += y-oy;
		return y;
	}

	public inline function traverse( f : MultiBatchElement -> Void ) {
		for ( e in elements)
			f(e);
	}

	static var nullText = "null";
	
	function set_text(t:String) {
		var t = t == null ? nullText : t;
		if( t == this.text ) return t;
		this.text = t;
		
		utf.reset();
		haxe.Utf8.iter( text,utf.push );
		
		rebuild();
		
		return t;
	}

	function set_textAlign(a) {
		if( a == this.textAlign )
			return a;
		textAlign = a;
		rebuild();
		return a;
	}

	function set_letterSpacing(s) {
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

	public
	function rebuild() {
		if ( text != null && font != null ) {
			var r = initGlyphs(utf);
			_textColor(textColor);
			tWidth = r.x;
			tHeight = r.y;
		}
	}

	var _info : TextLayoutInfos;
	
	function initGlyphs( utf : hxd.IntStack, ?rebuild = true, ?lines : Array<Int> = null ) : h2d.col.PointInt {
		
		if( _info == null )
			_info = new TextLayoutInfos(textAlign, maxWidth, lineSpacing, letterSpacing);
		else 
			_info.reset(textAlign, maxWidth, lineSpacing, letterSpacing);
			
		return @:privateAccess h2d.Text._initGlyphs( layout, font, _info, utf, rebuild, lines);
	}

	var tHeight : Null<Int> = null;
	function get_textHeight() : Int {
		if ( tHeight != null) return tHeight;
		var r = initGlyphs( utf, false);
		tWidth = r.x;
		tHeight = r.y;
		return tHeight;
	}

	var tWidth : Null<Int> = null;
	function get_textWidth() : Int {
		if ( tWidth != null) return tWidth;
		var r = initGlyphs( utf, false);
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
	
	function _textColor(c) {
		var hasDropShadow = dropShadow != null;
		if ( !hasDropShadow) {
			for ( e in elements) {
				e.setColor( textColor);
				e.alpha = alpha;
			}
		}
		else {
			for ( i in 0...elements.length) {
				var e = elements[i];
				if ( (i & 1) == 0 ) 
					e.setColor( dropShadow.color,dropShadow.alpha * alpha);
				else 
					e.setColor( textColor ,alpha );
			}
		}
	}

	function set_textColor(c) {
		c = c & 0xffffff;
		if( c == this.textColor )
			return c;
		this.textColor = c;
		_textColor(c);
		return c;
	}

	public inline function isDisposed() return elements==null;

	public function dispose() {
		for(e in elements)
			e.remove();
		elements = null;

		font = null;
		sp = null;
		layout = null;
	}

}
