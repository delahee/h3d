package h2d;
import h2d.Font.FontChar;

class Kerning {
	public var prevChar 	: Int = 0;
	public var offset 		: Int = 0;
	public var next 		: Null<Kerning> = null;
	public function new(c, o) {
		this.prevChar = c;
		this.offset = o;
	}
}

class FontChar {
	public var t 		: h2d.Tile = null;
	public var width 	: Int = 0;
	var kerning 		: Null<Kerning> = null;
	
	public function new(t,w) {
		this.t = t;
		this.width = w;
	}
	
	public function addKerning( prevChar : Int, offset : Int ) {
		var k = new Kerning(prevChar, offset);
		k.next = kerning;
		kerning = k;
	}
	
	public function getKerningOffset( prevChar : Int ) {
		var k = kerning;
		while( k != null ) {
			if( k.prevChar == prevChar )
				return k.offset;
			k = k.next;
		}
		return 0;
	}
	
	public function clone() {
		var f =  new FontChar(t.clone(), width);
		f.kerning = kerning;
		return f;
	}

}

/**
 * 
 * 
 * example where font can be find by the flash subsystem ( flash or openfl )
 * @usage
 * var font = hxd.res.FontBuilder.getFont("arial", 32, { antiAliasing : false , chars : hxd.Charset.DEFAULT_CHARS } );
 * 
 */
class Font {
	
	public var name(default, null) : String;
	public var size(default, null) : Int;
	public var baseLine(default, null) : Float;
	
	public var lineHeight(default, null) : Int;
	public var tile(default,null) : h2d.Tile;
	public var charset : hxd.Charset;
	public var isBuildable = true;
	
	public var sharedTex:Bool = false;
	var glyphs : Map<Int,FontChar>;
	
	public var emptyChar(default,null) : FontChar;//let's see what happens
	public var defaultChar : FontChar;//let's see what happens
	public var defaultLetterSpacing : Float = 0.0;
	
	public
	function new(name,size) {
		this.name = name;
		this.size = size;
		glyphs = new Map();
		defaultChar = emptyChar = new FontChar(new Tile(null, 0, 0, 0, 0),0);
		charset = hxd.Charset.getDefault();
	}
	
	public 
	inline 
	function getChar( code : Int ) : FontChar{
		var c = glyphs.get(code);
		if( c == null ) {
			c = charset.resolveChar(code, glyphs);
			if ( c == null ) c = defaultChar;
		}
		return c;
	}
	
	/**
		This is meant to create smoother fonts by creating them with double size while still keeping the original glyph size.
	**/
	public function resizeTo( size : Int ) {
		var ratio = size / this.size;
		for ( c in glyphs ) {
			c.width = Std.int(c.width * ratio);
			c.t.scaleToSize(Std.int(c.t.width * ratio), Std.int(c.t.height * ratio));
		}
		lineHeight = Std.int(lineHeight * ratio);
		this.size = size;
	}
	
	public function iter( f : FontChar -> Void ) {
		for( c in glyphs ) 
			f(c);
	}
	
	public function hasChar( code : Int ) {
		return glyphs.get(code) != null;
	}
	
	public function aliasGlyph( dest:Int, from:Int) {
		if (  glyphs.exists(from))
			glyphs.set( dest , glyphs.get(from).clone() );
		else 
			glyphs.set( dest , defaultChar.clone() );
		
	}
	
	/**
	 * Please use FontBuilder.deleteFont(myfont) or @:privateAccess myfont.dispose() if you are _really_ sure about what you do
	 */
	function dispose() {
		if( tile == null )
			return;
		if(!sharedTex)
			tile.dispose();
		glyphs = null;
		tile = null;
		charset = null;
		defaultChar = null;
	}
	
}
