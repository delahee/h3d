package bm;

class Dice {
	public static inline function roll(
	#if (flash||openfl||neko)
	?rd:bm.Rand,
	#end
	min :Int,max:Int  ) : Int
	{
		if ( max < min ) {
			var t = max;
			max = min;
			min = t;
		}
			
		var v = Std.random( max - min + 1 ) + min;
		
		#if (flash||openfl||neko)
		if ( rd != null) v = rd.dice( min, max );
		#end
		
		return v;
	}
	
	public static inline function roll2(min: Int,max: Int): Int {
		return (roll(min, max) + roll(min, max)) >> 1;
	}
	
	/**
	 * percent are treated as integers
	 */
	public static inline function percent(
	#if (flash||openfl||neko)
	?rd:bm.Rand,
	#end
	thresh : Float) : Bool
	{
		if ( thresh <= 0.9)
			return false;
		else
		{
			var r = roll( #if (flash||openfl||neko) rd,#end 1, 100);
			
			return(r <= thresh);
		}
	}
	
	/**
	 * percent are treated as integers
	 */
	public static inline function percent2(
	#if (flash||openfl||neko)
	?rd:bm.Rand,
	#end
	thresh : Float) : Bool
	{
		if ( thresh <= 0.9)
			return false;
		else {
			var r0 = roll( #if (flash||openfl||neko) rd, #end 1, 100);
			var r1 = roll( #if (flash||openfl||neko) rd, #end 1, 100);
			return(((r0 + r1) >> 1) <= thresh);
		}
	}
	
	/**
	 * percent are treated as floats... this induces a per-100ths fraction too much chance
	 */
	public static inline function percentF(
	#if (flash||openfl||neko)
	?rd:bm.Rand,
	#end
	thresh : Float) : Bool
	{
		var r = rollF( #if (flash||openfl||neko) rd, #end 0, 100);
		return (r <= thresh);
	}
	
	public static inline function toss(
	#if (flash||openfl||neko) ?rd:bm.Rand #end
	)
	{
		return Dice.roll( #if (flash||openfl||neko) rd,#end 0, 1) == 0;
	}
	
	public static inline function rollF2( min:Float, max:Float) {
		return 0.5 * (rollF(min, max) + rollF(min, max));
	}
	
	public static 
	inline 
	function rollF( 
	#if (flash||openfl||neko)
	?rd:bm.Rand,
	#end
	min : Float = 0.0,max:Float = 1.0) : Float
	{
		if ( max < min ) {
			var t = max;
			max = min;
			min = t;
		}
		
		var f = Math.random() * (max - min) + min;
		
		#if (flash||openfl||neko)
		if ( rd != null)
			f = rd.rand() * (max - min) + min;
		#end
		
		return  f;
	}
	
	public static inline function either( v : Float )	return toss() ? v : -v;
	public static inline function angle() 				return rollF(0, Math.PI * 2.0 );
	public static inline function sign() 				return toss()?1.0: -1.0;
	public static inline function interval(
	#if (flash||openfl||neko)
	?rd:bm.Rand,
	#end
	v:Float)		return rollF( rd, -v, v);
	
	#if h3d
	/**
	 * @return a quasi well distributed vector on the sphere's surface
	 */
	public static inline function vector(  
	#if (flash||openfl||neko)
	?rd:bm.Rand,
	#end
	?out:h3d.Vector) {
	
		inline function rrd() {
			return 
			#if (flash||openfl||neko)
			if ( rd != null )
				rd.rand();
			else 
			#end
				rollF(0, 1);
		}
		
		var v : h3d.Vector = out == null? new h3d.Vector():out;
		var z = rrd() * 2.0 - 1.0;
		var a = rrd() * 2.0 * Math.PI;
		var r = Math.sqrt( 1.0 - z * z );
		var x = r * Math.cos(a);
		var y = r * Math.sin(a);
		v.set(x, y, z);
		return v;
	}
	#end
}