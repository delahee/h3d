package h2d;

import h2d.SpriteBatch.BatchElement;
import h3d.impl.Buffer;
import haxe.Timer;
import hxd.Assert;
import hxd.FloatBuffer;
import hxd.System;

private class ElementsIterator {
	var e : BatchElement;

	public inline function new(e) {
		this.e = e;
	}
	public inline function hasNext() {
		return e != null;
	}
	public inline function next() {
		var n = e;
		e = @:privateAccess e.next;
		return n;
	}
}

@:allow(h2d.SpriteBatch)
class BatchElement {

	/**
	 * call changePriority to update the priorty
	 */
	public var priority(default,null) : Int;

	public var x : hxd.Float32;
	public var y : hxd.Float32;

	public var scaleX : hxd.Float32;
	public var scaleY : hxd.Float32;

	//setting this will trigger parent property
	public var rotation : hxd.Float32;

	public var visible : Bool;
	public var alpha : Float;
	public var tile : Tile;
	
	public var colorR : hxd.Float32 = 1.0;
	public var colorG : hxd.Float32 = 1.0;
	public var colorB : hxd.Float32 = 1.0;
	public var colorA : hxd.Float32 = 1.0;
	
	public var batch(default, null) : SpriteBatch;
	public var data					: Dynamic;

	var prev : BatchElement;
	var next : BatchElement;

	@:noDebug
	public inline function new( t : h2d.Tile) {
		x = 0; y = 0; alpha = 1;
		rotation = 0; scaleX = scaleY = 1;
		priority = 0;
		setColor(0xffffff,1.0);
		tile = t;
		visible = true;
	}
	
	public inline function init( t : h2d.Tile) {
		x = 0; y = 0; alpha = 1;
		rotation = 0; scaleX = scaleY = 1;
		priority = 0;
		setColor(0xffffff,1.0);
		tile = t;
		visible = true;
		data = null;
	}
	
	public function copy( e : BatchElement) {
		x = e.x; 
		y = e.y;
		alpha = e.alpha;
		rotation = e.rotation;
		scaleX = e.scaleX;
		scaleY = e.scaleY;
		priority = e.priority;
		colorR = e.colorR;
		colorG = e.colorG;
		colorB = e.colorB;
		colorA = e.colorA;
		tile = e.tile;
		visible = e.visible;
	}
	
	//returns an unattached clone
	public function clone<T>(?s:T) : T {
		var nu : BatchElement = (s==null) ? new BatchElement(tile) : cast s;
		nu.x 		= x; 
		nu.y 		= y;
		nu.alpha 	= alpha;
		nu.rotation = rotation;
		nu.scaleX 	= scaleX;
		nu.scaleY 	= scaleY;
		nu.priority = priority;
		nu.colorR 	= colorR;
		nu.colorG 	= colorG;
		nu.colorB 	= colorB;
		nu.colorA 	= colorA;
		nu.tile 	= tile;
		nu.visible 	= visible;
		if( data!=null) nu.data		= Reflect.copy(data);
		return cast nu;
	}

	@:noDebug
	public function remove() {
		if(batch!=null)	batch.delete(this);
		batch = null;
	}

	public var width(get, set):Float;
	public var height(get, set):Float;

	inline function get_width() return scaleX * tile.width;
	inline function get_height() return scaleY * tile.height;

	inline function set_width(w:Float) {
		scaleX = w / tile.width;
		return w;
	}

	inline function set_height(h:Float) {
		scaleY = h / tile.height;
		return h;
	}
	
	public function setSize(w:Float, h:Float) : Void {
		set_width(w);
		set_height(h);
	}

	public inline function setScale(v:hxd.Float32) {
		scaleX = v;
		scaleY = v;
	}

	public inline function scale(v:hxd.Float32) {
		scaleX *= v;
		scaleY *= v;
	}

	public inline function setPos(x:hxd.Float32, y:hxd.Float32) {
		this.x = x;
		this.y = y;
	}

	public 
	inline 
	function setColor(c:Int, ?a:Float = 1.0) {
		colorR = ((c >> 16)	&0xff)	/ 255.0;
		colorG = ((c >> 8)	&0xff) 	/ 255.0;
		colorB = ((c 	)	&0xff) 	/ 255.0;
		colorA = a;
	}
	
	public 
	inline 
	function setColorF(r,g,b,a) {
		colorR = r;
		colorG = g;
		colorB = b;
		colorA = a;
	}
	
	
	public inline function changePriority(v) {
		this.priority = v;
		if ( batch != null)
		{
			//batch.changePriority(this, v);
			batch.delete(this);
			batch.add( this, v );
		}
		return v;
	}
	
	public function dispose() {
		remove();
		tile = null;
	}

}

