package h3d.prim;
using h3d.fbx.Data;
import h3d.impl.Buffer;
import h3d.col.Point;
import h3d.prim.FBXModel.FBXBuffers;

import hxd.System;

/*
 * Captures geometry and mem buffers at first send to gpu
 * */
@:publicFields
class FBXBuffers {
	
	var index : Array<Int>;
	var gt : h3d.col.Point;
	var idx : hxd.IndexBuffer;
	var midx : Array<hxd.IndexBuffer>;
	
	var pbuf : hxd.FloatBuffer;
	var	nbuf : hxd.FloatBuffer;
	var	sbuf : hxd.BytesBuffer;
	var	tbuf : hxd.FloatBuffer;
		
	var cbuf : hxd.FloatBuffer;
	var oldToNew : Map < Int, Array<Int> > ;
	
	var originalVerts : Array<Float>;
	public function new() {
		
	}
}

class FBXModel extends MeshPrimitive {

	public var geom(default, null) : h3d.fbx.Geometry;
	public var skin : h3d.anim.Skin;
	public var multiMaterial : Bool;
	
	var bounds : h3d.col.Bounds;
	var curMaterial : Int;
	var groupIndexes : Array<h3d.impl.Indexes>;
	public var isDynamic : Bool;
	
	public var geomCache : FBXBuffers;
	
	public var id = 0;
	static var uid = 0;
	
	public function new(g,isDynamic=false) {
		id = uid++;
		if ( System.debugLevel >= 2 ) trace("FBXModel.new() "+(id=(uid++)));
		super();
		this.geom = g;
		curMaterial = -1;
		this.isDynamic = isDynamic;
	}
	
	/**
	 * If buffer is modified, it MUST be a shallow copy
	 */
	public dynamic function onVertexBuffer( vb : Array<Float> ) :  Array<Float>
	{
		return vb;
	}
	
	/**
	 * If buffer is modified, it MUST be a shallow copy
	 */
	public dynamic function onNormalBuffer( nb : Array<Float> ) : Array<Float>
	{
		return nb;
	}
	
	public function getVerticesCount() {
		return Std.int(geom.getVertices().length / 3);
	}
	
	override function getBounds() {
		if( bounds != null )
			return bounds;
		bounds = new h3d.col.Bounds();
		var verts = geom.getVertices();
		var gt = geom.getGeomTranslate();
		if( gt == null ) gt = new Point();
		if( verts.length > 0 ) {
			bounds.xMin = bounds.xMax = verts[0] + gt.x;
			bounds.yMin = bounds.yMax = verts[1] + gt.y;
			bounds.zMin = bounds.zMax = verts[2] + gt.z;
		}
		var pos = 3;
		for( i in 1...Std.int(verts.length / 3) ) {
			var x = verts[pos++] + gt.x;
			var y = verts[pos++] + gt.y;
			var z = verts[pos++] + gt.z;
			if( x > bounds.xMax ) bounds.xMax = x;
			if( x < bounds.xMin ) bounds.xMin = x;
			if( y > bounds.yMax ) bounds.yMax = y;
			if( y < bounds.yMin ) bounds.yMin = y;
			if( z > bounds.zMax ) bounds.zMax = z;
			if( z < bounds.zMin ) bounds.zMin = z;
		}
		return bounds;
	}
	
	override function render( engine : h3d.Engine ) {
		if( curMaterial < 0 ) {
			super.render(engine);
			return;
		}
		if( indexes == null || indexes.isDisposed() )
			alloc(engine);
		var idx = indexes;
		indexes = groupIndexes[curMaterial];
		if( indexes != null ) super.render(engine);
		indexes = idx;
		curMaterial = -1;
	}
	
	override function selectMaterial( material : Int ) {
		curMaterial = material;
	}
	
	override function dispose() {
		super.dispose();
		if( groupIndexes != null ) {
			for( i in groupIndexes )
				if( i != null )
					i.dispose();
			groupIndexes = null;
		}
	}
	
