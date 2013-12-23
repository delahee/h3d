package h3d.fbx;
using h3d.fbx.Data;

class Geometry {

	var lib : Library;
	var root : FbxNode;
	
	public function new(l, root) {
		this.lib = l;
		this.root = root;
	}
	
	public function getVertices() : Array<Float>{
		return root.get("Vertices").getFloats();
	}
	
	public function getPolygons() : Array<Int>{
		return root.get("PolygonVertexIndex").getInts();
	}

	public function getMaterials() {
		var mats = root.get("LayerElementMaterial",true);
		return mats == null ? null : mats.get("Materials").getInts();
	}
	
	
	/**
	 * This is not the vertex index but a geometry index used mainly for blend shape computation ( morph, secondary shapes )
	 * index order is not interesting because we will mutate vertices
	 */
	public function getShapeIndexes() :Array<Int>{
		return root.get("Indexes").getInts();
	}

	/**
		Decode polygon informations into triangle indexes and vertexes indexes.
		Returns vidx, which is the list of vertices indexes and iout which is the index buffer for the full vertex model
	**/
	public function getIndexes() {
		var count = 0, pos = 0;
		var index = getPolygons();
		var vout = [], iout = [];
		for( i in index ) {
			count++;
			if( i < 0 ) {
				index[pos] = -i - 1;
				var start = pos - count + 1;
				for( n in 0...count )
					vout.push(index[n + start]);
				for( n in 0...count - 2 ) {
					iout.push(start + n);
					iout.push(start + count - 1);
					iout.push(start + n + 1);
				}
				index[pos] = i; // restore
				count = 0;
			}
			pos++;
		}
		return { vidx : vout, idx : iout };
	}

	public function getNormals() {
		var nrm = root.get("LayerElementNormal.Normals").getFloats();
		// if by-vertice (Maya in some cases, unless maybe "Split per-Vertex Normals" is checked)
		// let's reindex based on polygon indexes
		if( root.get("LayerElementNormal.MappingInformationType").props[0].toString() == "ByVertice" ) {
			var nout = [];
			for( i in getPolygons() ) {
				var vid = i;
				if( vid < 0 ) vid = -vid - 1;
				nout.push(nrm[vid * 3]);
				nout.push(nrm[vid * 3 + 1]);
				nout.push(nrm[vid * 3 + 2]);
			}
			nrm = nout;
		}
		return nrm;
	}
	
	//it is not necessary to unwind normals 
	public function getShapeNormals() {
		return root.get("Normals").getFloats();
	}
	
	public function getColors() {
		var color = root.get("LayerElementColor",true);
		return color == null ? null : { values : color.get("Colors").getFloats(), index : color.get("ColorIndex").getInts() };
	}
	
	public function getUVs() {
		var uvs = [];
		for( v in root.getAll("LayerElementUV") ) {
			var index = v.get("UVIndex", true);
			var values = v.get("UV").getFloats();
			var index = if( index == null ) {
				// ByVertice/Direct (Maya sometimes...)
				[for( i in getPolygons() ) if( i < 0 ) -i - 1 else i];
			} else index.getInts();
			uvs.push({ values : values, index : index });
		}
		return uvs;
	}
	
	@:access(h3d.fbx.Library.leftHand)
	public function getGeomTranslate() {
		for( p in lib.getParent(root, "Model").getAll("Properties70.P") )
			if( p.props[0].toString() == "GeometricTranslation" )
				return new h3d.col.Point(p.props[4].toFloat() * (lib.leftHand ? -1 : 1), p.props[5].toFloat(), p.props[6].toFloat());
		return null;
	}


}