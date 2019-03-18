package h3d.impl;
import h3d.impl.MemoryManager.FreeCell;
import haxe.EnumFlags.EnumFlags;
import hxd.System;

@:allow(h3d)
class FreeCell {
	static var GUID = 0;
	var id = -1;
	var pos : Int;
	var count : Int;
	var next : FreeCell;
	inline function new(pos,count,next) {
		this.pos = pos;
		this.count = count;
		this.next = next;
		id = GUID++;
	}
}

enum BigBufferFlag {
	BBF_DYNAMIC;
	BBF_DIRTY;
	BBF_AUTO_RELEASE;
}

@:allow(h3d)
class BigBuffer {

	public static var GUID = 0;
	
	public var id = 0;
	
	var mem : MemoryManager;
	var stride : Int;
	var size : Int;
	
	var vbuf : Driver.VertexBuffer;
	var free : FreeCell;
	var next : BigBuffer;
	var flags : EnumFlags<BigBufferFlag>;
	
	#if debug
	public var allocHead : Buffer;
	#end
	
	
	function new(mem, v, stride, size,isDynamic=false) {
		this.mem = mem;
		this.size = size;
		this.stride = stride;
		this.vbuf = v;
		this.free = new FreeCell(0, size, null);
		flags = EnumFlags.ofInt(0);
		if ( isDynamic ) flags.set(BBF_DYNAMIC);
		id = GUID++;
		//trace("BB: newed " + id);
	}
	
	function reset(mem, v, stride, size, isDynamic = false) {
		this.mem = mem;
		this.size = size;
		this.stride = stride;
		this.vbuf = v;
		this.free = new FreeCell(0, size, null);
		flags = EnumFlags.ofInt(0);
		if ( isDynamic ) flags.set(BBF_DYNAMIC);
		id = GUID++;
	}

	public inline function isDynamic() return flags.has(BBF_DYNAMIC);
	
	@:noDebug
	function freeCursor( pos:Int, nvect:Int ) {
		var prev : FreeCell = null;
		var f = free;
		var end = pos + nvect;
		while( f != null ) {
			if( f.pos == end ) {
				f.pos -= nvect;
				f.count += nvect;
				if( prev != null && prev.pos + prev.count == f.pos ) {
					prev.count += f.count;
					prev.next = f.next;
				}
				nvect = 0;
				break;
			}
			if( f.pos > end ) {
				if( prev != null && prev.pos + prev.count == pos )
					prev.count += nvect;
				else {
					var n = new FreeCell(pos, nvect, f);
					if( prev == null ) free = n else prev.next = n;
				}
				nvect = 0;
				break;
			}
			prev = f;
			f = f.next;
		}
		if( nvect != 0 )
			throw "assert";
	}

	function dispose() {
		//trace("BB: disposed " + id);
		mem.driver.disposeVertex(vbuf);
		vbuf = null;
	}
	
	function isDisposed() {
		return vbuf == null;
	}

	static var pool : hxd.Stack<BigBuffer> = null;
	public static 
	inline 
	function alloc(mem, v, stride, size,isDynamic=false):BigBuffer{
		if ( pool == null ) pool = new hxd.Stack<BigBuffer>();
		
		var b = pool.pop();
		if ( b == null ) 	b = new BigBuffer(mem, v, stride, size,isDynamic=false);
		else  				b.reset(mem, v, stride, size,isDynamic=false);
		
		return b;
	}
	
	public static 
	inline 
	function delete(b:BigBuffer){
		if ( b == null ) return;
		b.dispose();
		b.reset(null, null,0,0,false);
		if ( pool == null ) pool = new hxd.Stack<BigBuffer>();
		pool.push(b);
	}
}

/**
 * VRAM Manager
 */
class MemoryManager {

	#if (desktop&&cpp)
	static inline var MAX_MEMORY = 256 << 20; // MB
	static inline var MAX_BUFFERS = 4096; // Maximum number of buffers
	#else
	static inline var MAX_MEMORY = 512 << 20; // MB
	static inline var MAX_BUFFERS = 16*1024; // Maximum number of buffers
	#end

