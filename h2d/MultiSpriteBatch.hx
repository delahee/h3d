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

	public var x 		: hxd.Float32 = 0.0;
	public var y 		: hxd.Float32 = 0.0;

	public var scaleX 	: hxd.Float32 = 1.0;
	public var scaleY 	: hxd.Float32 = 1.0;

	//setting this will trigger parent property
	public var rotation : hxd.Float32 = 0.0;

	public var visible : Bool 	= true;
	public var alpha : Float	= 1.0;
	public var tile : Tile;
	
	public var colorR : hxd.Float32 = 1.0;
	public var colorG : hxd.Float32 = 1.0;
	public var colorB : hxd.Float32 = 1.0;
	public var colorA : hxd.Float32 = 1.0;
	
	public var batch(default, null) : MultiSpriteBatch;
	public var blendMode : h2d.BlendMode 	= h2d.BlendMode.Normal;
	public var data			: Dynamic 		= null;

	var prev : MultiBatchElement;
	var next : MultiBatchElement;

	@:noDebug
	public inline function new( t : h2d.Tile) {
		x = 0; y = 0; alpha = 1.0;
		rotation = 0; scaleX = scaleY = 1;
		priority = 0;
		setColor(0xffffff,1.0);
		tile = t;
		visible = true;
		blendMode = h2d.BlendMode.Normal;
	}
	
	public function copy( e : MultiBatchElement) {
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
		tile.copy( e.tile );
		visible = e.visible;
		blendMode = e.blendMode;
		data = e.data;
	}
	
	public function clone<T>(?s:T) : T {
		var nu : MultiBatchElement = (s==null) ? new MultiBatchElement(tile) : cast s;
		nu.x = x; 
		nu.y = y;
		nu.alpha = alpha;
		nu.rotation = rotation;
		nu.scaleX = scaleX;
		nu.scaleY = scaleY;
		nu.priority = priority;
		nu.colorR = colorR;
		nu.colorG = colorG;
		nu.colorB = colorB;
		nu.colorA = colorA;
		nu.tile = tile.clone();
		nu.visible = visible;
		nu.blendMode = blendMode;
		nu.data = data;
		return cast nu;
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
	
	public inline function setSize(w:Float, h:Float) : Void {
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
	function setColor4(v:h3d.Vector) {
		colorR = v.r;
		colorG = v.g;
		colorB = v.b;
		colorA = v.a;
	}
	
	public 
	inline 
	function setColor32(c:Int) {
		colorR = ((c >> 16)	&0xff)	/ 255.0;
		colorG = ((c >> 8)	&0xff) 	/ 255.0;
		colorB = ((c 	)	&0xff) 	/ 255.0;
		colorA = ((c >>>24)	&0xff) 	/ 255.0;
	}
	
	public 
	inline 
	function setColorF(r,g,b,a) {
		colorR = r;
		colorG = g;
		colorB = b;
		colorA = a;
	}
	
	public inline function getColorI() {
		return 
			(Math.round(colorA*255) << 24)
		|	(Math.round(colorR*255) << 16)
		|	(Math.round(colorG*255) << 8)
		|	(Math.round(colorB*255));
	}
	
	public function changePriority(v) {
		this.priority = v;
		if ( batch != null)
		{
			//batch.changePriority(this, v);
			var b = batch;
			b.delete(this);
			b.add( this, v );
		}
		return v;
	}
	
	public function safeChangePriority(v) {
		if ( v == priority ) return v;
		return changePriority(v);
	}
	
	/**
	 * ! beware as params bounds are not emptied()
	 */
	public 
	inline
	function getBounds( ?cb : h2d.col.Bounds ) : h2d.col.Bounds{
		var bnd = (cb==null)? new h2d.col.Bounds():cb;
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

	var first : MultiBatchElement;
	var last : MultiBatchElement;
	var length : Int;

	var tmpBuf : hxd.FloatBuffer;
	public var debug = false;


	public function new(?parent : h2d.Sprite) {
		super(parent);

		hasRotationScale = true;
		shader.hasVertexAlpha = true;
		shader.hasVertexColor = true;

		tmpMatrix = new Matrix();
	}

	public inline function nbQuad() return length;

	public override function dispose() {
		super.dispose();

		disposeAllElements();
		first = null;
		last = null;
	}

	public function disposeAllElements() {
		for( e in getElements() )
			e.dispose();
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


	/**
	 */
	@:noDebug
	public function add(e:MultiBatchElement, ?prio = 0) {
		e.batch = this;
		e.priority = prio;

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
		
		//#if debug
		//if ( debug ) trace("added");
		//#end 
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
		
		//#if debug
		//if ( debug ) trace("deleted");
		//#end 
	}
	
	@:allow(h2d.MultiBatchElement)
	@:noDebug
	function changePriority(e : MultiBatchElement, newPrio: Int) {
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
	public function pushElemSRT( tmp : FloatBuffer, e:MultiBatchElement, pos :Int):Int {
		var t = e.tile;
		if ( e.scaleX == 1.0 && e.scaleY == 1.0 && e.rotation == 0.0 ) return pushElem(tmp, e, pos);
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

		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;
		var px = t.dx + hx, py = t.dy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v;

		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;
		
		var px : hxd.Float32 = t.dx, py = t.dy + hy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u;
		tmp[pos++] = t.v2;
		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;
		
		var px = t.dx + hx, py = t.dy + hy;
		tmp[pos++] = tmpMatrix.transformX(px, py);
		tmp[pos++] = tmpMatrix.transformY(px, py);
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v2;
		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;

		return pos;
	}

	@:noDebug
	public function pushElem( tmp : FloatBuffer, e:MultiBatchElement, pos :Int):Int {
		var t = e.tile;
		if ( t == null ) return 0;

		var sx : hxd.Float32 = e.x + t.dx;
		var sy : hxd.Float32 = e.y + t.dy;

		tmp[pos++] = sx;
		tmp[pos++] = sy;
		tmp[pos++] = t.u;
		tmp[pos++] = t.v;
		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;

		tmp[pos++] = sx + t.width;
		tmp[pos++] = sy;
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v;
		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;

		tmp[pos++] = sx;
		tmp[pos++] = sy + t.height;
		tmp[pos++] = t.u;
		tmp[pos++] = t.v2;
		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;

		tmp[pos++] = sx + t.width;
		tmp[pos++] = sy + t.height;
		tmp[pos++] = t.u2;
		tmp[pos++] = t.v2;
		tmp[pos++] = e.alpha;
		tmp[pos++] = e.colorR;
		tmp[pos++] = e.colorG;
		tmp[pos++] = e.colorB;
		tmp[pos++] = e.colorA;

		return pos;
	}

	override function getBoundsRec( relativeTo, out,forSize) {
		super.getBoundsRec(relativeTo, out, forSize);
		if ( first == null ) return;
		
		var e = first;
		var t = e.tile;
		var ca = Math.cos(e.rotation), sa = Math.sin(e.rotation);
		var hx = t.width, hy = t.height;
		var px = t.dx, py = t.dy;
		var x, y;
		var eps = 1e-10;
		
		while( e != null ) {
			t = e.tile;
			ca = Math.cos(e.rotation);
			sa = Math.sin(e.rotation);
			hx = t.width; hy = t.height;
			px = t.dx;
			py = t.dy;

			tmpMatrix.identity();
			tmpMatrix.scale(e.scaleX, e.scaleY);
			tmpMatrix.rotate(e.rotation);
			tmpMatrix.translate(e.x, e.y);

			x = tmpMatrix.transformX(px, py);
			y = tmpMatrix.transformY(px, py);
			addBounds(relativeTo, out, x, y, eps, eps);

			var px = t.dx + hx, py = t.dy;
			x = tmpMatrix.transformX(px, py);
			y = tmpMatrix.transformY(px, py);
			addBounds(relativeTo, out, x, y, eps, eps);

			var px = t.dx, py = t.dy + hy;
			x = tmpMatrix.transformX(px, py);
			y = tmpMatrix.transformY(px, py);
			addBounds(relativeTo, out, x, y, eps, eps);

			var px = t.dx + hx, py = t.dy + hy;
			x = tmpMatrix.transformX(px, py);
			y = tmpMatrix.transformY(px, py);
			addBounds(relativeTo, out, x, y, eps, eps);
			
			e = e.next;
		}
	}

	var tmpMatrix:Matrix;

	inline function getStride() {
		var stride = 4;
		stride += 4;
		stride += 1;
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
		
		if ( nbQuad() > 8192 ) {
			#if debug
			//are you really sure that is what you wanted to do...
			//smells like a leak...
			throw "MultiSpriteBatch asssertion : too many elements..."+nbQuad()+" is too much "+name;
			#else
			//prevent buffer fragmentations and crash
			return;
			#end
		}
		
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
		
			h3d.impl.Buffer.delete(buffer);
		}
	}

	public function getElementBounds( e:MultiBatchElement,relativeTo:h2d.Sprite, ?out) {
		if( out == null ) 			out = new h2d.col.Bounds();
		if( relativeTo == null ) 	relativeTo = getScene();
		if( relativeTo == null )	relativeTo = new Sprite();
		
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
		addBounds(relativeTo, out, x, y, 1e-10, 1e-10);
		
		if( out.isEmpty() ) {
			addBounds(relativeTo, out, 0, 0, 1, 1);
			out.xMax = out.xMin;
			out.yMax = out.yMin;
		}
		return out;
	}

	@:noDebug
	public inline function getElements()  {
		return new MultiElementsIterator(first);
	}
	
	@:noDebug
	public inline function collectElements()  {
		var a = [];
		for (e in getElements())
			a.push(e);
		return a;
	}

	public inline function isEmpty() {
		return first == null;
	}
}