package hxd;

private class RingBufferIterator<T> {
	var arr 		: Array<T>;
	var len 		: Int;
	var pos 		: Int;
	var posStart 	: Int;
	
	public inline function new( arr : Array<T>,posStart:Int, len:Int )  {
		this.arr = arr;
		this.len = len;
		this.pos = 0;
		this.posStart = posStart;
	}
	
	public inline function hasNext() {
		return pos < len;
	}
	
	public inline function next() {
		var v = arr[ hxd.Math.umod( pos + posStart, len ) ];
		pos++;
		return v;
	}
}

@:generic
class RingBuffer<T>  {
	public var arr : Array<T> = [];
	
	public var posStart = 0;
	public var posEnd = 0;
	
	var ringSize:Int=0;
	
	public var length(get, never):Int; 
	
	inline function get_length(){
		return posEnd - posStart;
	}
	
	public function new( size:Int){
		ringSize = size;
	}
	
	public function clear(){
		posEnd = posStart;
	}
	
	public inline function first() : T {
		if ( posStart == posEnd ) return null;
		return arr[posStart];
	}
	
	public inline function popFirst() : T {
		if ( posStart == posEnd ) return null;
		var e = arr[posStart];
		posStart++;
		return e;
	}
	
	public inline function last() : T {
		if ( posStart == posEnd ) return null;
		return arr[ hxd.Math.umod((posEnd-1) , ringSize ) ];
	}
	
	//zero based access
	public function get(idx:Int){
		return arr[hxd.Math.umod( posStart + idx, ringSize )];
	}
	
	public function pushBack(val:T){
		arr[hxd.Math.umod(posEnd, ringSize)] = val;
		posEnd++;
		if ( posEnd - posStart > ringSize )
			posStart++;
	}
	
	public inline function iterator() return new RingBufferIterator<T>(arr,posStart,get_length());
	
}

#if debug
class RBTest {
	public static function test() {
		var a : hxd.RingBuffer<Null<Int>> = new hxd.RingBuffer<Null<Int>>( 4 ); 
		
		a.pushBack( 0 );
		a.pushBack( 1 );
		a.pushBack( 2 );
		
		for ( v in a ) trace( v);
		trace("************");
		
		trace( a.first());
		trace( a.last());
		
		trace("************");
		var a : hxd.RingBuffer<Null<Int>> = new hxd.RingBuffer<Null<Int>>( 4 ); 
		
		a.pushBack( 0 );
		a.pushBack( 1 );
		a.pushBack( 2 );
		a.pushBack( 3 );
		a.pushBack( 4 );
		
		for ( v in a ) trace( v);
		trace("************");
		
		a.pushBack( 5 );
		
		for ( v in a ) trace( v);
		trace("************");
		trace( a.first());
		trace( a.last());
		
		trace("************");
		
		var i = 0;
	}
}
#end