	@:allow(h3d)
	var driver : Driver;
	
	/**
	 * One buffer per stride type
	 */
	var buffers : Array<BigBuffer>;
	var idict : Map<Indexes,Bool>;
	
	var textures : Array<h3d.mat.Texture>;
	
	public var indexes(default,null) : Indexes;
	public var quadIndexes(default,null) : Indexes;
	public var usedMemory(default,null) : Int;
	public var bufferCount(default,null) : Int;
	public var allocSize(default, null) : Int;
	public var texMemory(default, null) : Int = 0;


	public function new(driver,allocSize) {
		this.driver = driver;
		this.allocSize = allocSize;

		idict = new Map();
		textures = new Array();
		buffers = new Array();
		
		initIndexes();
	}
	
	public inline function textureCount() return textures.length;
	
	public inline function getTextures() return textures;
	
	@:noDebug
	function initIndexes() {
		var indices = new hxd.IndexBuffer();
		for( i in 0...allocSize ) indices.push(i);
		indexes = allocIndex(indices);

		var indices = new hxd.IndexBuffer();
		var p = 0;
		
		var t0 = haxe.Timer.stamp();
		var size = allocSize >> 2;
		#if (desktop&&cpp)
		size = 1024 * 128;
		indices[size-1] = 0; 
		#end
		for( i in 0...size ) {
			var k 			= i << 2;
			indices[i*6] 	= k;
			indices[i*6+1] 	= k + 1;
			indices[i*6+2] 	= k + 2;
			indices[i*6+3] 	= k + 2;
			indices[i*6+4] 	= k + 1;
			indices[i*6+5] 	= k + 3;
		}
		quadIndexes = allocIndex(indices);
		
	}

	/**
		Call user-defined garbage function that will cleanup some unused allocated objects.
		Might be called several times if we need to allocate a lot of memory
	**/
	public dynamic function garbage() {
	}

	/**
		Clean empty	 (unused) buffers
	**/
	public function cleanBuffers() {
		for( i in 0...buffers.length ) {
			var b = buffers[i], prev : BigBuffer = null;
			while( b != null ) {
				if( b.free.count == b.size ) {
					b.dispose();
					bufferCount--;
					usedMemory -= b.size * b.stride * 4;
					if( prev == null )
						buffers[i] = b.next;
					else
						prev.next = b.next;
				} else
					prev = b;
				b = b.next;
			}
		}
	}

	public function stats() {
		var total = 0, free = 0, count = 0;
		for( b in buffers ) {
			var b = b;
			while( b != null ) {
				total += b.stride * b.size * 4;
				var f = b.free;
				while( f != null ) {
					free += f.count * b.stride * 4;
					f = f.next;
				}
				count++;
				b = b.next;
			}
		}
		cleanTextures();
		var tcount = 0, tmem = 0;
		for( t in textures ) {
			tcount++;
			tmem += t.width * t.height * bpp(t);
		}
		return {
			bufferCount : count,
			freeMemory : free,
			totalMemory : total,
			textureCount : tcount,
			textureMemory : tmem,
		};
	}
	
	public function traverseAllocatedBuffers(f) {
		for( b in buffers ) {
			var ba = b;
			while( ba != null ) {
				f(ba);
				ba = ba.next;
			}
		}
	}
	

