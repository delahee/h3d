package hxd;


private class StackIterator<T> {
	var b : Array<T>;
	var len : Int;
	var pos : Int;
	public inline function new( b : Array<T>,len:Int )  {
		this.b = b;
		this.len = len;
		this.pos = 0;
	}
	public inline function hasNext() {
		return pos < len;
	}
	public inline function next() {
		return b[pos++];
	}
}

private class BackwardStackIteratorBug<T> {
	var b : Array<T>;
	var len : Int;
	var pos : Int;
	public inline function new( b : Array<T>,len:Int )  {
		this.b = b;
		this.len = len;
		this.pos = len;
	}
	public inline function hasNext() {
		return pos > 0;
	}
	public inline function next() {
		return b[--pos];
	}
}

private class BackwardStackIterator<T> {
	var b : Array<T>;
	var len : Int;
	var pos : Int;
	public inline function new( b : Array<T>,len:Int )  {
		this.b = b;
		this.len = len;
		this.pos = 0;
	}
	public inline function hasNext() {
		return pos < len;
	}
	public inline function next() {
		return b[len - pos++ - 1];
	}
}

//could be an abstract but they are not reliable enough at the time I write this 
@:generic
class Stack<T> {
	var arr : Array<T>=[];
	var pos = 0;
	
	public var length(get, never):Int; inline function get_length() return pos;
	
	public inline function new() {}
	
	/**
	 * slow, breaks order but no realloc
	 */
	public inline function remove(v:T):Bool{
		var i = arr.indexOf(v);
		return removeAt(i);
	}
	
	public inline function removeAt(i:Int):Bool {
		if ( i < 0 ) return false;
		if( pos > 1 ){
			arr[i] = arr[pos-1];
			arr[pos-1] = null;
			pos--;
		}
		else {
			arr[0] = null;
			pos = 0;
		}
		return true;
	}
	
	public inline function reserve(n) {
		if (arr.length < n )
			arr[n] = null;
	}
	
	public inline function push(v:T) {
		arr[pos++] = v;
	}
	
	public inline function pop() : T {
		if ( pos == 0 ) return null;
			
		var v = arr[pos-1]; 
		arr[--pos] = null;
		return v;
	}
	
	public inline function unsafeGet(idx:Int) {
		return arr[idx];
	}
	
	public inline function hardReset() {
		for ( i in 0...arr.length) arr[i] = null;
		pos = 0;
	}
	
	public inline function reset() {
		pos = 0;
	}
	
	public inline function iterator() return new StackIterator(arr,get_length());
	public inline function backWardIterator() return new BackwardStackIterator(arr,get_length());	
	public inline function toString() {
		var s = "";
		for ( i in 0...pos) {
			s += Std.string(arr[i]);
		}
		return s;
	}
	
	public inline function toData() {
		return arr;
	}
}