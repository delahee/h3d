package h3d.scene;

import h2d.Anim;
import h2d.col.Line;
import h2d.col.Point;
import h2d.Tile;
import h3d.Vector;
import hxd.Math;
import hxd.Profiler;

/*
 * uv0------uv0
 * |		|
 * |        |
 * |        |
 * |        |
 * uvn		uvn
 * 
 */

enum NormalMode {
	XAligned;
	YAligned;
	ZAligned;
}

@:allow( Lines2d ) 
class Line2dData {
	public var vertices : Array<h3d.Vector> = [];
	public var colors 	: Array<Int> 		= [];
	public var sizes 	: Array<Float>		= [];
	public var tiles	: Array<Tile> 		= [];
	public var uvs		: Array<h3d.Vector> = []; //padded along left right 
	
	public var normalMode : NormalMode 		= XAligned;
	public var update : Line2dData -> Int -> Float -> Void;

	public var curSize  : Float 	= 0.0;
	public var curColor : Int 		= 0;
	public var curTile 	: h2d.Tile;
	public var length = 0;
	
	public var alpha = 1.0;
	
	public var quadCount(get,null) : Int;
	
	public function new() {
		lineStyle();
	}
	
	///
	inline function get_quadCount() {
		return length;
	}
	
	public inline function lineStyle( ?size = 1.0, ?color = 0xFFFFFF, ?alpha = 1.0, ?tile:h2d.Tile ) {
		curSize = size;
		curColor = (color&0x00FFFFFF) | (hxd.Math.f2b( alpha )<<24);
		curTile = tile;
	}
	
	public function vertex(pos:h3d.Vector, ?auv : h3d.Vector) {
		var i = length++;
		if (vertices.length < length) grow();	
		
		sizes[i] 	= curSize;
		vertices[i]	.load( pos );
		colors[i]	= curColor;
			
		if ( auv == null ) 	uvs[i].set(0, 0, 1, 1);
		else 				uvs[i].load( auv );
	}
	
	function grow() {
		var i = vertices.length;
		vertices[i] = new h3d.Vector();
		colors	[i] = 0x00FFFFFF;
		uvs     [i] = new h3d.Vector(0, 0, 1, 1);
		sizes	[i] = 0;
	}
	
	inline function clear() {
		length = 0;
		alpha = 1.0;
	}
	
	public inline function begin() {
		clear();
	}
	
	public inline function end() {
	}
}

class Lines2d extends h3d.scene.Mesh {
	public var nbQuad = 2048;
	public var nbVertex:Int;
	public var lines : Array<Line2dData> = new Array<Line2dData>();
	
	var quads 		: h3d.prim.StaticPackedQuads;
	var tmpPos 		= new h3d.Vector();
	
	var mat 		= new h3d.Matrix();	
	var worldToCam 	= new h3d.Matrix();
	var camToWorld 	= new h3d.Matrix(); 
	
	var tile : h2d.Tile; 
	var curQuadCount = 0;
	
	@:noDebug
	public function new(tile:h2d.Tile, ?parent:h3d.scene.Object,?nb:Null<Int>) : Void {
		this.tile = tile;
		if ( nb != null) nbQuad = nb;
		nbVertex = nbQuad << 2;
		
		var pos = [];
		pos[nbVertex * 3 - 1] = 0.0;
		for ( i in 0...pos.length ) 
			pos[i] = 0.0;
			
		quads = new h3d.prim.StaticPackedQuads(nbVertex,pos);
		quads.addUV();
		quads.addColor();
		
		super( quads, null, parent);
		
		material.texture = tile.getTexture();
		material.culling = None;
		material.blendMode = Normal;
		material.hasVertexColor = true;
		material.depthWrite = true;
		material.depthTest = Less;
		
		skipOcclusion = true;
	}
	
	public inline function newLine() : Line2dData{
		var s = new Line2dData();
		lines.push( s);
		return s;
	}
	
	public var pool : hxd.Stack<Line2dData> = new hxd.Stack<Line2dData>();
	
	public inline function reserve(n) {
		for ( i in 0...n)
			pool.push( new Line2dData() );
	}
	
	public function allocLine() : Line2dData {
		var l = null;
		if ( pool.length <= 0) 
			l = new Line2dData();
		else 
			l = pool.pop();
		lines.push( l );
		return l;
	}
	
