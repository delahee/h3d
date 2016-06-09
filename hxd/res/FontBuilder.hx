package hxd.res;
import haxe.Utf8;

typedef FontBuildOptions = {
	?antiAliasing : Bool,
	?chars : String,
	?alphaPremultiplied:Bool,
	?noRetain:Bool,
	
	?to4444:Bool,
	?filters:Array<flash.filters.BitmapFilter>,
	?edgify:{lum:Float, a:Int},//Allow to have really crispy font even at low resolution
};

/**
	FontBuilder allows to dynamicaly create a Bitmap font from a vector font.
	Depending on the platform this might require the font to be available as part of the resources,
	or it can be embedded manually with hxd.res.Embed.embedFont
**/
@:access(h2d.Font)
@:access(h2d.Tile)
class FontBuilder {

	var font : h2d.Font;
	var options : FontBuildOptions;
	var innerTex : h3d.mat.Texture;
	var tiles : Array<h2d.Tile>;
	
	static var FONTS = new Map<String,h2d.Font>();
	static var FONT_ALIASES = new Map<String,String>();

	function new(name, size, opt) {
		var name = FONT_ALIASES.exists( name ) ? FONT_ALIASES.get(name) : name;
		this.font = new h2d.Font(name, size);
		this.options = opt == null ? { } : opt;
		if( options.antiAliasing == null ) options.antiAliasing = true;
		if ( options.chars == null ) options.chars = hxd.Charset.DEFAULT_CHARS;
		if ( options.alphaPremultiplied == null ) options.alphaPremultiplied = #if flash true #else false #end;
		
		if ( options.to4444 == null ) options.to4444 = #if cpp true #else false #end;
		
		#if flash
		options.to4444 = false;
		#end
		
		#if cpp
		var drv = h3d.Engine.getCurrent().getNativeDriver();
		if ( !drv.supports4444)
			options.to4444 = false;
		#end
	}
	
	public static function dispose() {
		for( f in FONTS )
			f.dispose();
		FONTS = new Map();
	}
	
