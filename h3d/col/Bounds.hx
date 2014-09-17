package h3d.col;
import hxd.Math;

class Bounds {
	
	public var xMin : hxd.Float32;
	public var xMax : hxd.Float32;
	public var yMin : hxd.Float32;
	public var yMax : hxd.Float32;
	public var zMin : hxd.Float32;
	public var zMax : hxd.Float32;
	
	public inline function new() {
		empty();
	}
	
	@:noDebug
	/**
	 * 
	 * @param	mvp is the .m matrix field of the h3d.scene.camera
	 */
	public function inFrustum( mvp : Matrix ) {

		// left
		if( testPlane(new Plane(mvp._14 + mvp._11, mvp._24 + mvp._21 , mvp._34 + mvp._31, -(mvp._44 + mvp._41))) < 0 )
			return false;
		
		// right
		if( testPlane(new Plane(mvp._14 - mvp._11, mvp._24 - mvp._21 , mvp._34 - mvp._31, mvp._41 - mvp._44)) < 0 )
			return false;

		// bottom
		if( testPlane(new Plane(mvp._14 + mvp._12, mvp._24 + mvp._22 , mvp._34 + mvp._32, -(mvp._44 + mvp._42))) < 0 )
			return false;

		// top
		if( testPlane(new Plane(mvp._14 - mvp._12, mvp._24 - mvp._22 , mvp._34 - mvp._32, mvp._42 - mvp._44)) < 0 )
			return false;

		// near
		if( testPlane(new Plane(mvp._13, mvp._23, mvp._33, -mvp._43)) < 0 )
			return false;

		// far
		if( testPlane(new Plane(mvp._14 - mvp._13, mvp._24 - mvp._23, mvp._34 - mvp._33, mvp._43 - mvp._44)) < 0 )
			return false;
			
		return true;
	}
	
	@:noDebug
	inline
	function testPlane( p : Plane ) {
		var a = p.nx;
		var b = p.ny;
		var c = p.nz;
		var dd = a * (xMax + xMin) + b * (yMax + yMin) + c * (zMax + zMin);
		if( a < 0 ) a = -a;
		if( b < 0 ) b = -b;
		if( c < 0 ) c = -c;
		var rr = a * (xMax - xMin) + b * (yMax - yMin) + c * (zMax - zMin);
		return dd + rr - p.d*2;
	}
	
