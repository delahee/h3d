package h3d.scene;

import h2d.Tile;
import h3d.scene.Lines3d.Line3dData;
import h3d.Vector;
import hxd.Math;

class Line3dData {
	public var vertices : Array<h3d.Vector> = [];
	public var tangents : Array<h3d.Vector> = [];
	public var colors 	: Array<h3d.Vector> = [];
	public var sizes 	: Array<Float> = [];
	public var tiles	: Array<Tile> = [];
	public var uvs		: Array<h3d.Vector> = []; //padded along left right 
	public var length(default, null) : Int;
	
	var curSize  : Float;
	var curColor  : h3d.Vector = new Vector(1,1,1,1);
	var curTile : h2d.Tile;
	var curUV 	: h3d.Vector  = new Vector(0,0,1,1);
	var hasBegun : Bool;
	var owner : Lines3d;
	public var quadCount(get, null) : Int; inline function get_quadCount() return length;
	
	public function new(owner)  {
		length = 0;
		this.owner=owner;
	}
	
	public function clone() {
		var l 		= new Line3dData(owner);
		
		l.vertices	= vertices.copy();
		l.tangents	= tangents.copy();
		l.colors 	= colors.copy();
		l.sizes 	= sizes.copy();
		l.tiles		= tiles.copy();
		l.uvs		= uvs.copy();
		
		l.curSize  	= curSize;
		l.curColor  = curColor;
		l.curTile 	= curTile.clone();
		l.curUV		= curUV.clone();
		
		l.hasBegun 	= hasBegun;
		l.length    = length;
		return l;
	}
	
	public function lineStyle( ?size = 1.0, ?color = 0xFFFFFFFF, ?alpha = 1.0, ?tile:h2d.Tile ) {
		curSize  = size;
		curColor.setColor(color);
		if ( alpha <= 0) alpha = 0;
		curColor.a *= alpha;
		curTile = tile==null?owner.tile:tile;
		curUV.set( curTile.u, curTile.v, curTile.u2, curTile.v2 );
	}
	
	public inline function vertex(pos:h3d.Vector, tangent:h3d.Vector ) {
		var i = length++;
		if (vertices.length < length) grow();	
		
		vertices[i].load(pos);
		tangents[i].load(tangent);
		uvs     [i].load(curUV); 
		colors  [i].load(curColor);
		
		sizes   [i] = curSize;
		tiles   [i] = curTile;
	}
	
	public inline function reserve(i:Int) {
		while ( --i >= 0 ) 
			grow();
	}
	
	function grow() {
		var i = vertices.length;
		vertices[i] = new h3d.Vector();
		colors	[i] = new h3d.Vector(0,0,0,0);
		tangents[i] = new h3d.Vector();
		uvs     [i] = new h3d.Vector(0, 0, 1, 1);
	}
	
	public function clear() {
		length = 0;
		
		for( c in colors)
			c.a = 0.0;
			
		for ( v in vertices)
			v.zero();
			
		for ( t in tangents)
			t.zero();
			
		curColor.a = 0.0;
	}
	
	public function begin() {
		clear();
		hasBegun = true;
		curTile = owner.tile;
		curUV.set( curTile.u, curTile.v, curTile.u2, curTile.v2 );
	}
	
	public function end() {
		hasBegun = false;
	}
}

class Lines3d extends h3d.scene.Mesh  {
	public var 			nbQuad = 2048;
	public var 			nbVertex:Int;
	public var 			lines : Array<Line3dData> = new Array<Line3dData>();
	public var 			tile(default,null) : h2d.Tile; 
	public var 			freeze = false;
	
	var quads 			: h3d.prim.StaticPackedQuads;
	var frozen 			= false;
	var curQuadCount 	= 0;
	
	public function new(tile:h2d.Tile, ?parent:h3d.scene.Object,?nb:Null<Int>) : Void {
		this.tile = tile;
		if ( nb != null) nbQuad = nb;
		nbVertex = nbQuad << 2;
		
		quads = new h3d.prim.StaticPackedQuads(2048);
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
		name = "trail";
	}
	
	public function invalidate() {
		frozen = false;
	}
	
	public override function clone(?o : Object) : Lines3d{
		var m = o == null ? new Lines3d(tile, parent, nbVertex) : cast o;
		m.frozen = false;
		m.lines = lines.map(function(l) {
			return l.clone();
		});
		return m;
	}
	
