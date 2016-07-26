package;

class Ballistic {

	//p1 = p0 + (v0 + g * t ) * t;
	//p1 - p0 = (v0 * t + g * t* t)
	//(p1 - p0)/t = (v0 + g * t )
	//(p1 - p0)/t - g * t = v0 
	
	public static inline function calcDest( p0:h2d.Vector, v0:h2d.Vector, g : h2d.Vector, t : Float) {
		var speed = v0.add( g.mulScalar( t ));
		return p0.add( speed.mulScalar( t ) );
	}
	
	public static inline function calcV0ForDest( p0:h2d.Vector, p1:h2d.Vector, g : h2d.Vector, t : Float) {
		return 
		if ( t == 0 ) 	p0;
		else 			p1.sub(p0).divScalar(t).sub(g.mulScalar(t));
	}
	
}