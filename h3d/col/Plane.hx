package h3d.col;
import hxd.Math;

@:allow(h3d.col)
class Plane {
	
	// Place equation :  nx.X + ny.Y + nz.Z - d = 0
	var nx 	: hxd.Float32;
	var ny 	: hxd.Float32;
	var nz 	: hxd.Float32;
	var d 	: hxd.Float32;
	
	inline function new(nx, ny, nz, d) {
		this.nx = nx;
		this.ny = ny;
		this.nz = nz;
		this.d = d;
	}
	
	/**
		Returns the plan normal
	**/
	public inline function getNormal() {
		return new Point(nx, ny, nz);
	}
	
	public inline function getNormalDistance() {
		return d;
	}
	
	/**
		Normalize the plan, so we can use distance().
	**/
	public inline function normalize() {
		var len = Math.invSqrt(nx * nx + ny * ny + nz * nz);
		nx *= len;
		ny *= len;
		nz *= len;
		d *= len;
	}
	
	public function toString() {
		return "{" + getNormal()+","+ d + "}";
	}
	
	/**
		Returns the signed distance between a point an the plane. This requires the plan to be normalized. If the distance is negative it means that we are "under" the plan.
	**/
	public inline function distance( p : Point ) {
		return nx * p.x + ny * p.y + nz * p.z - d;
	}
	
	public inline function side( p : Point ) {
		return distance(p) >= 0;
	}
	
	public inline function project( p : Point ) : Point {
		var d = distance(p);
		return new Point(p.x - d * nx, p.y - d * ny, p.z - d * nz);
	}

	public inline function projectTo( p : Point, out : Point ) {
		var d = distance(p);
		out.x = p.x - d * nx;
		out.y = p.y - d * ny;
		out.z = p.z - d * nz;
	}
	
	public static inline function fromPoints( p0 : Point, p1 : Point, p2 : Point ) {
		var d1 = p1.sub(p0);
		var d2 = p2.sub(p0);
		var n = d1.cross(d2);
		return new Plane(n.x,n.y,n.z,n.dot(p0));
	}
	
	public static inline function fromNormalPoint( n : Point, p : Point ) {
		return new Plane(n.x,n.y,n.z,n.dot(p));
	}
	
	public static inline function X(v:Float) {
		return new Plane( 1, 0, 0, v );
	}
	
	public static inline function Y(v:Float) {
		return new Plane( 0, 1, 0, v );
	}

	public static inline function Z(v:Float) {
		return new Plane( 0, 0, 1, v );
	}
	
}