package hxd;

private typedef InnerData = #if flash flash.Vector<Float> #else Array<Float> #end

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
		#elseif cpp
		this = new InnerData();
		#else
		this = new InnerData(length);
		#end
	}
	
	public inline function push( v : Float ) {
		#if flash
		this[this.length] = v;
		#else
		this.push(v);
		#end
	}
	
	/**
	 * creates a back copy
	 */
	@:from
	public static inline function fromArray( arr: Array<Float> ) :FloatBuffer{
		var f = new FloatBuffer(arr.length);
		for ( v in 0...arr.length )
			f[v] = arr[v];
		return f;
	}
	
	public static inline function makeView( arr: Array<Float> ) : FloatBuffer {
		#if flash
		var f = new FloatBuffer(arr.length);
		for ( v in 0...arr.length )
			f[v] = arr[v];
		return f;
		#else 
		return cast arr;
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
		if ( this.length < v ) {
			trace("regrowing to " + v);
			this[v] = 0.0;
		}
		#end
	}
	
	
	@:arrayAccess public inline function arrayRead(key:Int) : Float {
		#if flash
		return this[key];
		#else 
		return hxd.ArrayTools.unsafeGet(this,key);
		#end
	}

	@:arrayAccess public inline function arrayWrite(key:Int, value : Float) : Float {
		#if debug
			if( this.length <= key)
				throw "need regrow until " + key;
		#end
			
		#if flash
			return this[key] = value;
		#else
			return hxd.ArrayTools.unsafeSet(this, key, value );
		#end
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
	
	public inline function blit( src : FloatBuffer, count:Int) {
		#if flash
			for ( i in 0...count)  arrayWrite( i, src[i]);
		#else 
			hxd.ArrayTools.blit(this, 0, src.getNative(), 0, count);
		#end
	}
		
	public inline function zero() {
		#if flash
			for ( i in 0...length)  arrayWrite( i, 0 );
		#else 
			hxd.ArrayTools.zeroF(this);
		#end
	}
	
	public inline function clone() {
		var v = new FloatBuffer(length);
		#if flash
			for ( i in 0...length)  v.arrayWrite( i, arrayRead(i) );
		#else 
			hxd.ArrayTools.blit(v.getNative(), 0, this, 0, length);
		#end
		return v;
	}
	
}