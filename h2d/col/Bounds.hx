package h2d.col;

class Bounds {
	
	public var xMin : Float;
	public var yMin : Float;

	public var xMax : Float;
	public var yMax : Float;
	
	public var x(get, null) : Float;
	public var y(get, null) : Float;
	
	public var width(get,null) : Float;
	public var height(get,null) : Float;
	
	public inline function new() {
		empty();
	}
	
	inline function get_x() 	return xMin;
	inline function get_y() 	return yMin;
	
	inline function get_width() 	return xMax - xMin;
	inline function get_height() 	return yMax - yMin;
	
	public var 		left(get, set) : Float; 	
	inline function get_left() return xMin;
	inline function set_left(v) return xMin = v;
	
	public var		right(get, set) : Float; 	
	inline function get_right() return xMax;
	inline function set_right(v) return xMax = v;
	
	public var		top(get, set) : Float; 	
	inline function get_top() return yMin;
	inline function set_top(v) return yMin = v;
	
	public var		bottom(get, set) : Float; 	
	inline function get_bottom() return yMax;
	inline function set_bottom(v) return yMax=v;
	
	public inline function collides( b : Bounds ) {
		return !(xMin > b.xMax || yMin > b.yMax || xMax < b.xMin || yMax < b.yMin);
	}
	
	public inline function includes( p : Point ) {
		return p.x >= xMin && p.x < xMax && p.y >= yMin && p.y < yMax;
	}
	
	public inline function includes2( px:Float, py:Float) {
		return px >= xMin && px < xMax && py >= yMin && py < yMax;
	}
	
	/**
	 * http://stackoverflow.com/questions/401847/circle-rectangle-collision-detection-intersection
	 */
	public inline function testCircle( px,py ,r) {
		var closestX = hxd.Math.clamp(px, xMin, xMax);
		var closestY = hxd.Math.clamp(py, yMin, yMax);
		
		var distX = px - closestX;
		var distY = py - closestY;
		
		var distSq = distX * distX + distY * distY;
		return distSq < r * r;
	}
	
	public inline function add( b : Bounds ) {
		if( b.xMin < xMin ) xMin = b.xMin;
		if( b.xMax > xMax ) xMax = b.xMax;
		if( b.yMin < yMin ) yMin = b.yMin;
		if( b.yMax > yMax ) yMax = b.yMax;
	}
	
	/**
	 * set the bounding box with 4 floats
	 */
	public inline function add4( x:Float, y:Float, w:Float, h:Float ) {
		var ixMin = x;
		var iyMin = y;
		
		var ixMax = x+w;
		var iyMax = y+h;
		
		if( ixMin < xMin ) xMin = ixMin;
		if( ixMax > xMax ) xMax = ixMax;
		if( iyMin < yMin ) yMin = iyMin;
		if ( iyMax > yMax ) yMax = iyMax;
		return this;
	}

	public inline function addPoint( p : Point ) {
		if( p.x < xMin ) xMin = p.x;
		if( p.x > xMax ) xMax = p.x;
		if( p.y < yMin ) yMin = p.y;
		if ( p.y > yMax ) yMax = p.y;
		return this;
	}
	
	public inline function addPoint2( px:Float,py:Float ) {
		if( px < xMin ) xMin = px;
		if( px > xMax ) xMax = px;
		if( py < yMin ) yMin = py;
		if ( py > yMax ) yMax = py;
		return this;
	}
	
	public inline function setMin( p : Point ) {
		xMin = p.x;
		yMin = p.y;
	}

	public inline function setMax( p : Point ) {
		xMax = p.x;
		yMax = p.y;
	}
	
	public inline function load( b : Bounds ) {
		xMin = b.xMin;
		yMin = b.yMin;
		xMax = b.xMax;
		yMax = b.yMax;
	}
	
