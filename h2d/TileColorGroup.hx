package h2d;
import h3d.Vector;
import hxd.Assert;
import hxd.System;

private class TileLayerContent extends h3d.prim.Primitive {

	var tmp : hxd.FloatStack;
	public var xMin : Float;
	public var yMin : Float;
	public var xMax : Float;
	public var yMax : Float;

	var uploaded = false;
	
	public function new() {
		reset();
	}
	
	public function isEmpty() {
		return buffer == null;
	}

	public function reset() {
		if ( tmp == null ) 	tmp = new hxd.FloatStack();
		else 				tmp.reset();
		
		xMin = hxd.Math.POSITIVE_INFINITY;
		yMin = hxd.Math.POSITIVE_INFINITY;
		xMax = hxd.Math.NEGATIVE_INFINITY;
		yMax = hxd.Math.NEGATIVE_INFINITY;
		uploaded = false;
	}
	
	public override function dispose(){
		super.dispose();
		releaseBuffer();
		uploaded = false;
	}
	
	
	function releaseBuffer(){
		if ( buffer != null ) {
			h3d.impl.Buffer.delete( buffer );
			buffer = null;
			uploaded = false;
		}
	}
	
	function vertCount() {
		return tmp.length >> 3;
	}

	override public function triCount() {
		return (tmp.length >> 4);
	}

	public function add( x : Int, y : Int, r : Float, g : Float, b : Float, a : Float, t : Tile ) {
		var sx = x + t.dx;
		var sy = y + t.dy;
		var sx2 = sx + t.width;
		var sy2 = sy + t.height;
		
		tmp.push(sx);
		tmp.push(sy);
		tmp.push(t.u);
		tmp.push(t.v);
		tmp.push(r);
		tmp.push(g);
		tmp.push(b);
		tmp.push(a);
		tmp.push(sx2);
		tmp.push(sy);
		tmp.push(t.u2);
		tmp.push(t.v);
		tmp.push(r);
		tmp.push(g);
		tmp.push(b);
		tmp.push(a);
		tmp.push(sx);
		tmp.push(sy2);
		tmp.push(t.u);
		tmp.push(t.v2);
		tmp.push(r);
		tmp.push(g);
		tmp.push(b);
		tmp.push(a);
		tmp.push(sx2);
		tmp.push(sy2);
		tmp.push(t.u2);
		tmp.push(t.v2);
		tmp.push(r);
		tmp.push(g);
		tmp.push(b);
		tmp.push(a);
		if( sx < xMin ) xMin = sx;
		if( sy < yMin ) yMin = sy;
		if( sx2 > xMax ) xMax = sx2;
		if( sy2 > yMax ) yMax = sy2;
	}
	
	public function addPoint( x : Float, y : Float, color : Int ) {
		tmp.push(x);
		tmp.push(y);
		tmp.push(0);
		tmp.push(0);
		insertColor(color);
	}

	/**
	 * assumes ARGB construct
	 */
	inline function insertColor( c : Int ) {
		var  r = hxd.Math.b2f(c>>16);
		var  g = hxd.Math.b2f(c>>8);
		var  b = hxd.Math.b2f(c);
		var  a = hxd.Math.b2f(c>>>24);
	
		tmp.push(r);
		tmp.push(g);
		tmp.push(b);
		tmp.push(a);
	}

	public inline function rectColor( x : Float, y : Float, w : Float, h : Float, color : Int ) {
		tmp.push(x);
		tmp.push(y);
		tmp.push(0);
		tmp.push(0);
		insertColor(color);
		tmp.push(x + w);
		tmp.push(y);
		tmp.push(1);
		tmp.push(0);
		insertColor(color);
		tmp.push(x);
		tmp.push(y + h);
		tmp.push(0);
		tmp.push(1);
		insertColor(color);
		tmp.push(x + w);
		tmp.push(y + h);
		tmp.push(1);
		tmp.push(1);
		insertColor(color);
	}

	public inline function rectGradient( x : Float, y : Float, w : Float, h : Float, ctl : Int, ctr : Int, cbl : Int, cbr : Int ) {
		tmp.push(x);
		tmp.push(y);
		tmp.push(0);
		tmp.push(0);
		insertColor(ctl);
		tmp.push(x + w);
		tmp.push(y);
		tmp.push(1);
		tmp.push(0);
		insertColor(ctr);
		tmp.push(x);
		tmp.push(y + h);
		tmp.push(0);
		tmp.push(1);
		insertColor(cbl);
		tmp.push(x + w);
		tmp.push(y + h);
		tmp.push(1);
		tmp.push(0);
		insertColor(cbr);
	}

