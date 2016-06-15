package h2d;

import h2d.MultiSpriteBatch.MultiBatchElement;
import h3d.impl.Buffer;
import haxe.Timer;
import hxd.Assert;
import hxd.FloatBuffer;
import hxd.System;

private class MultiElementsIterator {
	var e : MultiBatchElement;

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

@:allow(h2d.MultiSpriteBatch)
class MultiBatchElement {

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
	public var color : h3d.Vector;
	public var batch(default, null) : MultiSpriteBatch;
	public var blendMode : h2d.BlendMode = h2d.BlendMode.Normal;

	var prev : MultiBatchElement;
	var next : MultiBatchElement;

	@:noDebug
	public inline function new( t : h2d.Tile) {
		x = 0; y = 0; alpha = 1;
		rotation = 0; scaleX = scaleY = 1;
		priority = 0;
		color = new h3d.Vector(1, 1, 1, 1);
		tile = t;
		visible = true;
	}
	
	public function copy( e : MultiBatchElement) {
		x = e.x; 
		y = e.y;
		alpha = e.alpha;
		rotation = e.rotation;
		scaleX = e.scaleX;
		scaleY = e.scaleY;
		priority = e.priority;
		color.load( e.color );
		tile = e.tile;
		visible = e.visible;
	}
	
	public function getClone() {
		var nu = new MultiBatchElement(tile);
		nu.x = x; 
		nu.y = y;
		nu.alpha = alpha;
		nu.rotation = rotation;
		nu.scaleX = scaleX;
		nu.scaleY = scaleY;
		nu.priority = priority;
		nu.color.load( color );
		nu.tile = tile;
		nu.visible = visible;
		return nu;
	}

	@:noDebug
	public function remove() {
		if(batch!=null)	batch.delete(this);
		batch = null;
	}
	
	@:noDebug
	public function dispose() {
		remove();
		tile = null;
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

	public inline function setColor(c:Int, ?a:Float = 1.0) {
		color.setColor((c & 0xffffff) | (0xff << 24) );
		color.a = a;
	}
	
	public function changePriority(v) {
		this.priority = v;
		if ( batch != null)
		{
			batch.delete(this);
			batch.add( this, v );
		}
		return v;
	}
	
	public inline function getBounds() {
		var bnd = new h2d.col.Bounds();
		var c = tile.getCenterRatio();
		bnd.addPoint2( x - c.x * width, y - c.y * height);
		bnd.addPoint2( x + (1.0 - c.x) * width, y + (1.0 - c.y) * height );
		return bnd;
	}

}

/**
	Allocates a new Spritebatch
	parameter `t` tile is the master tile of all the subsequent tiles will be a part of
	parameter `?parent` parent of the sbatch, the final sbatch will inherit transforms (cool ! )

	beware by default all transforms on subtiles ( batch elements ) are allowed but disabling them will enhance performances
	see `hasVertexColor`, `hasRotationScale`, `hasVertexAlpha`
 */
class MultiSpriteBatch extends Drawable {

	public var hasRotationScale : Bool; // costs is nearly 0
	public var hasVertexColor(default,set) : Bool; 
	public var hasVertexAlpha(default,set) : Bool; 

	var first : MultiBatchElement;
	var last : MultiBatchElement;
	var length : Int;

	var tmpBuf : hxd.FloatBuffer;

	public function new(?parent : h2d.Sprite) {
		super(parent);

		hasVertexColor = true;
		hasRotationScale = true;
		hasVertexAlpha = true;

		tmpMatrix = new Matrix();
	}

	public inline function nbQuad() return length;

	public override function dispose() {
		super.dispose();

		removeAllElements();
		first = null;
		last = null;
	}

	public function removeAllElements() {
		for( e in getElements() )
			e.remove();
	}
	
	public function clearList() {
		first = null;
		last = null;
		length = 0;
	}

	inline function set_hasVertexColor(b) {
		hasVertexColor=shader.hasVertexColor = b;
		return b;
	}

	inline function set_hasVertexAlpha(b) {
		hasVertexAlpha=shader.hasVertexAlpha = b;
		return b;
	}

	/**
	 */
	@:noDebug
	public function add(e:MultiBatchElement, ?prio=0) {
		e.batch = this;
		e.priority = prio;

		//if ( prio == null )	{
			//if( first == null )
				//first = last = e;
			//else {
				//last.next = e;
				//e.prev = last;
				//last = e;
			//}
		//}
		//else {
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
		//}
		length++;
		return e;
	}

	/**
	 * no prio, means sprite will be pushed to back
	 * priority means higher is farther
	 */
	@:noDebug
	public inline function alloc(?t:h2d.Tile,?prio:Int) {
		return add(new MultiBatchElement(t), prio);
	}

	@:allow(h2d.MultiBatchElement)
	@:noDebug
	function delete(e : MultiBatchElement) {
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


	@:noDebug
	public function pushElemSRT( tmp : FloatBuffer, e:MultiBatchElement, pos :Int):Int {
		var t = e.tile;

		#if debug
		Assert.notNull( t , "all elem must have tiles");
		#end
		if ( t == null ) return 0;

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
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}
		var px = t.dx + hx, py = t.dy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v;

		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}
		var px : hxd.Float32 = t.dx, py = t.dy + hy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}
		var px = t.dx + hx, py = t.dy + hy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}

