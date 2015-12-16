package hxd;

class Timer {

	public static function wantedFPS() {
		return flash.Lib.current.stage.frameRate;
	}
	
	public static var maxDeltaTime = 0.5;
	public static var oldTime = haxe.Timer.stamp();
	public static var tmod_factor = 0.95;
	public static var calc_tmod : Float = 1;
	public static var tmod : Float = 1.0;
	public static var deltaT : Float = 1;
	public static var rdeltaT : Float = 1;
	static var frameCount = 0;

	public inline static function update() {
		frameCount++;
		var newTime = haxe.Timer.stamp();
		rdeltaT = deltaT = newTime - oldTime;
		if ( deltaT == 0.0 ) rdeltaT = deltaT = hxd.Math.EPSILON;
		
		oldTime = newTime;
		if( deltaT < maxDeltaTime )
			calc_tmod = calc_tmod * tmod_factor + (1 - tmod_factor) * deltaT * wantedFPS();
		else
			deltaT = 1 / wantedFPS();
		tmod = calc_tmod;
	}

	public inline static function fps() : Float {
		return wantedFPS()/tmod ;
	}
	
	public static function skip() {
		oldTime = haxe.Timer.stamp();
	}

}