/**
	Allocates a new Spritebatch
	parameter `t` tile is the master tile of all the subsequent tiles will be a part of
	parameter `?parent` parent of the sbatch, the final sbatch will inherit transforms (cool ! )

	beware by default all transforms on subtiles ( batch elements ) are allowed but disabling them will enhance performances
	see `hasVertexColor`, `hasRotationScale`, `hasVertexAlpha`
 */
class SpriteBatch extends Drawable {

	public var tile : Tile;
	public var hasRotationScale : Bool; // costs is nearly 0
	public var hasVertexColor(default,set) : Bool; 
	public var hasVertexAlpha(default,set) : Bool; 

	var first : BatchElement;
	var last : BatchElement;
	var length : Int;

	var tmpBuf : hxd.FloatBuffer;

	var optimized : Bool;
	var computed : Bool;
	var optBuffer : Buffer;
	var optPos : Int;

	public function new(masterTile:h2d.Tile, ?parent : h2d.Sprite) {
		super(parent);

		if ( masterTile == null ) throw "masterTile is mandatory";

		var t = masterTile.clone();
		t.dx = 0;
		t.dy = 0;
		tile = t;

		hasVertexColor = true;
		hasRotationScale = true;
		hasVertexAlpha = true;

		tmpMatrix = new Matrix();
	}

	public inline function nbQuad() return length;

	public override function onDelete() {
		super.onDelete();
		if( optBuffer!=null){
			Buffer.delete(optBuffer);
			optBuffer = null;
		}
	}

	public override function dispose() {
		invalidate();
		
		super.dispose();

		removeAllElements();
		tmpBuf = null;
		tile = null;
		first = null;
		last = null;
	}

	/**
	 * If your spritebatch often stays untouched
	 * hinting for staticness will help make a static buffer which will be many times faster than dynamic one
	 * this is best suited for backdrops and static tiling
	 *
	 * please call invalidate() in order to trigger TRS recomputation
	 */
	public function optimizeForStatic(onOff) {
		invalidate();
		optimized = onOff;
	}

	public function removeAllElements() {
		invalidate();
		for( e in getElements() )
			e.remove();
	}

	inline function set_hasVertexColor(b) {
		hasVertexColor=shader.hasVertexColor = b;
		return b;
	}

	inline function set_hasVertexAlpha(b) {
		hasVertexAlpha=shader.hasVertexAlpha = b;
		return b;
	}

	public inline function invalidate() {
		computed = false;
		if ( optBuffer != null) Buffer.delete(optBuffer);
		optBuffer = null;
	}

	/**
	 */
	@:noDebug
	public function add(e:BatchElement, ?prio=0) {
		invalidate();

		e.batch = this;
		e.priority = prio;

		/*should e.remove first
		if ( prio == null )	{
			if( first == null )
				first = last = e;
			else {
				last.next = e;
				e.prev = last;
				last = e;
			}
		}
		else {*/
			if( first == null ){
				first = last = e;
			}
			else {
				var cur = first;
				while ( e.priority <= cur.priority && cur.next != null) // Modified by Seb
					cur = cur.next;

				if ( cur.next == null ) {
					if ( cur.priority >= e.priority) {
						cur.next = e;
						e.prev = cur;

						if( last == cur)
							last = e;
						if ( first == cur )
							first = cur;
					}
					else {
						e.next = cur;
						e.prev = cur.prev;
						if( cur.prev!=null)
							cur.prev.next = e;
						cur.prev = e;
						if( first ==cur )
							first = e;
						if( last == cur )
							last = cur;
					}
				}
				else {
					var p = cur.prev;
					var n = cur;
					e.next = cur;
					cur.prev = e;
					e.prev = p;
					if ( p != null)
						p.next = e;

					if ( p == null )
						first = e;
				}
			}
		// }
		length++;
		
		#if debug
		if ( nbQuad() > 8192 ) {
			//are you really sure that is what you wanted to do...
			//smells like a leak...
			throw "SpriteBatch asssertion : too many elements..."+nbQuad()+" is too much "+name;
		}
		#end
		
		return e;
	}

	/**
	 * no prio, means sprite will be pushed to back
	 * priority means higher is farther
	 */
	@:noDebug
	public inline function alloc(?t:h2d.Tile,?prio:Int) {
		return add(new BatchElement(t==null?tile:t), prio);
	}

	@:allow(h2d.BatchElement)
	@:noDebug
	function delete(e : BatchElement) {
		if( e.prev == null ) {
			if( first == e )
				first = e.next;
		} else
			e.prev.next = e.next;
		if( e.next == null ) {
			if( last == e )
				last = e.prev;
		} else
			e.next.prev = e.prev;

		e.prev = null;
		e.next = null;
		length--;
	}