		return pos;
	}

	@:noDebug
	public function pushElem( tmp : FloatBuffer, e:MultiBatchElement, pos :Int):Int {
		var t = e.tile;

		#if debug
		Assert.notNull( t , "all elem must have tiles");
		#end
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
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}

		tmp[pos++] = sx + t.width;
		tmp[pos++] = sy;
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}

		tmp[pos++] = sx;
		tmp[pos++] = sy + t.height;
		tmp[pos++] = t.u;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}

		tmp[pos++] = sx + t.width;
		tmp[pos++] = sy + t.height;
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v2;
		if( hasVertexAlpha)
			tmp[pos++] = e.alpha;
		if ( hasVertexColor ) {
			tmp[pos++] = e.color.x;
			tmp[pos++] = e.color.y;
			tmp[pos++] = e.color.z;
			tmp[pos++] = e.color.w;
		}

		return pos;
	}

	override function getBoundsRec( relativeTo, out,forSize) {
		super.getBoundsRec(relativeTo, out,forSize);
		var e = first;
		while( e != null ) {
			var t = e.tile;
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
			addBounds(relativeTo, out, x, y,1e-10,1e-10);

			var px = t.dx + hx, py = t.dy;
			x = tmpMatrix.transformX(px, py);
			y = tmpMatrix.transformY(px, py);
			addBounds(relativeTo, out, x, y,1e-10,1e-10);

			var px = t.dx, py = t.dy + hy;
			x = tmpMatrix.transformX(px, py);
			y = tmpMatrix.transformY(px, py);
			addBounds(relativeTo, out, x, y,1e-10,1e-10);

			var px = t.dx + hx, py = t.dy + hy;
			x = tmpMatrix.transformX(px, py);
			y = tmpMatrix.transformY(px, py);
			addBounds(relativeTo, out, x, y,1e-10,1e-10);
			
			e = e.next;
		}
	}

	var tmpMatrix:Matrix;

	inline function getStride() {
		var stride = 4;
		if ( hasVertexColor ) stride += 4;
		if ( hasVertexAlpha ) stride += 1;
		return stride;
	}

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
		return pos;
	}

	@:noDebug
	override function draw( ctx : RenderContext ) {
		super.draw(ctx);
		if ( first == null ) return;

		var stride = getStride();
		var bufpos = 0;
		bufpos = computeTRS();
		var nverts = Std.int( bufpos / stride );
		if( nbQuad() > 0 ){
			ctx.flush(true);

			//trace(stride+" " + bufpos + " " + tmpBuf.length);
			var buffer = ctx.engine.mem.alloc(nverts, stride, 4,true);
			buffer.uploadVector(tmpBuf, 0, nverts);
			
			inline function draw( tile:h2d.Tile, blend:h2d.BlendMode,pos:Int, nb:Int) {//nb sprites
				//trace("drawing sprites pos:" + pos + " nb:" + nb);
				//buffer = ctx.engine.mem.alloc(nb*4, stride, 4,true);
				//buffer.uploadVector(tmpBuf, pos * stride * 4, nb * 4);
				//optionnaly, upload everything then render partial ( better ?)
				blendMode = blend;
				setupShader(ctx.engine, tile, Drawable.BASE_TILE_DONT_CARE);
				ctx.engine.renderQuadBuffer(buffer,pos*2,nb*2);
			}
			
			var e = first;
			var start = 0;
			var pos = 0;
			var verts = 0;
			var drawnVerts = 0;
			var tile = e.tile != null ? e.tile : h2d.Tools.getEmptyTile();
			var curTex : h3d.mat.Texture = tile.getTexture();
			var curBlend : h2d.BlendMode = e.blendMode;
			var lastElem = null;
			
			while ( e != null ) {
				if ( e.visible ) {
					curTex = e.tile==null?null:e.tile.getTexture();
					curBlend = e.blendMode;
					lastElem = e;
					break;
				}
				e = e.next;
			}
			
			while ( e != null ) {
				if ( e.visible ) {
					var tile = e.tile != null ? e.tile : h2d.Tools.getEmptyTile();
					var tex = tile.getTexture();
					var blend = e.blendMode;
					if ( curTex != tex || curBlend != e.blendMode ){
						draw(lastElem.tile, lastElem.blendMode, start, pos - start );
						drawnVerts += (pos - start) * 4;
						start = pos;
						curTex = tex;
						curBlend = blend;
					}
					verts += 4;
					lastElem = e;
					pos++;
				}
				e = e.next;
			}
			
			
			if ( drawnVerts < verts ) 
				draw(lastElem.tile, lastElem.blendMode,start, pos - start);
		
			buffer.dispose();
		}
	}

	@:noDebug
	public inline function getElements()  {
		return new MultiElementsIterator(first);
	}

	//public static var spin = 0;

	public inline function isEmpty() {
		return first == null;
	}

}