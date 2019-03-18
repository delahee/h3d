package h3d.impl;
import hxd.Assert;


/**
 * VRAM Buffer pointer
 * we should had fvf, stride or anythign meaningfull here, it is too sparse....
 */
class Buffer {

	public static var GUID = 2048;
	
	public var id = 0;
	public var b : MemoryManager.BigBuffer;
	public var pos : Int;
	public var nvert : Int;
	public var next : Buffer;
	
	#if debug
	public var allocPos : AllocPos;
	public var allocNext : Buffer;
	public var allocPrev : Buffer;
	#end
	
	public inline
	function new(b : MemoryManager.BigBuffer, pos, nvert) {
		this.b = b;
		this.pos = pos;
		this.nvert = nvert;
		id = GUID++;
		//trace("B:newing#" + id);
	}
	
	//this buffer is potentially under draw process, it should not be allocated now to avoid stall
	public inline function dirty() {
		b.flags.set( BBF_DIRTY );
	}

	public function toString() {
		return 'id:$id pos:$pos nvert:$nvert ' + ((next == null)?"":'next:${next.id}');
	}
	
	public inline function isDisposed() {
		return b == null || b.isDisposed();
	}
	
	public inline function getDepth() {
		return 1 + ((next == null) ? 0 : next.getDepth());
	}
	
	public function dispose() {
		if ( b != null ) {
			if ( b.flags.has(BBF_AUTO_RELEASE)){
				MemoryManager.BigBuffer.delete(b);
				b = null;
			}
			else {
				b.flags.set(BBF_DIRTY);//don't reuse this frame
				b.freeCursor(pos, nvert);
				#if debug
				if( allocNext != null )
					allocNext.allocPrev = allocPrev;
				if( allocPrev != null )
					allocPrev.allocNext = allocNext;
				if( b.allocHead == this )
					b.allocHead = allocNext;
				#end
				b = null;
				if ( next != null ) next.dispose();
			}
		}
	}
	
	public function uploadStack( stack : hxd.FloatStack, dataPos : Int, nverts:Int) {
		uploadVector( stack.toData(), dataPos, nverts);
	}
	
	public function uploadVector( data : hxd.FloatBuffer, dataPos : Int, nverts : Int ) {
		var cur = this;
		while( nverts > 0 ) {
			if( cur == null ) throw "Too many vertexes";
			var count = nverts > cur.nvert ? cur.nvert : nverts;
			
			cur.b.mem.driver.uploadVertexBuffer(cur.b.vbuf, cur.pos, count, data, dataPos);
			dataPos += count * b.stride;
			nverts -= count;
			cur = cur.next;
		}
	}
	
	public function uploadBytes( data : haxe.io.Bytes, dataPos : Int, nverts : Int ) {
		var cur = this;
		while( nverts > 0 ) {
			if( cur == null ) throw "Too many vertexes";
			var count = nverts > cur.nvert ? cur.nvert : nverts;
			cur.b.mem.driver.uploadVertexBytes(cur.b.vbuf, cur.pos, count, data, dataPos);
			dataPos += count * b.stride * 4;
			nverts -= count;
			cur = cur.next;
		}
	}
	
	public inline function reset(b:h3d.impl.MemoryManager.BigBuffer,pos:Int,nvert:Int){
		id = GUID++;
		this.b = b;
		this.pos = pos;
		this.nvert = nvert;
		next = null;
		
		#if debug
		allocPos 	= null;
		allocNext 	= null;
		allocPrev	= null;
		#end
	}
	
	static var pool : hxd.Stack<Buffer> = null;
	
	public static 
	inline 
	function alloc(ab:h3d.impl.MemoryManager.BigBuffer,pos:Int,nvert:Int):Buffer{
		if ( pool == null ) pool = new hxd.Stack<Buffer>();
		
		var b = pool.pop();
		if ( b == null ) 	b = new Buffer(ab, pos, nvert);
		else  				b.reset(ab,pos,nvert);
		
		return b;
	}
	
	public static 
	inline 
	function delete(b:Buffer){
		if ( b == null ) return;
		b.dispose();
		b.reset(null,0,0);
		
		if ( pool == null ) pool = new hxd.Stack<Buffer>();
		pool.push(b);
	}
}

class BufferOffset {
	public var b : Buffer;
	public var offset : Int;// in float units
	public var shared : Bool; // hint channel setup for low level
	public var stride : Null<Int>;// hint channel setup for low level in byte units
	
	public function new(b, offset,?shared=false,?stride) {
		this.b = b;
		this.offset = offset;
		this.shared = shared;
		this.stride = stride;
	}
	public function dispose() {
		if( b != null ) {
			b.dispose();
			b = null;
		}
	}
	
	public function toString()
	{
		return 'b:$b ofs:$offset shared:$shared stride:$stride';
	}
}