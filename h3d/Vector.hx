package h3d;
import hxd.Float32;
using hxd.Math;

/**
	A 4 floats vector. Everytime a Vector is returned, it means a copy is created.
**/
class Vector {

	public var x : hxd.Float32;
	public var y : hxd.Float32;
	public var z : hxd.Float32;
	public var w : hxd.Float32;

	public inline function new( x = 0., y = 0., z = 0., w = 1. ) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public inline function distance( v : Vector ) {
		return Math.sqrt(distanceSq(v));
	}
	
	public inline function dist( v : Vector ) return distance(v);
	public inline function dist2( v : Vector ) return distanceSq(v);

	public inline function distanceSq( v : Vector ) {
		var dx = v.x - x;
		var dy = v.y - y;
		var dz = v.z - z;
		return dx * dx + dy * dy + dz * dz;
	}

	public inline function sub( v : Vector , ?out:Vector) : Vector{
		if ( out == null ) out = new Vector();
		out.set(x - v.x, y - v.y, z - v.z, w - v.w);
		return out;
	}

	public inline function add( v : Vector , ?out:Vector) : Vector {
		if ( out == null ) out = new Vector();
		out.set(x + v.x, y + v.y, z + v.z, w + v.w);
		return out;
	}
	
	public inline function add3( ax:hxd.Float32,ay:hxd.Float32,az:hxd.Float32, ?out:Vector) : Vector {
		if ( out == null ) out = new Vector();
		out.set(x + ax, y + ay, z + az);
		return out;
	}
	
	public inline function incr( v : Vector ) : Void {
		x += v.x; y += v.y;
		z += v.z; w += v.w;
	}
	
	public inline function incr3( vx,vy,vz ) {
		x += vx; 
		y += vy;
		z += vz;
	}
	
	public inline function decr( v : Vector ) {
		x -= v.x; y -= v.y;
		z -= v.z; w -= v.w;
	}
	
	public inline function decr3( vx : hxd.Float32,vy: hxd.Float32,vz: hxd.Float32 ) {
		x -= vx;
		y -= vy;
		z -= vz;
	}

	// note : cross product is left-handed
	public inline function cross( v : Vector, ?out : Vector ) {
		var res = out == null? new h3d.Vector() : out;
		res.set(y * v.z - z * v.y, z * v.x - x * v.z,  x * v.y - y * v.x, 1);
		return res;
	}
	
	public inline function reflect( n : Vector ) {
		var k = 2 * this.dot3(n);
		return new Vector(x - k * n.x, y - k * n.y, z - k * n.z, 1);
	}

	public inline function dot3( v : Vector ) {
		return x * v.x + y * v.y + z * v.z;
	}

	public inline function dot4( v : Vector ) {
		return x * v.x + y * v.y + z * v.z + w * v.w;
	}
	
	public inline function mul3( v : Vector ) {
		return new h3d.Vector( x * v.x, y * v.y, z * v.z);
	}
	
	public inline function mul4( v : Vector ) {
		return new h3d.Vector( x * v.x, y * v.y, z * v.z);
	}
	
	public inline function mulScalar3( s : Float) : Vector {
		return new h3d.Vector(x * s,y * s, z * s);
	}
	
	public inline function mulScalar4( s : Float) : Vector {
		return new h3d.Vector(x * s,y * s, z * s, w*s);
	}

	public inline function lengthSq() {
		return x * x + y * y + z * z;
	}

	public inline function length() {
		return lengthSq().sqrt();
	}

	public function normalize() : Void {
		var k = lengthSq();
		if( k < hxd.Math.EPSILON ) k = 0 else k = k.invSqrt();
		x *= k;
		y *= k;
		z *= k;
	}
	
	public inline function isEqInt4(v:h3d.Vector) {
		return 	Math.round(v.x) == Math.round(x)
		&&		Math.round(v.y) == Math.round(y)
		&&		Math.round(v.z) == Math.round(z)
		&&		Math.round(v.w) == Math.round(w);
	}
	
	public inline function getNormalized() {
		var k = lengthSq();
		if( k < hxd.Math.EPSILON ) k = 0 else k = k.invSqrt();
		return new Vector(x * k, y * k, z * k);
	}
	