	public function allocStats() : Array < { allocated:Bool,file : String, line : Int, count : Int, tex : Bool, size : Int
	#if advancedDebug
		,ids:Array<Int> 
	#end
	}> {
		#if !debug
		return [];
		#else
		var h = new Map();
		var all = [];
		
		for ( buf in buffers ) {
			var head = buf;
			var buf = buf;
			while( buf != null ) {
				var b = buf.allocHead;
				while( b != null ) {
					var key = b.allocPos.fileName + ":" + Std.string(b.allocPos.lineNumber);
					var inf = h.get(key);
					if( inf == null ) {
						inf = { allocated:true,file : b.allocPos.fileName, line : b.allocPos.lineNumber, count : 0, size : 0, tex : false
						#if advancedDebug
						,ids:[] 
						#end
						};
						h.set(key, inf);
						all.push(inf);
					}
					inf.count++;
					inf.size += b.nvert * b.b.stride * 4;
					#if advancedDebug
					inf.ids.push(b.id);
					#end
					b = b.allocNext;
				}
				buf = buf.next;
			}
			
			if( head!=null && head.free!=null){
				var b = head.free;
				while( b != null ) {
					var key = "freecell:"+b.id;
					var inf = h.get(key);
					if( inf == null ) {
						inf = { allocated:false,file : "", line : 0, count : 0, size : 0, tex : false
						#if advancedDebug
						,ids:[] 
						#end
						};
						h.set(key, inf);
						all.push(inf);
					}
					inf.count++;
					inf.size += b.count * head.stride * 4;
					#if advancedDebug
					inf.ids.push(b.id);
					#end
					b = b.next;
				}
			}
		}
		for( t in textures ) {
			var key = "$"+t.allocPos.fileName + ":" + t.allocPos.lineNumber;
			var inf = h.get(key);
			if( inf == null ) {
				inf = { allocated:true, file : t.allocPos.fileName, line : t.allocPos.lineNumber, count : 0, size : 0, tex : true
				#if advancedDebug
				,ids:[t.id] 
				#end
				};
				h.set(key, inf);
				all.push(inf);
			}
			inf.count++;
			inf.size += t.width * t.height * 4;
		}
		all.sort(function(a, b) return a.size == b.size ? a.line - b.line : b.size - a.size);
		return all;
		#end
	}
	
	public function textureStats() {
		var a = [];
		
		#if debug
		for( t in textures ) {
			var key = "$"+t.allocPos.fileName + ":" + t.allocPos.lineNumber;
			a.push( { key:key, id:t.id , name:t.name} );
		}
		a.sort( function( e0, e1) return Reflect.compare( e0.id, e1.id));
		#end
		
		return a;
	}
	
	@:allow(h3d.impl.Indexes.dispose)
	function deleteIndexes( i : Indexes ) {
		idict.remove(i);
		driver.disposeIndexes(i.ibuf);
		i.ibuf = null;
		usedMemory -= i.count * 2;
	}
	
	public function readAtfHeader( data : haxe.io.Bytes ) {
		var cubic = (data.get(6) & 0x80) != 0;
		var alpha = false, compress = false;
		switch( data.get(6) & 0x7F ) {
		case 0:
		case 1: alpha = true;
		case 2: compress = true;
		case 3, 4: alpha = true; compress = true;
		case f: throw "Invalid ATF format " + f;
		}
		var width = 1 << data.get(7);
		var height = 1 << data.get(8);
		var mips = data.get(9) - 1;
		return {
			width : width,
			height : height,
			cubic : cubic,
			alpha : alpha,
			compress : compress,
			mips : mips,
		};
	}
	

	/*
	public function allocCustomTexture( fmt : h3d.mat.Data.TextureFormat, width : Int, height : Int, mipLevels : Int = 0, cubic : Bool = false, target : Bool = false, ?allocPos : AllocPos ) {
		cleanTextures();
		return newTexture(fmt, width, height, cubic, target, mipLevels, allocPos);
	}
	
	public function allocTargetTexture( width : Int, height : Int, ?allocPos : AllocPos ) {
		System.trace4("allocating target tex");
		cleanTextures();
		return newTexture(Rgba, width, height, false, true, 0, allocPos);
	}

	public function allocCubeTexture( size : Int, ?mipMap = false, ?allocPos : AllocPos ) {
		cleanTextures();
		var levels = 0;
		if( mipMap ) {
			while( size > (1 << levels) )
				levels++;
		}
		return newTexture(Rgba, size, size, true, false, levels, allocPos);
	}*/

