package hxd;



import haxe.io.Bytes;

private typedef InnerData = 
#if (flash||openfl)
	flash.display.BitmapData 
#elseif js
	js.html.ImageData 
#else 
	Int 
#end;

abstract BitmapData(InnerData) {

	public var width(get, never) : Int;
	public var height(get, never) : Int;
	
	public inline function new(width:Int, height:Int) {
		#if ((flash)||(openfl))
		this = new flash.display.BitmapData(width, height, true, 0);
		#else
		throw "TODO";
		#end
	}
	
	public inline function clear( color : Int ) {
		#if ((flash)||(openfl))
		this.fillRect(this.rect, color);
		#else
		throw "TODO";
		#end
	}
	
	public inline function fill( rect : h2d.col.Bounds, color : Int ) {
		#if ((flash)||(openfl))
		this.fillRect(new flash.geom.Rectangle(Std.int(rect.xMin), Std.int(rect.yMin), Math.ceil(rect.xMax - rect.xMin), Math.ceil(rect.yMax - rect.yMin)), color);
		#else
		throw "TODO";
		#end
	}

	public function line( x0 : Int, y0 : Int, x1 : Int, y1 : Int, color : Int ) {
		var dx = x1 - x0;
		var dy = y1 - y0;
		if( dx == 0 ) {
			if( y1 < y0 ) {
				var tmp = y0;
				y0 = y1;
				y1 = tmp;
			}
			for( y in y0...y1 + 1 )
				setPixel(x0, y, color);
		} else if( dy == 0 ) {
			if( x1 < x0 ) {
				var tmp = x0;
				x0 = x1;
				x1 = tmp;
			}
			for( x in x0...x1 + 1 )
				setPixel(x, y0, color);
		} else {
			throw "TODO";
		}
	}
	
	public inline function dispose() {
		#if ((flash)||(openfl))
		this.dispose();
		#end
	}
	
	public inline function getPixel( x : Int, y : Int ) {
		#if ( flash || openfl )
		return toNative().getPixel32(x, y);
		#else
		throw "TODO";
		return 0;
		#end
	}

	public inline function setPixel( x : Int, y : Int, c : Int ) {
		#if ((flash)||(openfl))
		this.setPixel32(x, y, c);
		#else
		throw "TODO";
		#end
	}
	
	inline function get_width() {
		return this.width;
	}

	inline function get_height() {
		return this.height;
	}
	
	public inline function isAlphaPremultiplied() {
		#if flash
			return false;
		#else 
			return toNative().premultipliedAlpha;
		#end
	}
	/**
	 * According to flash spec, always return a non premultiplied zone (albeit information can be lost)
	 */
	public inline function getPixels() : Pixels {
		return nativeGetPixels(this);
	}

	public inline function setPixels( pixels : Pixels ) {
		nativeSetPixels(this, pixels);
	}
	
	public inline function toNative() : InnerData {
		return this;
	}
	
	public static inline function fromNative( bmp : InnerData ) : BitmapData {
		return cast bmp;
	}
	
	static function nativeGetPixels( b : InnerData ) : hxd.Pixels {
		#if flash
			 var p = new Pixels(b.width, b.height, haxe.io.Bytes.ofData(b.getPixels(b.rect)), ARGB);
			 return p;
		#elseif openfl
			var bRect = b.rect;
			var bPixels : Bytes = hxd.ByteConversions.byteArrayToBytes(b.getPixels(b.rect));
			var p = new Pixels(b.width, b.height, bPixels, ARGB);
			return p;
		#else
			throw "TODO";
			return null;
		#end
	}
	
	static function nativeSetPixels( b : InnerData, pixels : Pixels ) {
		#if flash
			var bytes = pixels.bytes.getData();
			bytes.position = 0;
			switch( pixels.format ) {
			case BGRA:
				bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
			case ARGB:
				bytes.endian = flash.utils.Endian.BIG_ENDIAN;
			case RGBA:
				pixels.convert(BGRA);
				bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
			}
			b.setPixels(b.rect, bytes);
		#elseif ((js) || (cpp))
			b.setPixels(b.rect, flash.utils.ByteArray.fromBytes(pixels.bytes));
		#else
			throw "TODO";
		#end
	}
}