	override function alloc( engine : h3d.Engine ) {
		dispose();
		
		if ( System.debugLevel >= 2 ) trace('FBXModel(#$id).alloc()');
		
		var verts = geom.getVertices();
		var norms = geom.getNormals();
		
		//give the user a handle
		verts = onVertexBuffer(verts);
		norms = onNormalBuffer(norms);
		
		var tuvs = geom.getUVs()[0];
		var colors = geom.getColors();
		var mats = multiMaterial ? geom.getMaterials() : null;
		
		var gt = geom.getGeomTranslate();
		if( gt == null ) gt = new Point();
		
		var idx = new hxd.IndexBuffer();
		var midx = new Array<hxd.IndexBuffer>();
		
		var pbuf = new hxd.FloatBuffer(), 
			nbuf = (norms == null ? null : new hxd.FloatBuffer()), 
			sbuf = (skin == null ? null : new hxd.BytesBuffer()), 
			tbuf = (tuvs == null ? null : new hxd.FloatBuffer());
			
		var cbuf = (colors == null ? null : new hxd.FloatBuffer());
		
		// skin split
		var sidx = null, stri = 0;
		if( skin != null && skin.isSplit() ) {
			if( multiMaterial ) throw "Multimaterial not supported with skin split";
			sidx = [for( _ in skin.splitJoints ) new hxd.IndexBuffer()];
		}
		
		if ( sbuf != null ) if ( System.debugLevel >= 2 ) trace('FBXModel(#$id).alloc() has skin infos');
		
		var oldToNew : Map < Int, Array<Int> > = new Map();
		
		// triangulize indexes : format is  A,B,...,-X : negative values mark the end of the polygon
		// This Is An Evil desindexing.
		var count = 0, pos = 0, matPos = 0;
		var index = geom.getPolygons();
		
		function link( oindx, nindex ) {
			var tgt = null;
			if ( oldToNew.get( oindx ) == null )
				oldToNew.set( oindx,  tgt = []);
			else tgt = oldToNew.get( oindx );
			tgt.push(nindex);
		}
		
		for( i in index ) {
			count++;
			if( i < 0 ) {
				index[pos] = -i - 1;
				var start = pos - count + 1;
				for( n in 0...count ) {
					var k = n + start;
					var vidx = index[k];
					
					var x = verts[vidx * 3] 	+ gt.x;
					var y = verts[vidx * 3+1] 	+ gt.y;
					var z = verts[vidx * 3+2] 	+ gt.z;
					
					if ( isDynamic ) link(vidx, Math.round(pbuf.length/3) );
					
					pbuf.push(x); 
					pbuf.push(y);
					pbuf.push(z);

					if( nbuf != null ) {
						nbuf.push(norms[k*3]);
						nbuf.push(norms[k*3+1]);
						nbuf.push(norms[k*3+2]);
					}

					if( tbuf != null ) {
						var iuv = tuvs.index[k];
						tbuf.push(tuvs.values[iuv*2]);
						tbuf.push(1 - tuvs.values[iuv * 2 + 1]);
					}
					
					if( sbuf != null ) {
						var p = vidx * skin.bonesPerVertex;
						var idx = 0;
						
						for ( i in 0...skin.bonesPerVertex ) {
							sbuf.writeFloat(skin.vertexWeights[p + i]);
							idx = idx | ( (skin.vertexJoints[p + i] << (8*i)) & 255 ) ;
						}
						
						sbuf.writeInt32(idx);
					}
					
					if( cbuf != null ) {
						var icol = colors.index[k];
						cbuf.push(colors.values[icol * 4]);
						cbuf.push(colors.values[icol * 4 + 1]);
						cbuf.push(colors.values[icol * 4 + 2]);
					}
				}
				// polygons are actually triangle fans
				for ( n in 0...count - 2 ) {
					idx.push(start + n);
					idx.push(start + count - 1);
					idx.push(start + n + 1);
				}
				// by-skin-group index
				if( skin != null && skin.isSplit() ) {
					for( n in 0...count - 2 ) {
						var idx = sidx[skin.triangleGroups[stri++]];
						idx.push(start + n);
						idx.push(start + count - 1);
						idx.push(start + n + 1);
					}
				}
				// by-material index
				if( mats != null ) {
					var mid = mats[matPos++];
					var idx = midx[mid];
					if( idx == null ) {
						idx = new hxd.IndexBuffer();
						midx[mid] = idx;
					}
					for( n in 0...count - 2 ) {
						idx.push(start + n);
						idx.push(start + count - 1);
						idx.push(start + n + 1);
					}
				}
				index[pos] = i; // restore
				count = 0;
			}
			pos++;
		}
		
		if ( isDynamic ) {
			
			geomCache = new FBXBuffers();
			
			geomCache.originalVerts = verts;
			
			geomCache.index = index.copy();
			geomCache.gt = gt;
			geomCache.pbuf = pbuf.clone();
			geomCache.idx = idx;
			geomCache.midx = midx;
			geomCache.tbuf = tbuf;
			geomCache.sbuf = sbuf;
			geomCache.cbuf = cbuf;
			
			var k = 10;
			
			trace("*** INDEX ");
			for ( i in geomCache.index.slice(0,k)) trace(i);
			
			trace("*** PBUF ");
			for ( i in geomCache.pbuf.getNative().slice(0,k*3)) trace(i);
			
			trace("*** IDX ");
			for ( i in geomCache.idx.getNative().slice(0, k)) trace(i);
			
			trace("*** INFOS ");
			trace("geomCache pbuf len : "+geomCache.pbuf.length);
			trace("geomCache idx len : "+geomCache.idx.length);
			
			trace("orig vert len : "+verts.length);
			trace("orig idx len : "+index.length);
			
			trace("*** PBUF - GT ");
			var arr = geomCache.pbuf.getNative().slice(0, k * 3);
			for ( i in 0...Std.int( arr.length / 3 ) ) {
				var eix = arr[i*3];
				var eiy = arr[i*3+1];
				var eiz = arr[i*3+2];
				trace(eix-geomCache.gt.x);
				trace(eiy-geomCache.gt.y);
				trace(eiz-geomCache.gt.z);
			}
			
			trace("*** OLD TO NEW ");
			geomCache.oldToNew = oldToNew;
			
			trace(geomCache.oldToNew.get(0));
			trace(geomCache.oldToNew.get(1));
			trace(geomCache.oldToNew.get(2));
			trace(geomCache.oldToNew.get(3));
			trace(geomCache.oldToNew.get(4));
			trace(geomCache.oldToNew.get(5));
		}
	
		//send !
		addBuffer("pos", engine.mem.allocVector(pbuf, 3, 0));
		if( nbuf != null ) addBuffer("normal", engine.mem.allocVector(nbuf, 3, 0 ));
		if( tbuf != null ) addBuffer("uv", engine.mem.allocVector(tbuf, 2, 0));
		if ( sbuf != null ) {
			
			if ( System.debugLevel>=2 ) trace(' FBXModel(#$id).alloc() allocating weights and indexes');
			
			var nverts = Std.int(sbuf.length / ((skin.bonesPerVertex + 1) * 4));
			var skinBuf = engine.mem.alloc(nverts, skin.bonesPerVertex + 1, 0);
			skinBuf.uploadBytes(sbuf.getBytes(), 0, nverts);
			var bw = addBuffer("weights", skinBuf, 0);
			bw.shared = true; bw.stride = 16;
			
			var bi = addBuffer("indexes", skinBuf, skin.bonesPerVertex);
			bi.shared = true; bi.stride = 16;
		}
		else {
			if ( System.debugLevel>=2 ) trace( ' FBXModel(#$id).alloc() no sbuf thus no index and weights!');
		}
			
		if( cbuf != null ) addBuffer("color", engine.mem.allocVector(cbuf, 3, 0));
		
		indexes = engine.mem.allocIndex(idx);
		if( mats != null ) {
			groupIndexes = [];
			for( i in midx )
				groupIndexes.push(i == null ? null : engine.mem.allocIndex(i));
		}
		if( sidx != null ) {
			groupIndexes = [];
			for( i in sidx )
				groupIndexes.push(i == null ? null : engine.mem.allocIndex(i));
		}
		
		#if false 
			if ( System.debugLevel >= 2 ) {
				var i = 0;
				var meshName = '$id';
				var saveFile = sys.io.File.write( 'FbxData_$meshName.hx', false );
				
				saveFile.writeString('class FbxData_$meshName{\n');
					saveFile.writeString("public static var vertexBuffer : Array<Float> = { var fb = [\n");
					for ( i in 0...pbuf.length) {
						var v = pbuf[i];
						saveFile.writeString(v + ( (i==pbuf.length-1) ? "" : ",") + "\n" );
					}
					saveFile.writeString(" ]; fb; };\n");
					
					saveFile.writeString("public static var indexBuffer : Array<Int> = { var ib = [\n");
					for ( i in 0...idx.length) {
						var v = idx[i];
						saveFile.writeString(v + ( (i==idx.length-1) ? "" : ",") + "\n" );
					}
					saveFile.writeString(" ]; ib; };\n");
					
				saveFile.writeString("}\n");
				saveFile.close();
			}
		#end
	}
	
}