	/**
	 * Check if the camera model-view-projection Matrix intersects with the Bounds. Returns -1 if outside, 0 if interests and 1 if fully inside.
	 * @param	mvp : the model-view-projection matrix to test against
	 * @param	checkZ : tells if we will check against the near/far plane
	 */
	public function inFrustumDetails( mvp : Matrix, checkZ = true ) {
		var ret = 1;
		
		// left
		var p = new Plane(mvp._14 + mvp._11, mvp._24 + mvp._21 , mvp._34 + mvp._31, mvp._44 + mvp._41);
		var m = p.nx * (p.nx > 0 ? xMax : xMin) + p.ny * (p.ny > 0 ? yMax : yMin) + p.nz * (p.nz > 0 ? zMax : zMin);
		if( m + p.d < 0 )
			return -1;
		var n = p.nx * (p.nx > 0 ? xMin : xMax) + p.ny * (p.ny > 0 ? yMin : yMax) + p.nz * (p.nz > 0 ? zMin : zMax);
		if( n + p.d < 0 ) ret = 0;
		// right
		var p = new Plane(mvp._14 - mvp._11, mvp._24 - mvp._21 , mvp._34 - mvp._31, mvp._44 - mvp._41);
		var m = p.nx * (p.nx > 0 ? xMax : xMin) + p.ny * (p.ny > 0 ? yMax : yMin) + p.nz * (p.nz > 0 ? zMax : zMin);
		if( m + p.d < 0 )
			return -1;
		var n = p.nx * (p.nx > 0 ? xMin : xMax) + p.ny * (p.ny > 0 ? yMin : yMax) + p.nz * (p.nz > 0 ? zMin : zMax);
		if( n + p.d < 0 ) ret = 0;
		// bottom
		var p = new Plane(mvp._14 + mvp._12, mvp._24 + mvp._22 , mvp._34 + mvp._32, mvp._44 + mvp._42);
		var m = p.nx * (p.nx > 0 ? xMax : xMin) + p.ny * (p.ny > 0 ? yMax : yMin) + p.nz * (p.nz > 0 ? zMax : zMin);
		if( m + p.d < 0 )
			return -1;
		var n = p.nx * (p.nx > 0 ? xMin : xMax) + p.ny * (p.ny > 0 ? yMin : yMax) + p.nz * (p.nz > 0 ? zMin : zMax);
		if( n + p.d < 0 ) ret = 0;
		
		// top
		var p = new Plane(mvp._14 - mvp._12, mvp._24 - mvp._22 , mvp._34 - mvp._32, mvp._44 - mvp._42);
		var m = p.nx * (p.nx > 0 ? xMax : xMin) + p.ny * (p.ny > 0 ? yMax : yMin) + p.nz * (p.nz > 0 ? zMax : zMin);
		if( m + p.d < 0 )
			return -1;
		var n = p.nx * (p.nx > 0 ? xMin : xMax) + p.ny * (p.ny > 0 ? yMin : yMax) + p.nz * (p.nz > 0 ? zMin : zMax);
		if( n + p.d < 0 ) ret = 0;
				
		if( checkZ ) {
			// nea
			var p = new Plane(mvp._13, mvp._23, mvp._33, mvp._43);
			var m = p.nx * (p.nx > 0 ? xMax : xMin) + p.ny * (p.ny > 0 ? yMax : yMin) + p.nz * (p.nz > 0 ? zMax : zMin);
			if( m + p.d < 0 )
				return -1;
			var n = p.nx * (p.nx > 0 ? xMin : xMax) + p.ny * (p.ny > 0 ? yMin : yMax) + p.nz * (p.nz > 0 ? zMin : zMax);
			if( n + p.d < 0 ) ret = 0;

			var p = new Plane(mvp._14 - mvp._13, mvp._24 - mvp._23, mvp._34 - mvp._33, mvp._44 - mvp._43);
			var m = p.nx * (p.nx > 0 ? xMax : xMin) + p.ny * (p.ny > 0 ? yMax : yMin) + p.nz * (p.nz > 0 ? zMax : zMin);
			if( m + p.d < 0 )
				return -1;
			var n = p.nx * (p.nx > 0 ? xMin : xMax) + p.ny * (p.ny > 0 ? yMin : yMax) + p.nz * (p.nz > 0 ? zMin : zMax);
			if( n + p.d < 0 ) ret = 0;
		}
		
		return ret;
	}
	
	public function transform3x4( m : Matrix ) {
		var xMin = xMin, yMin = yMin, zMin = zMin, xMax = xMax, yMax = yMax, zMax = zMax;
		empty();
		var v = new h3d.col.Point();
		v.set(xMin, yMin, zMin);
		v.transform(m);
		addPoint(v);
		v.set(xMin, yMin, zMax);
		v.transform(m);
		addPoint(v);
		v.set(xMin, yMax, zMin);
		v.transform(m);
		addPoint(v);
		v.set(xMin, yMax, zMax);
		v.transform(m);
		addPoint(v);
		v.set(xMax, yMin, zMin);
		v.transform(m);
		addPoint(v);
		v.set(xMax, yMin, zMax);
		v.transform(m);
		addPoint(v);
		v.set(xMax, yMax, zMin);
		v.transform(m);
		addPoint(v);
		v.set(xMax, yMax, zMax);
		v.transform(m);
		addPoint(v);
	}
	
	public inline function collide( b : Bounds ) {
		return !(xMin > b.xMax || yMin > b.yMax || zMin > b.zMax || xMax < b.xMin || yMax < b.yMin || zMax < b.zMin);
	}
	
	public inline function include( p : Point ) {
		return p.x >= xMin && p.x < xMax && p.y >= yMin && p.y < yMax && p.z >= zMin && p.z < zMax;
	}
	
	public inline function add( b : Bounds ) {
		if( b.xMin < xMin ) xMin = b.xMin;
		if( b.xMax > xMax ) xMax = b.xMax;
		if( b.yMin < yMin ) yMin = b.yMin;
		if( b.yMax > yMax ) yMax = b.yMax;
		if( b.zMin < zMin ) zMin = b.zMin;
		if( b.zMax > zMax ) zMax = b.zMax;
	}