	@:allow(h2d.BatchElement)
	@:noDebug
	function changePriority(e : BatchElement, newPrio: Int) {
		e.priority = newPrio;
		
		if( first == e ) {
			delete(e);
			add(e, newPrio);
			return;
		}
		
		if( e.batch != this ) {
			add(e, newPrio);
			return;
		}
		
		//BUBBLE
		if (e.prev.priority <= newPrio) {
			var prev = e.prev;
			e.remove();

			while (prev.priority <= newPrio) {
				prev = prev.prev;
				if (prev == null) {
					delete(e);
					add(e, newPrio);
					return;
				}
			}

			var nnext = prev.next;
			if (nnext != null)
				nnext.prev = e;
			e.next = nnext;

			prev.next = e;
			e.prev = prev;
		}
		else {
			var next = e.next;
			if (next == null) return;

			e.remove();

			while (next.priority > newPrio) {//the order is still preserved like a remove/add call pair
				if (next.next == null) {
					next.next = e;
					e.prev = next;

					e.batch = this;
					length++;
					return;
				}
				else 
					next = next.next;
			}

			var nprev = next.prev;
			if (nprev != null) {
				nprev.next = e;
				e.prev = nprev;
			}
			e.next = next;
			next.prev = e;
		}
		
		e.batch = this;
		length++;
	}