	public function allocIndex( indices : hxd.IndexBuffer, pos = 0, count = -1 ) {
		if( count < 0 ) count = indices.length;
		var ibuf = driver.allocIndexes(count);
		var idx = new Indexes(this, ibuf, count);
		idx.upload(indices, 0, count);
		idict.set(idx, true);
		usedMemory += idx.count * 2;
		return idx;
	}

	public function allocBytes( bytes : haxe.io.Bytes, stride : Int, align, ?isDynamic=false /*,?allocPos : AllocPos*/ ) : Buffer {
		var count = Std.int(bytes.length / (stride * 4));
		var b = alloc(count, stride, align, isDynamic /*,allocPos*/);
		b.uploadBytes(bytes, 0, count);
		return b;
	}

	public function allocStack( v : hxd.FloatStack, stride, align, ?isDynamic = false, ?isDirect = false ) : Buffer {
		var nvert 			= Std.int(v.length / stride);
		var b : Buffer 		= null;
		if ( isDirect ) 	b = allocDirect(nvert, stride, align, isDynamic);
		else 				b = alloc(nvert, stride, align, isDynamic);
		b.uploadStack(v, 0, nvert);
		return b;
	}
	
	public function allocVector( v : hxd.FloatBuffer, stride, align, ?isDynamic=false /*,?allocPos : AllocPos*/ ) : Buffer {
		var nvert = Std.int(v.length / stride);
		var b = alloc(nvert, stride, align, isDynamic /*,allocPos*/);
		b.uploadVector(v, 0, nvert);
		return b;
	}

	
	/**
		The amount of free buffers memory
	 **/
	function freeMemory() {
		var size = 0;
		for( b in buffers ) {
			var b = b;
			while( b != null ) {
				var free = b.free;
				while( free != null ) {
					size += free.count * b.stride * 4;
					free = free.next;
				}
				b = b.next;
			}
		}
		return size;
	}
	
	public function allocDirect( nvect : Int, stride : Int, align : Int, ?isDynamic = false ) : Buffer {
		var nalloc = 16384;//no idea why... probably because base index is 32k and index buffer must be perfectly aligned for validation ?
		var buf = driver.allocVertex( nalloc, stride , isDynamic );
		var b : BigBuffer = BigBuffer.alloc( this, buf , stride, nvect, isDynamic);
		b.flags.set( BBF_AUTO_RELEASE );
		#if flash 
		@:privateAccess buf.b = b;
		#end
		b.free.pos = nvect;
		b.free.count = nalloc-nvect;
		return Buffer.alloc( b,0, nvect );
	}

