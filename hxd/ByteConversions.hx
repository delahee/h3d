package hxd;

import haxe.io.Bytes;

/**
 * Tries to provide consistent access to haxe.io.bytes from any primitive
 */
class ByteConversions{

	
	#if (flash || openfl)
	public static function byteArrayToBytes( v: flash.utils.ByteArray ) : haxe.io.Bytes {
		return
		#if flash
		Bytes.ofData( v );
		#elseif (js&&openfl)
		{
			var b :Bytes = Bytes.alloc(v.length);
			for ( i in 0...v.length )
				b.set(i,v[i]);
			b;
		};
		#elseif (openfl)
		v; 
		#else
		throw "unsupported on this platform";
		#end
	}
	#end 
	
	#if (flash || openfl)
	public static inline function byteArrayToBytesView( v: flash.utils.ByteArray ) : hxd.BytesView {
		return BytesView.fromBytes(byteArrayToBytes(v));
	}
	#end 
	
	#if js
	public static inline function arrayBufferToBytes( v : js.html.ArrayBuffer ) : haxe.io.Bytes{
		return byteArrayToBytes(flash.utils.ByteArray.nmeOfBuffer(v));
	}
	#end
		
	#if (flash || openfl)
	public static function bytesToByteArray( v: haxe.io.Bytes ) :  flash.utils.ByteArray {
		#if flash
		return v.getData();
		#elseif openfl
		return flash.utils.ByteArray.fromBytes(v);
		#else
		throw "unsupported on this platform";
		#end
	}
	#end 
	
	#if (flash || openfl)
	public inline static function bytesViewToByteArray( bv: hxd.BytesView ) :  flash.utils.ByteArray {
		var ba = bytesToByteArray(bv.bytes);
		ba.position = bv.position;
		return ba;
	}
	#end 
}