	public inline function dir(v:h3d.Vector,?out:Vector) {
		var r = out==null?new h3d.Vector():out;
		r.load(v);
		r.decr( this );
		r.normalize();
		return r;
	}

	public inline 
	function set(x:hxd.Float32,y:hxd.Float32,z:hxd.Float32,w:hxd.Float32=1.) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public inline function splat3(v:hxd.Float32) {
		this.x = v;
		this.y = v;
		this.z = v;
	}
	
	public inline function splat4(v:hxd.Float32) {
		this.x = v;
		this.y = v;
		this.z = v;
		this.w = v;
	}
	
	public inline function load(v : Vector) {
		this.x = v.x;
		this.y = v.y;
		this.z = v.z;
		this.w = v.w;
	}
	
	public inline function mad( add:h3d.Vector,mul: hxd.Float32 ) : Void {
		x += add.x*mul;
		y += add.y*mul;
		z += add.z*mul;
	}
	
	public inline function mad3( add:h3d.Vector,mul:Vector ) : Void {
		x += add.x*mul.x;
		y += add.y*mul.y;
		z += add.z*mul.z;
	}
	

	public inline function scale3( f : hxd.Float32 ) : Void {
		x *= f;
		y *= f;
		z *= f;
	}
	
	public inline function scale4( f : hxd.Float32 ) : Void {
		x *= f;
		y *= f;
		z *= f;
		w *= f;
	}
	
	public inline function invert() : Void  {
		x = -x;
		y = -y;
		z = -z;
		w = -w;
	}
	
	public inline function project( m : Matrix ) {
		var px = x * m._11 + y * m._21 + z * m._31 + w * m._41;
		var py = x * m._12 + y * m._22 + z * m._32 + w * m._42;
		var pz = x * m._13 + y * m._23 + z * m._33 + w * m._43;
		var iw = 1 / (x * m._14 + y * m._24 + z * m._34 + w * m._44);
		x = px * iw;
		y = py * iw;
		z = pz * iw;
		w = 1;
	}
	