	override public function alloc(engine:h3d.Engine) {
		if ( tmp == null ) reset();
		
		if( buffer == null){
			var doDirect = false;
			#if sys
			doDirect = true;
			#end
			buffer = engine.mem.allocStack(tmp, 8, 4, true,doDirect);
			uploaded = true;
		}
	}

	public function doRender(engine, min, len) {
		if ( len > 0 ) {
			if ( 	buffer != null  && 	( vertCount() > buffer.nvert) ){
				releaseBuffer();
				//trace("releasing");
			}
				
			//refresh
			if ( 	buffer == null 
			|| 		buffer.isDisposed() ) {
				alloc(engine);
			}
				
			//upload!
			if ( !uploaded ){
				buffer.uploadStack(tmp, 0, vertCount());
				uploaded = true;
			}
			
			engine.renderQuadBuffer(buffer, min, len);
		}
	}
	
	var tmpColor = new Vector();
	
	/**
	 * renders quads
	 */
	public function doEmitRender(ctx:RenderContext, p:h2d.TileColorGroup, min, len) {
		
		if ( len > 0 ) {
			var tile = p.tile;
			var texSlot = ctx.beginDraw(p,p.tile.getTexture());
			
			var base 	= 0;
			var x 		= 0.0;
			var y 		= 0.0;
			var u 		= 0.0;
			var v 		= 0.0;
			
			var xTrs 	= 0.0;
			var yTrs 	= 0.0;
			
			for ( i in min...min + len) {
				for( j in 0...4 ){
					base 	= (i << 5) + (j << 3);
					
					x 		= tmp.get(base);
					y 		= tmp.get(base+1);

					xTrs 	= x * p.matA + y * p.matC + p.absX;
					yTrs 	= x * p.matB + y * p.matD + p.absY;
					
					u 		= tmp.get(base+2);
					v 		= tmp.get(base+3);
					
					tmpColor.r = tmp.get( base + 4 );
					tmpColor.g = tmp.get( base + 5 );
					tmpColor.b = tmp.get( base + 6 );
					tmpColor.a = tmp.get( base + 7 );
					
					ctx.emitVertex( xTrs,yTrs,u,v, tmpColor, texSlot);
				}
			}
		}
	}

}

class TileColorGroup extends Drawable {

	var content : TileLayerContent;
	var curColor : h3d.Vector;

	public var tile : Tile;
	public var rangeMin : Int;
	public var rangeMax : Int;

	public function new(t,?parent) {
		super(parent);
		tile = t;
		rangeMin = rangeMax = -1;
		shader.hasVertexColor = true;
		curColor	= new h3d.Vector(1, 1, 1, 1);
		content 	= new TileLayerContent();
	}

	public function reset() {
		content.reset();
	}

	override function getBoundsRec( relativeTo, out,forSize ) {
		super.getBoundsRec(relativeTo, out,forSize);
		addBounds(relativeTo, out, content.xMin, content.yMin, content.xMax - content.xMin, content.yMax - content.yMin);
	}

	/**
		Returns the number of tiles added to the group
	**/
	public function count() {
		return content.triCount() >> 1;
	}

	override function onDelete() {
		content.dispose();
		super.onDelete();
	}

	public function setDefaultColor( rgb : Int, ?alpha = 1.0 ) {
		hxd.Assert.isTrue( alpha <= 1.0001);
		curColor.x = ((rgb >> 16) & 0xFF) / 255;
		curColor.y = ((rgb >> 8) & 0xFF) / 255;
		curColor.z = (rgb & 0xFF) / 255;
		curColor.w = alpha;
	}

	public inline function add(x, y, t) {
		content.add(x, y, curColor.x, curColor.y, curColor.z, curColor.w, t);
	}

	public inline function addColor(x, y, r, g, b, a, t) {
		content.add(x, y, r, g, b, a, t);
	}

	override function draw(ctx:RenderContext) {
		var min = rangeMin < 0 ? 0 : rangeMin * 2;
		var max = content.triCount();
		if ( rangeMax > 0 && rangeMax < max * 2 ) max = rangeMax * 2;
		var len = max - min;
		
		if ( tile != null && len > 0 ) {
			if ( canEmit() ) {
				content.doEmitRender(ctx, this,min, len>>1);
			}
			else {
				ctx.flush();
				setupShader(ctx.engine, tile, Drawable.BASE_TILE_DONT_CARE);
				content.doRender(ctx.engine, min, len);
			}
		}
		
	}
}