	public function deleteLine(l : Line2dData) {
		lines.remove(l);
		l.lineStyle();
		l.begin();
		l.end();
		pool.push(l);
	}
	
	
	var idx : Int;
	@:noDebug
	override function sync(ctx : h3d.scene.RenderContext) { 
		if (!visible) return;
		
		Profiler.begin("Lines2d.sync");
		worldToCam.loadFrom( ctx.camera.mcam );
		camToWorld.identity().inverse( worldToCam );
		
		curQuadCount = 0;
			
		idx = 0;
		for ( li in 0...lines.length ) {
			var line = lines[li];
			if ( line.quadCount <= 0 ) continue;
			buildLine( line,ctx );
			curQuadCount += line.quadCount;
		}
		
		customTransform = camToWorld;
		posChanged = true;
		
		Profiler.end("Lines2d.sync");
		super.sync(ctx);
	}
	
	var tmpStart:Vector = new Vector();
	var tmpEnd:Vector = new Vector();
	var tmpStartNormal = new Vector();
	var tmpEndNormal = new Vector();
	var c:h3d.Vector = new Vector();
	
	@:noDebug
	function buildLine(l:Line2dData, ctx) {
		var t : Tile;
		var r = 0.0;
		var last = l.length - 1;
		var v;
		var n; 		 
		
		var vsize;
		var nsize;	 
		
		var vuv; 
        var nuv;
		
		var dx;
		var dy;
		var dz;
		for ( i in 0...last ) {
			r = i / (last - 1);
			
			v 		= l.vertices[i];
			n 		= l.vertices[i+1];
			
			vsize 	= l.sizes[i] 		* 0.5;
			nsize 	= l.sizes[i + 1] 	* 0.5;
			
			vuv 	= l.uvs[i];
			nuv 	= l.uvs[i+1];
			
			tmpStart.zero(); tmpEnd.zero();
			t = l.tiles[i] == null ? this.tile : l.tiles[i];
			
			tmpStart.set( v.x, v.y, v.z );
			tmpStart.transformTRS( worldToCam );
			
			tmpEnd.set( n.x, n.y, n.z );
			tmpEnd.transformTRS( worldToCam );
			
			switch( l.normalMode) {
				case XAligned:	tmpStartNormal.set(1, 0, 0);
								tmpEndNormal.set(1, 0, 0);
								
				case YAligned:	tmpStartNormal.set(0, 1, 0);
								tmpEndNormal.set(0, 1, 0);
								
				case ZAligned:	tmpStartNormal.set(0, 0, 1);
								tmpEndNormal.set(0, 0, 1);
			}
			
			//0 is start right
			dx = -tmpStartNormal.x * vsize;
			dy = -tmpStartNormal.y * vsize;
			dz = -tmpStartNormal.z * vsize;
			quads.setVertex( idx, tmpStart.x + dx,	tmpStart.y + dy, tmpStart.z + dz);
			
			//1 is start left
			dx = tmpStartNormal.x * vsize;
			dy = tmpStartNormal.y * vsize;
			dz = tmpStartNormal.z * vsize;
			
			quads.setVertex( idx + 1, tmpStart.x + dx, 	tmpStart.y + dy, tmpStart.z + dz);
			
			//2 is end left
			dx = -tmpEndNormal.x * nsize;
			dy = -tmpEndNormal.y * nsize;
			dz = -tmpEndNormal.z * nsize;
			
			quads.setVertex(idx + 2, tmpEnd.x + dx,	tmpEnd.y + dy, 	tmpEnd.z + dz);
			
			//3 is end right
			dx = tmpEndNormal.x * nsize;
			dy = tmpEndNormal.y * nsize;
			dz = tmpEndNormal.z * nsize;
			
			quads.setVertex( idx+3 , tmpEnd.x + dx,	tmpEnd.y + dy, 	tmpEnd.z + dz);
			
			quads.setUV( idx	, vuv.x, vuv.y);
			quads.setUV( idx+1	, vuv.z, vuv.w);
			quads.setUV( idx+2	, nuv.x, nuv.y);
			quads.setUV( idx+3	, nuv.z, nuv.w);
		
			c.setColor( l.colors[i] );
			c.a *= l.alpha;
			
			quads.setColor(idx,		c.r, c.g, c.b, c.a);
			quads.setColor(idx+1,	c.r, c.g, c.b, c.a);
			
			c.setColor( l.colors[i + 1] );
			c.a *= l.alpha;
			
			quads.setColor(idx+2,	c.r, c.g, c.b, c.a);
			quads.setColor(idx+3,	c.r, c.g, c.b, c.a);
			
			if (l.update != null)
				l.update(l, i, r);
				
			idx += 4;
		}
	}
	
	
	override function draw( ctx : h3d.scene.RenderContext ) {
		if ( primitive != null) primitive.dispose();
		quads.nbVertexToSend = curQuadCount<<2;
		if (quads.nbVertexToSend>0) super.draw(ctx);
	}
	
	public override function destroy() {
		super.destroy();
		
		quads = null;
		tmpPos = null;
		mat = null;
		worldToCam = null;	
		camToWorld 	= null;
		lines = null;
	}
}