	/**
		Allocate a vertex buffer.
		Align represent the number of vertex that represent a single primitive : 3 for triangles, 4 for quads
		You can use 0 to allocate your own buffer but in that case you can't use pre-allocated indexes/quadIndexes
		
		nvect is a number of vectors 
		stride is the step between two vectors
		align is the modulo of desired vector so that their start adress are all aligne on same multiple.
		@return Buffer with stride, pos (which is a strided pos)
	 **/
	public function alloc( nvect : Int, stride, align, ?isDynamic = false /*, ?allocPos : AllocPos*/ ) : Buffer {
		#if debug
		//trace( "gpu alloc:"+allocPos.fileName+" " + allocPos.lineNumber+" size:"+(nvect*stride*4));
		//trace( nvect );
		#end
		
		var b : BigBuffer = buffers[stride];
		var free : FreeCell = null;
		
		if ( nvect == 0 && align == 0 ) {
			align = 3;
		}
		//System.trace3('allocating vram nb:$nvect stride:$stride  align:$align dyn:$isDynamic');
			
		while ( b != null ) {
			free = b.free;
			while( free != null ) {
				if( free.count >= nvect && b.isDynamic() == isDynamic && !b.flags.has(BBF_DIRTY) ) {
					// align 0 must be on first index
					if( align == 0 ) {
						if( free.pos != 0 )
							free = null;
						break;
					} else {
						// we can't alloc into a smaller buffer because we might use preallocated indexes
						/*
						if( b.size != allocSize ) {
							free = null;
							break;
						}
						*/
						var d = (align - (free.pos % align)) % align;
						if( d == 0 )
							break;
							
						// insert some padding
						if ( free.count >= nvect + d ) {
							//System.trace3("padding buffer...");
							free.next = new FreeCell(free.pos + d, free.count - d, free.next);
							free.count = d;
							free = free.next;
							break;
						}
					}
					break;
				}
				free = free.next;
			}
			if( free != null ) break;
			b = b.next;
		}
		
		// try splitting big groups
		// we are fairly limited by primitive size anyway so let's remove this
		#if false
		if ( b == null && align > 0 ) {
			//System.trace3("trying to split big free buffers");
			var size = nvect;
			while( size > 65000 ) {
				b = buffers[stride];
				size >>= 1;
				size -= size % align;
				while ( b != null ) {
					free = b.free;
					// skip not aligned buffers
					if( b.size != allocSize || b.isDynamic() != isDynamic || b.flags.has(BBF_DIRTY) )
						free = null;
					while( free != null ) {
						if( free.count >= size ) {
							// check alignment
							var d = (align - (free.pos % align)) % align;
							if( d == 0 )
								break;
							// insert some padding
							if( free.count >= size + d ) {
								free.next = new FreeCell(free.pos + d, free.count - d, free.next);
								free.count = d;
								free = free.next;
								break;
							}
						}
						free = free.next;
					}
					if( free != null ) break;
					b = b.next;
				}
				if( b != null ) break;
			}
		}
		#end
		// buffer not found : allocate a new one
		if ( b == null ) {
			//System.trace3("reusable buffer not found. creating shallow buffer...");
			
			var size=0;
			if( align == 0 ) {
				size = nvect;
				
				var lim = 0;
				#if flash
				lim =  0x7fff;
				#else
				lim =  0x7fffffff;
				#end
				if ( size >= lim ) throw "Too many vertex to allocate " + size;
				
			} else {
				//trace("asked:" + nvect+" <> "+allocSize );
				if ( (nvect * 2) > allocSize ) {
					//trace("using ext");	
					#if (desktop&&cpp)
					size = nvect * 2;
					#else
					size = allocSize; // group allocations together to minimize buffer count
					#end
				} else {
					//trace("using reg");
					size = allocSize;
				}
			}
			var mem = size * stride * 4, v = null;
			//trace("alloc size "+size);
			if( usedMemory + mem > MAX_MEMORY || bufferCount >= MAX_BUFFERS || (v = driver.allocVertex(size,stride,isDynamic)) == null ) {
				var size = usedMemory - freeMemory();
				garbage();
				cleanBuffers();
				if( (usedMemory - freeMemory()) == size ) {
					if( bufferCount >= MAX_BUFFERS )
						throw "Too many vertex buffers : "+bufferCount;
					else
						throw  "Memory full : not enough vertex buffers ( " + mem +" )"+ bufferCount + " for "+size;
				}
				return alloc(nvect, stride, align, isDynamic /*,allocPos*/);
			}
			usedMemory += mem;
			bufferCount++;
			b = new BigBuffer(this, v, stride, size,isDynamic);
			#if flash
			untyped v.b = b;
			#end
			b.next = buffers[stride];
			buffers[stride] = b;
			free = b.free;
		}
		
		
		// always alloc multiples of 4 (prevent quad split)
		var alloc = (nvect > free.count) ? (free.count - (free.count%align)) : nvect;
		var fpos = free.pos;
		free.pos += alloc;
		free.count -= alloc;
		var b = Buffer.alloc(b, fpos, alloc);
		nvect -= alloc;
		#if false
		var head = b.b.allocHead;
		b.allocPos = allocPos;
		b.allocNext = head;
		if( head != null ) head.allocPrev = b;
		b.b.allocHead = b;
		#end
		if ( nvect > 0 ) {
			//System.trace3("not enough space, loooping");
			b.next = this.alloc(nvect, stride, align , isDynamic /*, allocPos */);
		}
			
		//System.trace3("found suitable buffer..."+b);
		return b;
	}

