package h2d;

import h2d.SpriteBatch;
import hxd.Stack;

class NumberOpt extends h2d.SpriteBatch {
	var val : Int = 1024*1024;
	
	var font 			: h2d.Font;
	var glyphs 			: hxd.Stack<BatchElement>;
	var vals 			: hxd.IntStack = new hxd.IntStack();
	var textColor 		: Int = 0xffffff;
	var letterSpacing = 1;
	
	public function new(fnt:h2d.Font, ?p:h2d.Sprite) {
		font = fnt;
		super( font.getChar('a'.code).t, p );
		glyphs = new Stack();
	}
	
	public var nb(get, set): Int;
	
	function get_nb() : Int  return val;
	
	function set_nb( nb : Int ) {
		var nb = Std.int( nb );
		if ( val == nb ) return nb;
		
		drawVal(nb);
		setTextColor( textColor );
		val = nb;
		return nb;
	}
	
	var zeroCode = "0".code;
	
	function allocGlyph(){
		return 
		if ( glyphs.length == 0 ) 	new BatchElement( font.getChar('0'.code).t );
		else 						glyphs.pop();
	}
	
	function deleteGlyph(e:BatchElement){
		e.remove();
		glyphs.push(e);
	}
	
	function drawVal(v : Int){
		var v : Float = v;
		
		vals.reset();
		if ( v == 0 ){
			vals.push(0);
		}
		else {
			while ( Std.int(v) != 0 ){
				var idx = Std.int(v) % 10;
				vals.push(idx);
				v = v / 10;
			}
		}
		
		vals.reverse();
		
		for ( e in getElements())
			deleteGlyph( e );
		removeAllElements();

		var cx = 0.0;
		var i = 0;
		for ( idx in vals ){
			var g = allocGlyph();
			var c = font.getChar(zeroCode + idx);
			g.tile = c.t;
			
			g.x = cx;
			g.y = 0;
			
			cx += letterSpacing + c.width + font.defaultLetterSpacing;
				
			if ( i > 0 ) cx += c.getKerningOffset(vals.unsafeGet(i - 1) + zeroCode);
			add(g);
			i++;
		}
	}
	
	
	public function setTextColor(t){
		textColor = t;
		for ( e in getElements() )
			e.setColor( (0xff << 24) | textColor ); 
	}
	
}