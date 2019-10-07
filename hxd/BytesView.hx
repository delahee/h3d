package hxd;

@:publicFields
class BytesView {
	var bytes 		: haxe.io.Bytes;
	var position	: Int;
	var length			: Int;
	
	inline function new( b:haxe.io.Bytes,p:Int,l:Int) {
		bytes = b;
		position = p;
		length = l;
	}
	
	inline function get( pos : Int ) : Int {
		return bytes.get(pos + position);
	}
	
	inline function set( pos : Int ,v)  {
		bytes.set(pos + position,v);
	}
	
	inline function blit( pos : Int, src : hxd.BytesView, srcpos : Int, len : Int ) : Void {
		return bytes.blit( pos + position, src.bytes, srcpos + src.position, len );
	}
	
	static inline function fromBytes(b) {
		return new BytesView(b, 0, b.length);
	}
}