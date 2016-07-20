package ent;
import h3d.mat.Material;
import h3d.mat.MeshMaterial;
import h3d.Vector;

class Part extends h3d.scene.Mesh  {

	public var nbQuad = 1024;
	public var nbVertex:Int;
	
	public var buf : hxd.Stack<PartData> = new hxd.Stack<PartData>();
	public var zBuf : Array<PartData>=[];
	
	var quads 		: h3d.prim.StaticPackedQuads;
	var tmpPos 		= new h3d.Vector();
	var tmpCamPos 	= new h3d.Vector();
	
	var zsPos0 		= new h3d.Vector();
	var zsPos1 		= new h3d.Vector();
	
	var mat 		= new h3d.Matrix();	
	var worldToCam 	= new h3d.Matrix();
	var camToWorld 	= new h3d.Matrix(); 
	
	public var zsort 	= true;
	
	public var tile(default,set) : h2d.Tile;
	public var garbage : ent.PartData -> Void;
	
	public inline function length() return quads.nbVertexToSend*4;
	
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
		material.culling = Back;
		material.hasVertexColor = true;
		material.depthWrite = false;
		material.depthTest = Less;
		material.blendMode = Normal;
		
		skipOcclusion = true;
		
		name = "Part";
	}
	
	public function alloc(?data:PartData) : PartData {
		if ( data == null ) data = new ent.PartData();
		if ( buf.length >= nbQuad ) //skip
			return data;
		buf.push(data);
		return data;
	}
	
	@:noDebug
	public function update(tmod = 1.0) {
		var i = buf.length-1;
		while ( i >= 0 ) {
			var p = buf.toData()[i];
			if ( p == null ) {
				i--;
				continue;
			}
			
			if ( (p.delay -= tmod) >= 0.0) {
				i--;
				continue;
			}
			
			#if debug
			if ( p.tile!=null && p.tile.getTexture() != tile.getTexture())
				throw "assert";
			#end
			
			p.dx += p.gx * tmod;
			p.dy += p.gy * tmod;
			p.dz += p.gz * tmod;
			
			p.dx *= Math.pow(p.frictx,tmod);
			p.dy *= Math.pow(p.fricty,tmod);
			p.dz *= Math.pow(p.frictz,tmod);
			
			p.x += p.dx * tmod;
			p.y += p.dy * tmod;
			p.z += p.dz * tmod;
			
			p.rotation += p.drotation * tmod;
			p.drotation *=  Math.pow(p.frictrotation, tmod );
			
			p.scale *= Math.pow(p.frictscale,tmod);
			p.ca 	*= Math.pow(p.fricta,tmod);
			
			p.maxlife = Math.max( p.life, p.maxlife );
			p.life -= tmod;
			p.time += tmod;
			p.rtime++;
			
			if( p.update!=null)
				p.update( p );
				
			if ( p.life <= 0.0 || p.kill ) {
				p.ca = 0.0;
				buf.remove( p );
				
				if(p.onDeath != null) p.onDeath(p);
				if(garbage != null) garbage( p );
				
				p.ready = false;
			}
			else 
				p.ready = true;
			
			i--;
		}
	}
	
	function set_tile( t ) {
		reset();
		tile = t;
		if (material != null && t!=null) {
			material.texture = t.getTexture();
			material.blendMode = material.blendMode;
		}
		return t;
	}
	
	public function reset() {
		if( buf!=null){
			for ( b in buf.toData())
				if ( garbage != null )
					garbage(b);
			buf.reset();
		}
	}
	
	var idx : Int;
	
	//@:noDebug
	override function sync(ctx : h3d.scene.RenderContext) { 
		if (!visible) return;
		
		worldToCam.loadFrom( ctx.camera.mcam );
		camToWorld.identity().inverse( worldToCam );
		
		tmpCamPos = ctx.camera.pos;
		
		if ( zsort && buf.length > 0 )
			buf.toData().sort(  function(p0, p1) {
				if ( p0 == null ) 
					return 1;
				if ( p1 == null ) 
					return -1;
				
				zsPos0.x = p0.x - tmpCamPos.x;
				zsPos0.y = p0.y - tmpCamPos.y;
				zsPos0.z = p0.z - tmpCamPos.z;
				
				zsPos1.x = p1.x - tmpCamPos.x;
				zsPos1.y = p1.y - tmpCamPos.y;
				zsPos1.z = p1.z - tmpCamPos.z;
				
				var z0d = zsPos0.lengthSq();
				var z1d = zsPos1.lengthSq();
				
				if ( z0d > z1d ) return -1;
				if ( z0d < z1d ) return 1;
				
				if ( p0.life < p1.life ) return -1;
				if ( p0.life > p1.life ) return 1;
				
				return 0;
			});

		for ( i in 0...quads.colors.length )
			quads.colors[i] = -0.0;
			
		idx = 0;
		var i = 0;
		var a;
		var dx;
		var dy;
		var szX = 0.0;
		var szY = 0.0;
		for ( p in buf) {
			if ( p == null ) 			break;
			if ( p.ca <= 0 || !p.ready ) 
				continue;
			
			var t = p.tile==null?this.tile:p.tile;
			
			tmpPos.set(p.x, p.y, p.z, 1.0);
			tmpPos.transformTRS( worldToCam );
			
			szX = p.sizex * p.scale;
			szY = p.sizey * p.scale;
			
			a 	= p.rotation + Math.PI * 1.75;
			dx 	= Math.cos(a) * szX;
			dy 	= Math.sin(a) * szY;
			quads.setVertex( idx , tmpPos.x + dx,	tmpPos.y + dy, 	tmpPos.z);
			
			a 	= p.rotation + Math.PI * 1.25;
			dx 	= Math.cos(a) * szX;
			dy 	= Math.sin(a) * szY;
			quads.setVertex(idx+1, tmpPos.x + dx,	tmpPos.y + dy, 	tmpPos.z);
			
			a 	= p.rotation + Math.PI * 0.25;
			dx 	= Math.cos(a) * szX;
			dy 	= Math.sin(a) * szY;
			quads.setVertex( idx+2 ,tmpPos.x + dx, 	tmpPos.y + dy, 	tmpPos.z);
			
			a 	= p.rotation + Math.PI * 0.75;
			dx 	= Math.cos(a) * szX;
			dy 	= Math.sin(a) * szY;
			quads.setVertex( idx +3,tmpPos.x + dx,	tmpPos.y + dy, 	tmpPos.z);
			
			quads.setUV( idx	, t.u2, t.v2);
			quads.setUV( idx+1	, t.u,	t.v2);
			quads.setUV( idx+2	, t.u2, t.v);
			quads.setUV( idx+3	, t.u,	t.v);
		
			quads.setColor(idx,		p.cr, p.cg, p.cb, p.ca);
			quads.setColor(idx+1,	p.cr, p.cg, p.cb, p.ca);
			quads.setColor(idx+2,	p.cr, p.cg, p.cb, p.ca);
			quads.setColor(idx+3,	p.cr, p.cg, p.cb, p.ca);
			
			idx += 4;
		}
		
		customTransform = camToWorld;
		posChanged = true;
		
		super.sync(ctx);
	}
	
	override function draw( ctx : h3d.scene.RenderContext ) {
		if ( primitive != null)
			primitive.dispose();
			
		quads.nbVertexToSend = hxd.Math.imin( nbQuad, buf.length )<<2;
		
		if (quads.nbVertexToSend>0)
			super.draw(ctx);
	}
	
	public override function destroy(){
		super.destroy();
		if( quads != null){
			quads.destroy();
			quads= null;
		}
	}
	
	public override function dispose() {
		super.dispose();
		
		quads = null;
		tmpPos = null;
		tmpCamPos = null;
		
		zsPos0 = null;
		zsPos1 = null;	
		
		mat = null;
		worldToCam = null;	
		camToWorld 	= null;
		buf.reset();
		buf = null;
		tile = null;
	}
}