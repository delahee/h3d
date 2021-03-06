package h3d.prim;

using h3d.fbx.Data;

import h3d.Engine;
import h3d.impl.Buffer;
import h3d.col.Point;
import h3d.prim.FBXModel.FBXBuffers;
import haxe.ds.Vector;
import hxd.Profiler;

import hxd.ByteConversions;
import hxd.BytesBuffer;
import hxd.FloatBuffer;
import hxd.fmt.h3d.Tools;
import hxd.IndexBuffer;
import hxd.System;

/*
 * Captures geometry and mem buffers at first send to gpu
 * THESE DATA ARE NOT MEANT TO BE MODIFIED, THEY ARE BACKUPS
 * */
@:publicFields
class FBXBuffers {
	
	//var index : Array<Int>;
	var gt : h3d.col.Point;
	var idx : hxd.IndexBuffer; // index buffer
	
	var midx : Array<hxd.IndexBuffer>; //permaterial index
	var sidx : Array<hxd.IndexBuffer>; //per skin part index
	
	var pbuf : hxd.FloatBuffer; //vertex coordinates
	var	nbuf : hxd.FloatBuffer; //normals
	
	var	sbuf : hxd.BytesBuffer; //skinning
	var	tbuf : hxd.FloatBuffer; //uv texture
		
	var cbuf : hxd.FloatBuffer;
	
	var secShapeNames : Array<String>;
	var secShapesIndex 	: Array<Array<Int>>;
	var secShapesVertex : Array<Array<Float>>;
	var secShapesNormal : Array<Array<Float>>;
	
	public function new() {
		
	}
}

class FBXModel extends MeshPrimitive {

	public var 	id = 0;
	static var 	uid = 0;
	
	public var 	geom(default, null) : h3d.fbx.Geometry;
	
	/**
	 * will be null when loading binary data
	 */
	public var 	blendShapes : Array<h3d.fbx.Geometry>;
	
	public var 	skin : h3d.anim.Skin;
	public var 	multiMaterial : Bool;
	
	var 		bounds : h3d.col.Bounds;
	var 		curMaterial : Int;
	var 		groupIndexes : Array<h3d.impl.Indexes>;
	public var 	isDynamic : Bool;
	
	public var 	geomCache : FBXBuffers;
	public var 	ratios : Null<haxe.ds.Vector<Float>>;
	
	public function new(g,isDynamic=false) {
		id = uid++;
		super();
		this.geom = g;
		curMaterial = -1;
		this.isDynamic = isDynamic;
		blendShapes = geom==null?null:[];
	}
	
	public function fork() {
		var c = new FBXModel(geom, isDynamic);
		c.geomCache = geomCache;
		c.bufferCache = null;
		c.skin = skin;
		return c;
	}
	
	public function getVerticesCount() {
		if( geom != null ) return Math.ceil(geom.getVertices().length / 3);
		if( geomCache == null)  alloc(h3d.Engine.getCurrent());
		return Std.int(geomCache.pbuf.length / 3);
	}
	
	public function getNbShapes() {
		if ( blendShapes != null ) return blendShapes.length;
		if ( geomCache != null ) return geomCache.secShapesIndex.length;
		
		return 0;
	}
	
	override function getBounds() {
		if ( geomCache == null) 
			alloc(h3d.Engine.getCurrent());
			
		if( bounds != null )
			return bounds;
			
		bounds = new h3d.col.Bounds();
		var gt = geomCache.gt;
		
		var verts = geomCache.pbuf;
		
		if( verts.length > 0 ) {
			bounds.xMin = bounds.xMax = verts[0] + gt.x;
			bounds.yMin = bounds.yMax = verts[1] + gt.y;
			bounds.zMin = bounds.zMax = verts[2] + gt.z;
		}
		
		var pos = 3;
		for ( i in 1...Std.int(verts.length / 3) ) {
			
			var x = verts[pos++] + gt.x;
			var y = verts[pos++] + gt.y;
			var z = verts[pos++] + gt.z;
			
			if( x > bounds.xMax ) bounds.xMax = x;
			if( x < bounds.xMin ) bounds.xMin = x;
			if ( y > bounds.yMax ) bounds.yMax = y;
			
			if( y < bounds.yMin ) bounds.yMin = y;
			if( z > bounds.zMax ) bounds.zMax = z;
			if( z < bounds.zMin ) bounds.zMin = z;
		}
		return bounds;
	}
	