	#if (flash||openfl)
	function buildPixels( firstBuild : Bool ) : hxd.Pixels {
		if( firstBuild )
			font.lineHeight = 0;
		var tf = new flash.text.TextField();
		
		var fmt = tf.defaultTextFormat;
		fmt.font = font.name;
		fmt.size = font.size;
		fmt.color = 0xFFFFFF;
		tf.defaultTextFormat = fmt;
		
		var fs = flash.text.Font.enumerateFonts();
		for( f in fs )
			if( f.fontName == font.name ) {
				tf.embedFonts = true;
				break;
			}
	#if false
		#if(!flash&&openfl)
			if ( ! tf.embedFonts ) 
				throw "Impossible to interpret not embedded fonts, use one among " +
				Lambda.map(flash.text.Font.enumerateFonts(),function(fnt)return fnt.fontName);
		#end
	#end	
		if ( options.antiAliasing ) {
			tf.gridFitType = flash.text.GridFitType.SUBPIXEL;
			tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		}
		else {
			tf.gridFitType = flash.text.GridFitType.NONE;
			tf.antiAliasType = flash.text.AntiAliasType.NORMAL;
		}
		
		var fpx = 0;
		var fpy = 0;
			
		if (options.filters != null) {
			tf.filters = options.filters;
			for ( f in options.filters) {
				var g = Std.instance( f , flash.filters.GlowFilter);
				if ( g != null) {
					fpx = hxd.Math.imax( fpx, Math.ceil(g.blurX));
					fpy = hxd.Math.imax( fpy, Math.ceil(g.blurY));
				}
			}
		}
		
		var surf = 0;
		var sizes = [];
		var allChars = options.chars;
		var allCC = getUtf8StringAsArray(options.chars);
		#if sys
		var allCCBytes = isolateUtf8Blocs(allCC);
		#end
		
		for ( i in 0...allCC.length ) {
			#if flash
			tf.text = options.chars.charAt(i);
			#elseif sys
			tf.text = options.chars.substr(allCCBytes[i].pos, allCCBytes[i].len);
			#end
			
			var w = (Math.ceil(tf.textWidth)+1);
			if( w == 1 ) continue;
			var h = (Math.ceil(tf.textHeight)+1);//incorrect on font with big descent ( Arial maj 64px on windows... )
			
			surf += (w+4) * (h+4);
			if( firstBuild && h > font.lineHeight )
				font.lineHeight = h;
			sizes[i] = { w:w + fpx , h:h + fpy };
		}
		var side = Math.ceil( Math.sqrt(surf) );
		var width = 1;
		while( side > width )
			width <<= 1;
		
		var height = width;
		while( width * height >> 1 > surf )
			height >>= 1;
		var bmp;
		
		do {
			bmp = new flash.display.BitmapData(width, height, true, 0);
			bmp.lock();
			bmp.fillRect(bmp.rect, 0);
			if( firstBuild )
				font.glyphs = new Map();
			tiles = [];
			var m = new flash.geom.Matrix();
			var x = 0, y = 0, lineH = 0;
			
			for ( i in 0...allCC.length ) {
				var size = sizes[i];
				if( size == null ) continue;
				var w = size.w;
				var h = size.h;
				
				//add padding
				x += 4;
				
				if( x + w > width ) {
					x = 0;
					y += lineH + 1;
				}
				// no space, resize
				if( y + h > height ) {
					bmp.dispose();
					bmp = null;
					height <<= 1;
					break;
				}
				m.tx = x - 2 + fpx;
				m.ty = y - 2 + fpy;
				
				#if flash
				tf.text = options.chars.charAt(i);
				#elseif sys
				tf.text = options.chars.substr(allCCBytes[i].pos, allCCBytes[i].len);
				#end
				
				bmp.draw(tf, m,true);
				if( firstBuild ){
					var t = new h2d.Tile(null, x, y, w - 1, h - 1);
					tiles.push(t);
					font.glyphs.set(allCC[i], new h2d.Font.FontChar(t,w-1));
				}
				// next element
				if( h+4 > lineH ) lineH = h+4;//add some vpad
				x += w + 4;//add some xpad
			}
		} while( bmp == null );
		
		var pixels = hxd.BitmapData.fromNative(bmp).getPixels();
		bmp.dispose();
		
		if( options.edgify != null ){
			var mem = hxd.impl.Memory.select(pixels.bytes.bytes);
			var e : { lum:Float,a:Int} = options.edgify;
			for( i in 0...pixels.width*pixels.height ) {
				var p = (i << 2);

				var b = mem.b(p);
				var g = mem.b(p+1);
				var r = mem.b(p+2);
				var a = mem.b(p+3);
				
				var lum = (0.299 * (r/255.0) + 0.587 * (g/255.0) + 0.114 * (b/255.0));
				
				if ( lum >= e.lum && a > e.a) {
					function f( v ) return Math.round(v * (a / 255.0));
					mem.wb(p,   f(255) );
					mem.wb(p+1, f(255) );
					mem.wb(p+2, f(255) );
					mem.wb(p+3, a);
				}
				else {
					mem.wb(p,   0);
					mem.wb(p+1, 0);
					mem.wb(p+2, 0);
					mem.wb(p+3, 0);
				}
			}
			mem.end();
		}
		
		if( !options.to4444){
			pixels.convert(BGRA);
			if( options.alphaPremultiplied ){
				pixels.flags.set( AlphaPremultiplied );
				inline function premul(v,a){
					return hxd.Math.f2b( hxd.Math.b2f(v)*hxd.Math.b2f(a) );
				}

				var mem = hxd.impl.Memory.select(pixels.bytes.bytes);
				for( i in 0...pixels.width*pixels.height ) {
					var p = (i << 2);

					var b = mem.b(p);
					var g = mem.b(p+1);
					var r = mem.b(p+2);
					var a = mem.b(p+3);
					
					mem.wb(p,   premul(b,a));
					mem.wb(p+1, premul(g,a));
					mem.wb(p+2, premul(r,a));
					mem.wb(p+3, a);
				}

				mem.end();
			}
		}
		else {	
			pixels = pixels.transcode(Mixed(4, 4, 4, 4));
		}

		return pixels;
	}

	function build() : h2d.Font {
		var pixels = buildPixels( true );

		if ( innerTex != null) {
			innerTex.destroy();
			innerTex = null;
		}
		innerTex = h3d.mat.Texture.fromPixels(pixels, !options.noRetain);
		if( options.noRetain ){
			innerTex.realloc = function(){
				if( innerTex.pixels!=null && innerTex.pixels.bytes!=null )
					innerTex.uploadPixels(innerTex.pixels);
				else
					innerTex.uploadPixels(buildPixels(false));
			}
		}
		innerTex.name = "tex font-name:" + font.name+" size:"+font.size;
		font.tile = h2d.Tile.fromTexture(innerTex);
		for( t in tiles )
			t.setTexture( innerTex );
		return font;
	}
	
	#else
	
	function build() {
		throw "Font building not supported on this platform";
		return null;
	}
	
	#end
	
	public static function addFontAlias(name:String, realName:String) {
		FONT_ALIASES.set( name, realName);
	}
	
	public static function addFont( name:String, fnt:h2d.Font ) {
		FONTS.set( name, fnt );
	}
	
	public static function hasFont( name : String, size : Int, ?options : FontBuildOptions) {
		return FONTS.exists( getFontKey(name, size, options ) );
	}
	
