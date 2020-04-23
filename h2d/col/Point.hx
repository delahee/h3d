package h2d.col;
import hxd.Math;

@:structInit
class Point {
	
	public var x : hxd.Float32;
	public var y : hxd.Float32;
	
	public inline function new(x = 0., y = 0.) {
		this.x = x;
		this.y = y;
	}
	
	public inline function set(x = 0., y = 0.) {
		this.x = x;
		this.y = y;
	}
	
	public inline function zero(){
		x = y = 0.0;
	}
	
	public inline function load(v:h2d.Vector){
		x = v.x;
		y = v.y;
	}
	
	public inline function clone() {
		return new Point(x,y);
	}
	
	public inline function distanceSq( p : Point ) {
		var dx = x - p.x;
		var dy = y - p.y;
		return dx * dx + dy * dy;
	}
	
	public inline function distanceSqXY( px:Float, py:Float ) {
		var dx = x - px;
		var dy = y - py;
		return dx * dx + dy * dy;
	}
	
	public inline function distance( p : Point ) {
		return Math.sqrt(distanceSq(p));
	}
	
	public inline function distanceXY( px:Float, py:Float ) {
		return Math.sqrt( distanceSqXY( px,py));
	}
	
	public function toString() {
		return "{" + Math.fmt(x) + "," + Math.fmt(y) + "}";
	}
		
	public inline function sub( p : Point ) {
		return new Point(x - p.x, y - p.y);
	}

	public inline function add( p : Point ) {
		return new Point(x + p.x, y + p.y);
	}
	
	public inline function incr( p : Point ) {
		x += p.x;
		y += p.y;
	}
	
	public inline function decr( p : Point ) {
		x -= p.x;
		y -= p.y;
	}
	
	public inline function incr2( px : hxd.Float32,py : hxd.Float32 ) {
		x += px;
		y += py;
	}
	
	public inline function decr2( px: hxd.Float32,py : hxd.Float32 ) {
		x -= px;
		y -= py;
	}
	
	public inline function add2( px:Float,py:Float ) {
		return new Point(x + px, y + py);
	}

	public inline function dot( p : Point ) {
		return x * p.x + y * p.y;
	}

	public inline function lengthSq() {
		return x * x + y * y;
	}

	public inline function length() {
		return Math.sqrt(lengthSq());
	}
	
	public inline function rotate( a: Float ) {
		var bx = x;
		var by = y;
		
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		
		x = ca * bx + sa *by;
		y = - sa * bx + ca*by;
	}

	public function normalize() {
		var k = lengthSq();
		if( k < Math.EPSILON ) k = 0 else k = Math.invSqrt(k);
		x *= k;
		y *= k;
	}

	public inline function scale( f : hxd.Float32 ) {
		x *= f;
		y *= f;
	}
	
	public function toVector() {
		return new h3d.Vector( x, y, 0, 1.0);
	}

	public inline function mulScalar( s : Float) : Point {
		return new Point(x * s,y * s);
	}
	
	//same but in place
	public inline function mulScalarIP( s : Float) : Point {
		x *= s;
		y *= s;
		return this;
	}
	
	public inline function divScalar( s : Float) : Point {
		var d = 1.0 / s;
		return new Point(x * d,y * d);
	}
	
	public static var ZERO = new Point(0, 0);
}