	@:noDebug
	public function pushElemSRT( tmp : FloatBuffer, e:BatchElement, pos :Int):Int {
		var t = e.tile;
		if ( t == null ) return 0;
		if ( e.scaleX == 1.0 && e.scaleY == 1.0 && e.rotation == 0.0 ) return pushElem(tmp, e, pos);
 
		var px : hxd.Float32 = t.dx, py = t.dy;
		var hx : hxd.Float32 = t.width;
		var hy : hxd.Float32 = t.height;

		tmpMatrix.identity();
		tmpMatrix.scale(e.scaleX, e.scaleY);
		tmpMatrix.rotate(e.rotation);
		tmpMatrix.translate(e.x, e.y);

		tmp[pos++] = tmpMatrix.transformX(px, py);// (px * ca + py * sa) * e.scale + e.x;
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u;
		tmp[pos++] = t.v;

		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}
		var px = t.dx + hx, py = t.dy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v;

		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}
		var px : hxd.Float32 = t.dx, py = t.dy + hy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}
		var px = t.dx + hx, py = t.dy + hy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}

		return pos;
	}

	@:noDebug
	public function pushElem( tmp : FloatBuffer, e:BatchElement, pos :Int):Int {
		var t = e.tile;
		if ( t == null ) return 0;

		var sx : hxd.Float32 = e.x + t.dx;
		var sy : hxd.Float32 = e.y + t.dy;

		tmp[pos++] = sx;
		tmp[pos++] = sy;
		tmp[pos++] = t.u;
		tmp[pos++] = t.v;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}

		tmp[pos++] = sx + t.width;
		tmp[pos++] = sy;
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}

		tmp[pos++] = sx;
		tmp[pos++] = sy + t.height;
		tmp[pos++] = t.u;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}

		tmp[pos++] = sx + t.width;
		tmp[pos++] = sy + t.height;
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.colorR;
			tmp[pos++] = e.colorG;
			tmp[pos++] = e.colorB;
			tmp[pos++] = e.colorA;
		}

		return pos;
	}

	override function getBoundsRec( relativeTo, out,forSize) {
		super.getBoundsRec(relativeTo, out, forSize);
		
		var eps = 1e-10;
		var e = first;
		while( e != null ) {
			var t = e.tile;
			if( hasRotationScale ) {
				var ca = Math.cos(e.rotation), sa = Math.sin(e.rotation);
				var hx = t.width, hy = t.height;
				var px = t.dx, py = t.dy;
				var x, y;

				tmpMatrix.identity();
				tmpMatrix.scale(e.scaleX, e.scaleY);
				tmpMatrix.rotate(e.rotation);
				tmpMatrix.translate(e.x, e.y);

				x = tmpMatrix.transformX(px, py);
				y = tmpMatrix.transformY(px, py);
				addBounds(relativeTo, out, x, y, eps,eps);

				var px = t.dx + hx, py = t.dy;
				x = tmpMatrix.transformX(px, py);
				y = tmpMatrix.transformY(px, py);
				addBounds(relativeTo, out, x, y, eps,eps);

				var px = t.dx, py = t.dy + hy;
				x = tmpMatrix.transformX(px, py);
				y = tmpMatrix.transformY(px, py);
				addBounds(relativeTo, out, x, y, eps,eps);

				var px = t.dx + hx, py = t.dy + hy;
				x = tmpMatrix.transformX(px, py);
				y = tmpMatrix.transformY(px, py);
				addBounds(relativeTo, out, x, y, eps,eps);
			} else
				addBounds(relativeTo, out, e.x + tile.dx, e.y + tile.dy, tile.width, tile.height);
			e = e.next;
		}
	}
	
	public function getElementBounds( e:BatchElement,relativeTo:h2d.Sprite, ?out) {
		if ( out == null ) 			out = new h2d.col.Bounds();
		if( relativeTo == null ) 	relativeTo = getScene();
		if ( relativeTo == null )	relativeTo = new Sprite();
		
		var eps = 1e-10;
		var ca = Math.cos(e.rotation), sa = Math.sin(e.rotation);
		var t = e.tile;
		var hx = t.width, hy = t.height;
		var px = t.dx, py = t.dy;
		var x, y;
		
		tmpMatrix.identity();
		tmpMatrix.scale(e.scaleX, e.scaleY);
		tmpMatrix.rotate(e.rotation);
		tmpMatrix.translate(e.x, e.y);
		
		x = tmpMatrix.transformX(px, py);
		y = tmpMatrix.transformY(px, py);
		addBounds(relativeTo, out, x, y, eps,eps);

		var px = t.dx + hx, py = t.dy;
		x = tmpMatrix.transformX(px, py);
		y = tmpMatrix.transformY(px, py);
		addBounds(relativeTo, out, x, y, eps,eps);

		var px = t.dx, py = t.dy + hy;
		x = tmpMatrix.transformX(px, py);
		y = tmpMatrix.transformY(px, py);
		addBounds(relativeTo, out, x, y, eps,eps);

		var px = t.dx + hx, py = t.dy + hy;
		x = tmpMatrix.transformX(px, py);
		y = tmpMatrix.transformY(px, py);
		addBounds(relativeTo, out, x, y, eps,eps);
		
		if( out.isEmpty() ) {
			addBounds(relativeTo, out, 0, 0, 1, 1);
			out.xMax = out.xMin;
			out.yMax = out.yMin;
		}
		return out;
	}

	var tmpMatrix:Matrix;

	inline function getStride() {
		var stride = 4;
		if ( hasVertexColor ) stride += 4;
		if ( hasVertexAlpha ) stride += 1;
		return stride;
	}

	@:noDebug
	function computeTRS()  	{
		if ( tmpBuf == null ) tmpBuf = new hxd.FloatBuffer();
		var stride = getStride();
		var len = (length + 1) * stride  * 4;
		if( tmpBuf.length < len)
			tmpBuf.grow( Math.ceil(len * 1.75) );

		var pos = 0;
		var e = first;
		var tmp = tmpBuf;

		if( hasRotationScale ){
			while ( e != null ) {
				if( e.visible )
					pos = pushElemSRT( tmp,e, pos);
				e = e.next;
			}
		}
		else {
			while ( e != null ) {
				if( e.visible )
					pos = pushElem( tmp,e, pos);
				e = e.next;
			}
		}
		computed = true;
		return pos;
	}

	@:noDebug
	override function draw( ctx : RenderContext ) {
		super.draw(ctx);
		if ( first == null ) return;

		var stride = getStride();
		var pos = 0;
		if ( !computed || !optimized ) {
			optPos = pos = computeTRS();
		}
		else
			pos = optPos;

		var nverts = Std.int( pos / stride );

		if ( nbQuad() > 8192 ) {
			#if debug
			//are you really sure that is what you wanted to do...
			//smells like a leak...
			throw "SpriteBatch asssertion : too many elements..."+nbQuad()+" is too much "+name;
			#else
			//prevent buffer fragmentations and crash
			return;
			#end
		}

		if( nbQuad() > 0 ){
			ctx.flush(true);

			var buffer = null;
			if( !optimized ){
				buffer = ctx.engine.mem.alloc(nverts, stride, 4,true);
				buffer.uploadVector(tmpBuf, 0, nverts);
			}else {
				if ( optBuffer == null || optBuffer.isDisposed() ) {
					optBuffer = ctx.engine.mem.alloc(nverts, stride, 4, false);
					optBuffer.uploadVector(tmpBuf, 0, nverts);
				}
				buffer = optBuffer;
			}
			setupShader(ctx.engine, tile, Drawable.BASE_TILE_DONT_CARE);
			ctx.engine.renderQuadBuffer(buffer);

			if( !optimized ){
				Buffer.delete(buffer);
			}
		}
	}

	@:noDebug
	public inline function getElements()  {
		return new ElementsIterator(first);
	}

	//public static var spin = 0;

	public inline function isEmpty() {
		return first == null;
	}

}