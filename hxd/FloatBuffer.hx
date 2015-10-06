package hxd;

private typedef InnerData = #if flash flash.Vector<Float> #else Array<hxd.impl.Float32> #end

private class InnerIterator {
	var b : InnerData;
	var len : Int;
	var pos : Int;
	public inline function new( b : InnerData )  {
		this.b = b;
		this.len = this.b.length;
		this.pos = 0;
	}
	public inline function hasNext() {
		return pos < len;
	}
	public inline function next() {
		return b[pos++];
	}
}

abstract FloatBuffer(InnerData) {

	public var length(get, never) : Int;

	public inline function new(length = 0) {
		#if js
		this = untyped __new__(Array, length);
		#elseif flash
		this = new InnerData(length);
		#else
		this = new InnerData();
		#end
	}

	public inline function push( v : Float ) {
		#if flash
		this[this.length] = v;
		#else
		this.push(v);
		#end
	}

	public inline function grow( v : Int ) {
		#if flash
		if( v > this.length ) this.length = v;
		#else
		while( this.length < v ) this.push(0.);
		#end
	}

	public inline function resize( v : Int ) {
		#if flash
		this.length = v;
		#else
		while( this.length < v ) this.push(0.);
		if( this.length > v ) this.splice(v, this.length - v);
		#end
	}


	@:arrayAccess inline function arrayRead(key:Int) : Float {
		return this[key];
	}

	@:arrayAccess inline function arrayWrite(key:Int, value : Float) : Float {
		return this[key] = value;
	}

	public inline function getNative() : InnerData {
		return this;
	}

	public inline function iterator() {
		return new InnerIterator(this);
	}

	inline function get_length() : Int {
		return this.length;
	}

	public inline function clone() {
		var v = new FloatBuffer(length);
		for ( i in 0...length)  v.arrayWrite( i, arrayRead(i) );
		return v;
	}
	
	/**
	 * Warning does not necessarily make a copy
	 * TODO optimize to use the bytes 
	 */
	@:noDebug
	public static function fromBytes( bytes:haxe.io.Bytes ) : hxd.FloatBuffer{
		var nbFloats = bytes.length >> 2;
		var f = new FloatBuffer(nbFloats);
		var pos = 0;
		for ( i in 0...nbFloats){
			f[i] = bytes.getFloat(pos);
			pos += 4;
		}
		return f;
	}
	
	public inline function toBytes() : haxe.io.Bytes {
		var ba = new flash.utils.ByteArray();
		ba.endian = flash.utils.Endian.LITTLE_ENDIAN;
		
		for (v in this )
			ba.writeFloat(v);
		
		#if flash
		return haxe.io.Bytes.ofData(ba);
		#else
		return ba;
		#end
	}
	
	public inline function blit( src : FloatBuffer, count:Int) {
		for ( i in 0...count)  arrayWrite( i, src[i]);
	}
		
	public inline function zero() {
		for ( i in 0...length)  arrayWrite( i, 0 );
	}
	
	public static inline function fromNative( data:InnerData ) : hxd.FloatBuffer {
		return cast data;
	}
}