	@:noDebug
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
	
	
	//this function is way too big, we should split it.
	@:noDebug
	override function alloc( engineengine : h3d.Engine ) {
		dispose();
		
		if ( geomCache != null){
			send();
			if ( ratios != null ) setShapeRatios( ratios );
			return;
		}
			
		var verts = geom.getVertices();
		var norms = geom.getNormals();
		
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
		
		var oldToNew : Map < Int, Array<Int> > = new Map();//based on positionnal vertex
		
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
		
		function cmp(v0, v1) return hxd.Math.isNear(v0, v1, 0.01);
		
		for( i in index ) {
			count++;
			if( i < 0 ) {
				index[pos] = -i - 1;
				var start = pos - count + 1;
				for ( n in 0...count ) {
					var k = start + n;
					var vidx = index[k];
					
					var x = verts[vidx * 3] 	+ gt.x;
					var y = verts[vidx * 3+1] 	+ gt.y;
					var z = verts[vidx * 3+2] 	+ gt.z;
					
					var newVertexIndex = Std.int(pbuf.length / 3);
					
					link(vidx, newVertexIndex );
					
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
						for( i in 0...skin.bonesPerVertex ) {
							sbuf.writeFloat(skin.vertexWeights[p + i]);
							idx = (skin.vertexJoints[p + i] << (8*i)) | idx;
						}
						sbuf.writeInt32(idx);
					}
					
					if( cbuf != null ) {
						var icol = colors.index[k];
						cbuf.push(colors.values[icol * 4]);
						cbuf.push(colors.values[icol * 4 + 1]);
						cbuf.push(colors.values[icol * 4 + 2]);
						cbuf.push(colors.values[icol * 4 + 3]);
					}
				}
				
				inline function last(arr:Array<Int>) {
					return arr[arr.length - 1];
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
		
		geomCache = new FBXBuffers();
		
		geomCache.gt = gt;
		geomCache.pbuf = pbuf;
		geomCache.idx = idx;
		geomCache.midx = midx;
		geomCache.sidx = sidx;
		geomCache.tbuf = tbuf;
		geomCache.nbuf = nbuf;
		geomCache.sbuf = sbuf;
		geomCache.cbuf = cbuf;
		
		geomCache.secShapesIndex = [];
		geomCache.secShapesVertex = [];
		geomCache.secShapesNormal = [];
		geomCache.secShapeNames = [];
		
		for ( b in blendShapes) {
			var arrIdx : Array<Int>= [];
			var arrVtx : Array<Float> = [];
			var arrNormal : Array<Float> = [];
			
			var bVertex = b.getVertices();
			var bNormal = b.getShapeNormals();
			
			var i = 0;
			//for every newly generated vertex
			for ( idx in b.getShapeIndexes()) {
				var o2n = oldToNew.get( idx );
				
				for ( idx in o2n ) {
					arrIdx.push( idx );
					
					var vidx3 = idx * 3;
					
					//map shape vertex to index
					arrVtx.push(bVertex[i * 3]);
					arrVtx.push(bVertex[i * 3 + 1]);
					arrVtx.push(bVertex[i * 3 + 2]);
					
					//map shape normal to index
					if ( norms != null) {
						arrNormal.push(bNormal[i * 3]);
						arrNormal.push(bNormal[i * 3+1]);
						arrNormal.push(bNormal[i * 3+2]);
					}
				}
				i++;
			}
			geomCache.secShapeNames.push(b.getRoot().name);
			geomCache.secShapesIndex.push(arrIdx);
			geomCache.secShapesVertex.push(arrVtx);
			if(arrNormal!=null)
				geomCache.secShapesNormal.push(arrNormal);
		}
	
		send();
		if ( ratios != null ) setShapeRatios( ratios );
	}
	
	/**
	 * You better have forked your primitives...
	 * @param	ratios
	 */
	@:noDebug
	public function setShapeRatios( ratios : haxe.ds.Vector<Float>) {
		var engine = h3d.Engine.getCurrent();
		if ( geomCache == null) alloc(h3d.Engine.getCurrent());
		if ( bufferCache == null ) send();
		
		var workBuf : hxd.FloatBuffer = geomCache.pbuf.clone();
		var nbTargets = geomCache.secShapesIndex.length;
		var r:Float;
		for ( si in 0...nbTargets) {
			var idx = geomCache.secShapesIndex[si];
			var vertices = geomCache.secShapesVertex[si];
			r = (si >= ratios.length) ? 0.0 : ratios[si];
			
			if ( r <= 0.0 ) continue;
			
			var vidx3:Int=0;
			var i3:Int=0;
			for ( vidx in idx ) { 
				vidx3 				= vidx * 3;
				workBuf[vidx3  ]	+= r * vertices[i3];
				workBuf[vidx3+1] 	+= r * vertices[i3+1];
				workBuf[vidx3+2] 	+= r * vertices[i3+2];
				i3+=3;
			}
		}
		addBuffer( "pos", engine.mem.allocVector(workBuf, 3, 0, isDynamic));
		
		workBuf = null;
		
		var b = getBuffer("normal");
		if ( b != null ) {
			
			workBuf = geomCache.nbuf.clone();
			for ( si in 0...nbTargets) {
				var idx = geomCache.secShapesIndex[si];
				var normals = geomCache.secShapesNormal[si];
				r = (si >= ratios.length) ? 0.0 : ratios[si];
				if ( r <= 0.0 ) continue;
				var vidx3:Int=0;
				var i3:Int=0;
				for ( vidx in idx ) { 
					vidx3 = vidx * 3;
					workBuf[vidx3  ] 	+= r * normals[i3  ];
					workBuf[vidx3+1] 	+= r * normals[i3+1];
					workBuf[vidx3+2] 	+= r * normals[i3+2];
					i3+=3;
				}
			}
			
			for ( si in 0...nbTargets) {
				var idx = geomCache.secShapesIndex[si];
				var r = (si >= ratios.length) ? 0.0 : ratios[si];
				if ( r <= 0.0 ) continue;
				var vidx3;
				for ( vidx in idx ) { 
					vidx3 = vidx * 3;
					var nx = workBuf[vidx3 ];
					var ny = workBuf[vidx3+1];
					var nz = workBuf[vidx3+2];
					var d = Math.sqrt(nx * nx  + ny * ny +nz * nz);
					
					if ( d != 0.0 ) {
						var l = 1.0 / d;
						workBuf[vidx3  ] 	= nx*l;
						workBuf[vidx3+1] 	= ny*l;
						workBuf[vidx3+2] 	= nz*l;
					}
				}
			}
			addBuffer( "normal", engine.mem.allocVector(workBuf, 3, 0, isDynamic));
			workBuf = null;
		}
		
		if( this.ratios == null || this.ratios.length < ratios.length) 
			this.ratios = new haxe.ds.Vector(ratios.length);
		haxe.ds.Vector.blit( ratios, 0, this.ratios, 0, ratios.length );
	}
	
	@:noDebug
	function send() {
		var engine = h3d.Engine.getCurrent();
		if ( engine == null ) return;
		
		addBuffer("pos", engine.mem.allocVector(geomCache.pbuf, 3, 0, isDynamic ));
		
		if( geomCache.nbuf != null ) addBuffer("normal", engine.mem.allocVector(geomCache.nbuf, 3, 0, isDynamic ));
		if( geomCache.tbuf != null ) addBuffer("uv", engine.mem.allocVector(geomCache.tbuf, 2, 0));
		if( geomCache.sbuf != null ) {
			var nverts = Std.int(geomCache.sbuf.length / ((skin.bonesPerVertex + 1) * 4));
			var skinBuf = engine.mem.alloc(nverts, skin.bonesPerVertex + 1, 0);
			skinBuf.uploadBytes(geomCache.sbuf.getBytes(), 0, nverts);
			var bw = addBuffer("weights", skinBuf, 0);
			bw.shared = true; bw.stride = 16;
			
			var bi = addBuffer("indexes", skinBuf, skin.bonesPerVertex);
			bi.shared = true; bi.stride = 16;
		}
			
		if( geomCache.cbuf != null ) addBuffer("color", engine.mem.allocVector(geomCache.cbuf, 4, 0));
		
		indexes = engine.mem.allocIndex(geomCache.idx);
		if( geomCache.midx != null ) {
			groupIndexes = [];
			for( i in geomCache.midx )
				groupIndexes.push(i == null ? null : engine.mem.allocIndex(i));
		}
		if( geomCache.sidx != null ) {
			groupIndexes = [];
			for( i in geomCache.sidx )
				groupIndexes.push(i == null ? null : engine.mem.allocIndex(i));
		}
	}
	
	@:noDebug
	public override function ofData(data:hxd.fmt.h3d.Data.Geometry) {
		geomCache = new FBXBuffers();
		
		var t = hxd.fmt.h3d.Tools;
		
		this.multiMaterial = data.isMultiMaterial;
		this.isDynamic = data.isDynamic;
		this.skin = null; //to do find it back !
		
		geomCache.idx = t.bytesToIntArray( data.index );
		geomCache.gt = new h3d.col.Point(data.gt.x, data.gt.y, data.gt.y);
		geomCache.pbuf = hxd.FloatBuffer.fromBytes( data.positions );
			
		if ( data.uvs!= null) 		
			geomCache.tbuf = hxd.FloatBuffer.fromBytes(data.uvs);
		if( data.normals != null) 
			geomCache.nbuf = hxd.FloatBuffer.fromBytes(data.normals) ;
			
		if( data.skinning != null)
			geomCache.sbuf = hxd.BytesBuffer.ofBytes(data.skinning);
			
		if ( data.colors != null ) 
			geomCache.cbuf = hxd.FloatBuffer.fromBytes( data.colors );
		
		geomCache.secShapesIndex = [];
		geomCache.secShapesVertex = [];
		geomCache.secShapesNormal = [];
		geomCache.secShapeNames = [];
		
		for ( a in data.extra ) {
			geomCache.secShapeNames.push( "" );
			geomCache.secShapesIndex.push( t.bytesToIntArray(a.index ));
			geomCache.secShapesVertex.push( t.bytesToFloatArray(a.positions ));
			geomCache.secShapesNormal.push( t.bytesToFloatArray(a.normals));
		}
		
		if( multiMaterial)
			geomCache.midx = data.groupIndexes.map(function(b)
				return hxd.IndexBuffer.fromBytes(b)
			);
		else if ( data.isSkinned ) 
			geomCache.midx = data.groupIndexes.map(function(b)
				return hxd.IndexBuffer.fromBytes(b)
			);
		
		super.ofData(data);
	}
}