	public inline function addPoint( p : Point ) {
		if( p.x < xMin ) xMin = p.x;
		if( p.x > xMax ) xMax = p.x;
		if( p.y < yMin ) yMin = p.y;
		if( p.y > yMax ) yMax = p.y;
		if( p.z < zMin ) zMin = p.z;
		if( p.z > zMax ) zMax = p.z;
	}

	public inline function addPos( x : Float, y : Float, z : Float ) {
		if( x < xMin ) xMin = x;
		if( x > xMax ) xMax = x;
		if( y < yMin ) yMin = y;
		if( y > yMax ) yMax = y;
		if( z < zMin ) zMin = z;
		if( z > zMax ) zMax = z;
	}
	
	public function intersection( a : Bounds, b : Bounds ) {
		var xMin = Math.max(a.xMin, b.xMin);
		var yMin = Math.max(a.yMin, b.yMin);
		var zMin = Math.max(a.zMin, b.zMin);
		var xMax = Math.max(a.xMax, b.xMax);
		var yMax = Math.max(a.yMax, b.yMax);
		var zMax = Math.max(a.zMax, b.zMax);
		this.xMin = xMin;
		this.xMax = xMax;
		this.yMin = yMin;
		this.yMax = yMax;
		this.zMin = zMin;
		this.zMax = zMax;
	}
	
	public inline function offset( dx : Float, dy : Float, dz : Float ) {
		xMin += dx;
		xMax += dx;
		yMin += dy;
		yMax += dy;
		zMin += dz;
		zMax += dz;
	}
	
	public inline function setMin( p : Point ) {
		xMin = p.x;
		yMin = p.y;
		zMin = p.z;
	}

	public inline function setMax( p : Point ) {
		xMax = p.x;
		yMax = p.y;
		zMax = p.z;
	}
	
	public function load( b : Bounds ) {
		xMin = b.xMin;
		xMax = b.xMax;
		yMin = b.yMin;
		yMax = b.yMax;
		zMin = b.zMin;
		zMax = b.zMax;
	}
	
	public function scaleCenter( v : Float ) {
		var dx = (xMax - xMin) * 0.5 * v;
		var dy = (yMax - yMin) * 0.5 * v;
		var dz = (zMax - zMin) * 0.5 * v;
		var mx = (xMax + xMin) * 0.5;
		var my = (yMax + yMin) * 0.5;
		var mz = (zMax + zMin) * 0.5;
		xMin = mx - dx * v;
		yMin = my - dy * v;
		zMin = mz - dz * v;
		xMax = mx + dx * v;
		yMax = my + dy * v;
		zMax = mz + dz * v;
	}
	
	public inline function getMin() {
		return new Point(xMin, yMin, zMin);
	}
	
	public inline function getCenter() {
		return new Point((xMin + xMax) * 0.5, (yMin + yMax) * 0.5, (zMin + zMax) * 0.5);
	}
	
	public inline function getCenterX() return (xMin + xMax) * 0.5;
	public inline function getCenterY() return (yMin + yMax) * 0.5;
	public inline function getCenterZ() return (zMin + zMax) * 0.5;

	public inline function getSize() {
		return new Point(xMax - xMin, yMax - yMin, zMax - zMin);
	}
	
	public inline function getMax() {
		return new Point(xMax, yMax, zMax);
	}
	
	/**
	 * Reset the bounds to nil
	 */
	public inline function empty() : Void {
		xMin = 1e20;
		xMax = -1e20;
		yMin = 1e20;
		yMax = -1e20;
		zMin = 1e20;
		zMax = -1e20;
	}

	/**
	 * Reset the bounds to very huge
	 */
	public inline function all() : Void {
		xMin = -1e20;
		xMax = 1e20;
		yMin = -1e20;
		yMax = 1e20;
		zMin = -1e20;
		zMax = 1e20;
	}
	
	public inline function clone() {
		var b = new Bounds();
		b.xMin = xMin;
		b.xMax = xMax;
		b.yMin = yMin;
		b.yMax = yMax;
		b.zMin = zMin;
		b.zMax = zMax;
		return b;
	}
	
	public function toString() {
		return "{" + getMin() + "," + getMax() + "}";
	}
	
	public static inline function fromPoints( min : Point, max : Point ) {
		var b = new Bounds();
		b.setMin(min);
		b.setMax(max);
		return b;
	}
	
}