	public function onContextLost() {
		#if debug
		hxd.System.trace2("onContextLost");
		#end
		dispose();
		initIndexes();
	}

	public function dispose() {
		
		indexes.dispose();
		indexes = null;
		quadIndexes.dispose();
		quadIndexes = null;
		
		for( t in textures.copy() )
			t.dispose();
		for( b in buffers.copy() ) {
			var b = b;
			while( b != null ) {
				b.dispose();
				b = b.next;
			}
		}
		for( i in idict.keys() )
			i.dispose();
		buffers = [];
		bufferCount = 0;
		usedMemory = 0;
		texMemory = 0;
	}
	
	// ------------------------------------- TEXTURES ------------------------------------------
	inline function bpp( t : h3d.mat.Texture ) {
		return 4;
	}
	
	public inline function startTextureGC(?delay = 60, ?force = false, ?nb = 128) {
		textures.sort(sortByLRU);
		for( t in textures.copy() ) {
			if ( t.realloc == null ) continue;
			if ( force || 	(t.lastFrame < h3d.Engine.getCurrent().frameCount - delay) ) {
				if(!t.flags.has(NoGC)){
					#if debug
					hxd.System.trace1("GC dispose texture: "+t.name+" (lastFrame="+t.lastFrame+" ; current="+h3d.Engine.getCurrent().frameCount+")");
					#end
					t.dispose();
					nb--;
					if ( nb <= 0) break;
				}
			}
		}
	}
	
	/**
	 * Useful to fully test reallocations
	 */
	public function resetTextures() {
		for ( t in textures.copy() ) {
			t.dispose();
		}
	}
	
	public function cleanTextures( ?delay=1200, ?force = true ) {
		#if !NoTextureGC
		textures.sort(sortByLRU);
		for( t in textures ) {
			if( t.realloc == null ) continue;
			if ( force 
			|| 	(t.lastFrame < h3d.Engine.getCurrent().frameCount - delay) ) {
				if(!t.flags.has(NoGC)){
					#if debug
					hxd.System.trace1("GC dispose texture: "+t.name+" (lastFrame="+t.lastFrame+" ; current="+h3d.Engine.getCurrent().frameCount+")");
					#end
					t.dispose();
					return true;
				}
			}
		}
		#end
		return false;
	}

	inline function sortByLRU( t1 : h3d.mat.Texture, t2 : h3d.mat.Texture ) {
		return t1.lastFrame - t2.lastFrame;
	}

	
	@:allow(h3d.mat.Texture.dispose)
	function deleteTexture( t : h3d.mat.Texture ) {
		driver.disposeTexture(t.t);
		t.t = null;
		texMemory -= t.width * t.height * bpp(t);
		textures.remove(t);
	}

	@:allow(h3d.mat.Texture.alloc)
	function allocTexture( t : h3d.mat.Texture, ?andClean = false) {
		#if debug
		if ( textures.indexOf(t) >= 0) throw "texture already there";
		if ( t.t  != null ) throw "there is already a texture here?";
		#end
		
		if( andClean )
			cleanTextures(false);
			
		t.t = driver.allocTexture(t);
		if( t.t == null ) {
			if ( !cleanTextures(true) ) throw "Maximum texture memory reached";
			
			#if debug
			trace("tex alloc reentrance");
			#end
			allocTexture(t);
			
			return;
		}
		textures.push(t);
		texMemory += t.width * t.height * bpp(t) * (t.isCubic?6:1);
	}

	@:noDebug
	public function reset() {
		for ( b in buffers ) {
			var bs = b;
			while( bs != null){
				bs.flags.unset( BBF_DIRTY );
				bs = bs.next;
			}
		}
	}
}
	