	public inline function scaleCenter( v : Float ) {
		var dx = (xMax - xMin) * 0.5 * v;
		var dy = (yMax - yMin) * 0.5 * v;
		var mx = (xMax + xMin) * 0.5;
		var my = (yMax + yMin) * 0.5;
		xMin = mx - dx * v;
		yMin = my - dy * v;
		xMax = mx + dx * v;
		yMax = my + dy * v;
		return this;
	}
	
	public inline function scaleY( v : Float ) {
		var dy = (yMax - yMin) * 0.5 * v;
		var my = (yMax + yMin) * 0.5;
		yMin = my - dy * v;
		yMax = my + dy * v;
		return this;
	}
	
	public inline function scaleX( v : Float ) {
		var dx = (xMax - xMin) * 0.5 * v;
		var mx = (xMax + xMin) * 0.5;
		xMin = mx - dx * v;
		xMax = mx + dx * v;
		return this;
	}
	
	public inline function offset( dx : Float, dy : Float ) {
		xMin += dx;
		xMax += dx;
		yMin += dy;
		yMax += dy;
	}
	
	public inline function getMin() 	return new Point(xMin, yMin);
	public inline function getCenter() 	return new Point((xMin + xMax) * 0.5, (yMin + yMax) * 0.5);
	public inline function getCenterX() return (xMin + xMax) * 0.5;
	public inline function getCenterY() return (yMin + yMax) * 0.5;
	public inline function getSize() 	return new Point(xMax - xMin, yMax - yMin);
	public inline function getMax() 	return new Point(xMax, yMax);
	public inline function isEmpty() 	return xMax <= xMin || yMax <= yMin;
	public inline function empty() {
		xMin = 1e20;
		yMin = 1e20;
		xMax = -1e20;
		yMax = -1e20;
	}
	
	

	public inline function all() {
		xMin = -1e20;
		yMin = -1e20;
		xMax = 1e20;
		yMax = 1e20;
	}
	
	public inline function copy(b) {
		xMin = b.xMin;
		yMin = b.yMin;
		xMax = b.xMax;
		yMax = b.yMax;
		return b;
	}
	
	public inline function clone() {
		var b = new Bounds();
		b.xMin = xMin;
		b.yMin = yMin;
		b.xMax = xMax;
		b.yMax = yMax;
		return b;
	}
	
	/**
	 * @return this
	 */
	public inline function translate(x, y) {
		xMin += x;
		xMax += x;
		
		yMin += y;
		yMax += y;
		return this;
	}
		
	/**
	 * in place transforms
	 */
	public inline function transform( m : h2d.Matrix ) : Bounds {
		
		var p0 = new Point(xMin,yMin);
		var p1 = new Point(xMin,yMax);
		var p2 = new Point(xMax,yMin);
		var p3 = new Point(xMax,yMax);
		
		m.transformPoint2( p0.x, p0.y, p0 );
		m.transformPoint2( p1.x, p1.y, p1 );
		m.transformPoint2( p2.x, p2.y, p2 );
		m.transformPoint2( p3.x, p3.y, p3 );
		 
		setMin(p0); setMax(p0);
		
		addPoint(p1);
		addPoint(p2);
		addPoint(p3);
		
		p0 = null; p1 = null; p2 = null; p3 = null;
		return this;
	}
	
	public function toString() {
		return "{" + getMin() + "," + getMax() + "}";
	}

	public static inline function fromValues( x : Float, y : Float, width : Float, height : Float ) {
		var b = new Bounds();
		b.xMin = x;
		b.yMin = y;
		b.xMax = x + width;
		b.yMax = y + height;
		return b;
	}
	
	public static inline function fromPoints( min : Point, max : Point ) {
		var b = new Bounds();
		b.setMin(min);
		b.setMax(max);
		return b;
	}
	
	public inline function random() : h2d.col.Point {
		return new h2d.col.Point(
			xMin + Math.random() * (xMax - xMin),
			yMin + Math.random() * (yMax - yMin)
		);
	}
	
	public inline function randomX() : Float 		return xMin + Math.random() * (xMax - xMin);
	public inline function randomY() : Float 		return yMin + Math.random() * (yMax - yMin);
	
}