	public inline function lerp( v1 : Vector, v2 : Vector, k : hxd.Float32 ) {
		var x = hxd.Math.lerpf(v1.x, v2.x, k);
		var y = hxd.Math.lerpf(v1.y, v2.y, k);
		var z = hxd.Math.lerpf(v1.z, v2.z, k);
		var w = hxd.Math.lerpf(v1.w, v2.w, k);
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public inline function lerp3( v1 : Vector, v2 : Vector, k : hxd.Float32 ) {
		var x = hxd.Math.lerpf(v1.x, v2.x, k);
		var y = hxd.Math.lerpf(v1.y, v2.y, k);
		var z = hxd.Math.lerpf(v1.z, v2.z, k);
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	@:noDebug
	public inline function transform3x4( m : Matrix ) {
		var px = x * m._11 + y * m._21 + z * m._31 + w * m._41;
		var py = x * m._12 + y * m._22 + z * m._32 + w * m._42;
		var pz = x * m._13 + y * m._23 + z * m._33 + w * m._43;
		x = px;
		y = py;
		z = pz;
	}

	@:noDebug
	public inline function transformTRS( m : Matrix ) {
		var px = x * m._11 + y * m._21 + z * m._31 + m._41;
		var py = x * m._12 + y * m._22 + z * m._32 + m._42;
		var pz = x * m._13 + y * m._23 + z * m._33 + m._43;
		x = px;
		y = py;
		z = pz;
	}

	@:noDebug
	public inline function transform3x3( m : Matrix ) {
		var px = x * m._11 + y * m._21 + z * m._31;
		var py = x * m._12 + y * m._22 + z * m._32;
		var pz = x * m._13 + y * m._23 + z * m._33;
		x = px;
		y = py;
		z = pz;
	}
	
	@:noDebug
	public inline function transform( m : Matrix ) {
		var px = x * m._11 + y * m._21 + z * m._31 + w * m._41;
		var py = x * m._12 + y * m._22 + z * m._32 + w * m._42;
		var pz = x * m._13 + y * m._23 + z * m._33 + w * m._43;
		var pw = x * m._14 + y * m._24 + z * m._34 + w * m._44;
		x = px;
		y = py;
		z = pz;
		w = pw;
	}

	public inline function zero() {
		x = y = z = w = 0.0;
	}
	
	public inline function isZero3() {
		return (x==y && y==z  && z == 0.0);
	}
	
	public inline function one() {
		x = y = z = w = 1.0;
	}
	
	public inline function toPoint() {
		return new h3d.col.Point(x, y, z);
	}
	
	public inline function clone() : h3d.Vector {
		return new Vector(x,y,z,w);
	}

	public function toString() {
		return '{${x.fmt()},${y.fmt()},${z.fmt()},${w.fmt()}}';
	}
	
	/// ----- COLOR FUNCTIONS

	public var r(get, set) : Float;
	public var g(get, set) : Float;
	public var b(get, set) : Float;
	public var a(get, set) : Float;

	inline function get_r() return x;
	inline function get_g() return y;
	inline function get_b() return z;
	inline function get_a() return w;
	inline function set_r(v) return x = v;
	inline function set_g(v) return y = v;
	inline function set_b(v) return z = v;
	inline function set_a(v) return w = v;

	///32 bit color set with alpha inclusion
	public inline function setColor( c : Int ) {
		var s = 1.0 / 255;
		r = ((c >> 16) & 0xFF) * s;
		g = ((c >> 8) & 0xFF) * s;
		b = (c & 0xFF) * s;
		a = (c >>> 24) * s;
	}
	
	///32 bit color set with alpha exclusion
	public inline function setColorAlpha( c : Int,f:Float ) {
		var s = 1.0 / 255;
		r = ((c >> 16) & 0xFF) * s;
		g = ((c >> 8) & 0xFF) * s;
		b = (c & 0xFF) * s;
		a = f;
		return this;
	}

	public inline function toColor() : Int{
		return (Std.int(a.clamp() * 255 + 0.499) << 24) | (Std.int(r.clamp() * 255 + 0.499) << 16) | (Std.int(g.clamp() * 255 + 0.499) << 8) | Std.int(b.clamp() * 255 + 0.499);
	}

	public static inline function fromColor( c : Int, scale : Float = 1.0 ) {
		var s = scale / 255;
		return new Vector(((c>>16)&0xFF)*s,((c>>8)&0xFF)*s,(c&0xFF)*s,(c >>> 24)*s);
	}
	
	public static inline function fromColorAlpha( c : Int, alpha : Float = 1.0 ) {
		var s = 1.0 / 255;
		return new Vector(((c>>16)&0xFF)*s,((c>>8)&0xFF)*s,(c&0xFF)*s,alpha);
	}
	
	public static var ONE = new h3d.Vector(1.0, 1.0, 1.0, 1.0);
	public static var ZERO = new h3d.Vector(0.0,0.0,0.0,0.0);

	public inline function rightHand() {
		var px = x; var py = y;
		x = py;
		y = -px;
	}
	
	public inline function toRightHand() {
		var l = clone();
		var px = l.x; var py = l.y;
		l.x = py;
		l.y = -px;
		return l;
	}
	
	public inline function leftHand() {
		var px = x; var py = y;
		x = -py;
		y = px;
	}

	public inline function setRandom() {
		var z = Math.random() * 2.0 - 1.0;
		var a = Math.random() * 2.0 * Math.PI;
		var r = Math.sqrt( 1.0 - z * z );
		var x = r * Math.cos(a);
		var y = r * Math.sin(a);
		set(x, y, z);
	}
	
	/**
	 * @return a quasi well distributed vector on the sphere's surface
	 */
	public static inline function random( ?out : h3d.Vector ) {
		var v = out == null?new Vector():out;
		var z = Math.random() * 2.0 - 1.0;
		var a = Math.random() * 2.0 * Math.PI;
		var r = Math.sqrt( 1.0 - z * z );
		var x = r * Math.cos(a);
		var y = r * Math.sin(a);
		v.set(x, y, z);
		return v;
	}
	
	public function rotateQuat( q : Quat ) {
		var m = hxd.impl.Tmp.getMatrix();
		
		q.saveToMatrix(m);
		transform3x3(m);
		
		hxd.impl.Tmp.saveMatrix(m);
	}
}