	static function getFontKey( name : String, size : Int, ?options : FontBuildOptions ) {
		var key = name + "#" + size;
		if ( options != null){
			key += "opt-aa:" + options.antiAliasing;
			if( options.chars != null )
				key += ";opt-chars:" + haxe.crypto.Crc32.make(haxe.io.Bytes.ofString(options.chars));
			key += ";opt-premul:" + options.alphaPremultiplied;
			
			if (options.filters != null && options.filters.length > 0) {
				var buf = new haxe.io.BytesBuffer();
				for (filter in options.filters) {
					var cls = Type.getClass(filter);
					buf.addString(Type.getClassName(cls));
					for (field in Type.getInstanceFields(cls)) {
						if (Reflect.hasField(filter, field)) {
							var s = Reflect.field(filter, field);
							if (s != null) buf.addString(s);
						}
					}
				}
				key += ";opt-filters:" + haxe.crypto.Crc32.make(buf.getBytes());
			}
		}
		return key;
	}
	
	public static function getFont( name : String, size : Int, ?options : FontBuildOptions ) : h2d.Font {
		var key = getFontKey( name, size, options );
		var f = FONTS.get(key);
		if ( f != null ) {
			var tex = f.tile.innerTex;
			if ( !tex.isDisposed() ) return f;
			if ( tex.isDisposed() && !f.isBuildable ){
				tex.realloc();			
				return f;
			}
			//let it pass to inner builder;
		}
		f = new FontBuilder(name, size, options).build();
		FONTS.set(key, f);
		return f;
	}
	
	public static function computeFontTextureSize( name : String, size : Int, ?options : FontBuildOptions ) : { width : Int, height : Int } {
		var builder = new FontBuilder(name, size, options);
		
		var font    = builder.font;
		var options = builder.options;
		var tf      = new flash.text.TextField();
		
		var fmt = tf.defaultTextFormat;
		fmt.font = font.name;
		fmt.size = font.size;
		fmt.color = 0xFFFFFF;
		tf.defaultTextFormat = fmt;
		
		var fs = flash.text.Font.enumerateFonts();
		for( f in fs )
			if( f.fontName == font.name ) {
				tf.embedFonts = true;
				break;
			}
		if ( options.antiAliasing ) {
			tf.gridFitType = flash.text.GridFitType.SUBPIXEL;
			tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		}
		
		if (options.filters != null) {
			tf.filters = options.filters;
		}
		
		var surf = 0;
		var sizes = [];
		var allChars = options.chars;
		var allCC = getUtf8StringAsArray(options.chars);
		#if sys
		var allCCBytes = isolateUtf8Blocs(allCC);
		#end
		
		for ( i in 0...allCC.length ) {
			#if flash
			tf.text = options.chars.charAt(i);
			#elseif sys
			tf.text = options.chars.substr(allCCBytes[i].pos, allCCBytes[i].len);
			#end
			
			var w = (Math.ceil(tf.textWidth)+1);
			if( w == 1 ) continue;
			var h = (Math.ceil(tf.textHeight)+1);//incorrect on font with big descent ( Arial maj 64px on windows... )
			
			surf += (w+4) * (h+4);
			sizes[i] = { w:w, h:h };
		}
		var side = Math.ceil( Math.sqrt(surf) );
		var width = 1;
		while( side > width )
			width <<= 1;
		
		var height = width;
		while( width * height >> 1 > surf )
			height >>= 1;
		var resize = false;
		
		do {
			var m = new flash.geom.Matrix();
			var x = 0, y = 0, lineH = 0;
			resize = false;
			
			for ( i in 0...allCC.length ) {
				var size = sizes[i];
				if( size == null ) continue;
				var w = size.w;
				var h = size.h;
				
				//add padding
				x += 4;
				
				if( x + w > width ) {
					x = 0;
					y += lineH + 1;
				}
				// no space, resize
				if( y + h > height ) {
					resize = true;
					height <<= 1;
					break;
				}
				m.tx = x - 2;
				m.ty = y - 2;
				// next element
				if( h+4 > lineH ) lineH = h+4;//add some vpad
				x += w + 4;//add some xpad
			}
		} while( resize );
		
		return { width : width, height : height };
	}
	
	public static function deleteFont( fnt:h2d.Font) { 
		for ( k in FONTS.keys())
			if ( FONTS.get(k) == fnt )
				FONTS.remove(k);
				
		for ( k in FONT_ALIASES.keys())
			if ( FONT_ALIASES.get(k) == fnt.name )
				FONT_ALIASES.remove(k);
				
		@:privateAccess fnt.dispose();
	}
	
	
	/**
	 * return s the correcponding array of int
	 */
	static function getUtf8StringAsArray(str:String) {
		var a = [];
		haxe.Utf8.iter( str, function(cc) {
			a.push(cc);
		});
		return a;
	}
	
	/*
	 * returns the corrresponding multi byte index ans length
	 */
	static function isolateUtf8Blocs(codes:Array<Int>) :Array<{pos:Int,len:Int}> {
		var a = [];
		var i = 0;
		var cl = 0;
		for ( cc in codes ) {
			cl = hxd.text.Utf8Tools.getByteLength(cc);
			a.push( { pos:i, len:cl } );
			i += cl;
		}
		
		return a;
	}
	
}