	public function newLine() : Line3dData {
		var s = new Line3dData(this);
		lines.push( s);
		return s;
	}
	
	public var pool : hxd.Stack<Line3dData> = new hxd.Stack<Line3dData>();
	public function allocLine() : Line3dData {
		var l = null;
		if ( pool.length <= 0) 
			l= new Line3dData(this);
		else 
			l = pool.pop();
		lines.push( l );
		return l;
	}
	
	public function deleteLine(l : Line3dData) {
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
		
		if ( !freeze || (freeze && !frozen)) {
			curQuadCount = 0;	
			idx = 0;
			for ( li in 0...lines.length ) {
				var line = lines[li];
				if ( line.quadCount <= 0 ) continue;
							
				buildLine( line,ctx );
				curQuadCount += line.quadCount;
			}
			posChanged = true;
			if ( freeze ) frozen = true;
		}
		
		super.sync(ctx);
	}
	
	var tmpStart:Vector = new Vector();
	var tmpEnd:Vector = new Vector();
	var tmpStartTangent = new Vector();
	var tmpEndTangent = new Vector();
	
	function buildLine(l:Line3dData,ctx) {		
		var v: h3d.Vector;
		var n: h3d.Vector;
		var t : Tile;
		
		var last = l.length - 1;
		var dx 		= 0.0;
		var dy 		= 0.0;
		var dz 		= 0.0;
		            
		var vsize;
		var nsize;
		            
		var vuv;
		var nuv;
		var c:h3d.Vector;
		
		for ( i in 0...last ) {
			v 		= l.vertices[i];
			n 		= l.vertices[i + 1];
			
			vsize 	= l.sizes[i] * 0.5;
			nsize 	= l.sizes[i+1] * 0.5;
			
			vuv 	= l.uvs[i];
			nuv 	= l.uvs[i+1];
			
			tmpStart.zero(); tmpEnd.zero();
			tmpStartTangent.zero(); tmpEndTangent.zero();
			t = l.tiles[i];
			
			tmpStart.load( v );
			tmpEnd.load( n );
			
			tmpStartTangent.load(l.tangents[i]);
			tmpEndTangent.load(l.tangents[i+1]);
			
			//0 is start right
			dx = -tmpStartTangent.x * vsize;
			dy = -tmpStartTangent.y * vsize;
			dz = -tmpStartTangent.z * vsize;
			quads.setVertex( idx, tmpStart.x + dx,	tmpStart.y + dy, tmpStart.z + dz);
			
			//1 is start left
			dx = tmpStartTangent.x * vsize;
			dy = tmpStartTangent.y * vsize;
			dz = tmpStartTangent.z * vsize;
			
			quads.setVertex( idx + 1, tmpStart.x + dx, 	tmpStart.y + dy, tmpStart.z + dz);
			
			//2 is end left
			dx = -tmpEndTangent.x * nsize;
			dy = -tmpEndTangent.y * nsize;
			dz = -tmpEndTangent.z * nsize;
			
			quads.setVertex(idx + 2, tmpEnd.x + dx,	tmpEnd.y + dy, 	tmpEnd.z + dz);
			
			//3 is end right
			dx = tmpEndTangent.x * nsize;
			dy = tmpEndTangent.y * nsize;
			dz = tmpEndTangent.z * nsize;
			
			quads.setVertex( idx+3 , tmpEnd.x + dx,	tmpEnd.y + dy, 	tmpEnd.z + dz);
			
			quads.setUV( idx	, vuv.x, vuv.y);
			quads.setUV( idx+1	, vuv.z, vuv.w);
			quads.setUV( idx+2	, nuv.x, nuv.y);
			quads.setUV( idx+3	, nuv.z, nuv.w);
		
			c = l.colors[i];
			quads.setColor(idx,		c.r, c.g, c.b, c.a);
			quads.setColor(idx+1,	c.r, c.g, c.b, c.a);
			
			c = l.colors[i+1];
			quads.setColor(idx+2,	c.r, c.g, c.b, c.a);
			quads.setColor(idx+3,	c.r, c.g, c.b, c.a);
			
			idx += 4;
		}
	}
	
	override function draw( ctx : h3d.scene.RenderContext ) {
		if ( primitive != null) 
			primitive.dispose();
		quads.nbVertexToSend = curQuadCount << 2;
		if (quads.nbVertexToSend>0) super.draw(ctx);
	}
	
	public override function destroy() {
		super.destroy();
		quads = null;
		lines = null;
	}
}