package hxd;

//enum EventKind {
@:enum abstract EventKind(Int) {
	var EPush		= 0;
	var ERelease	= 1;
	var EMove		= 2;
	var EOver		= 3;
	var EOut		= 4;
	var EWheel		= 5;
	var EFocus		= 6;
	var EFocusLost	= 7;
	var EKeyDown	= 8;
	var EKeyUp		= 9;
	var ESimulated	= 10;
}

class Event {

	public var kind 		: EventKind;
	public var relX 		: Float;
	public var relY 		: Float;
	public var propagate 	: Bool;
	public var cancel 		: Bool;
	public var button 		: Int;
	public var touchId 		: Int;
	public var keyCode 		: Int;
	public var charCode 	: Int;
	public var wheelDelta 	: Float;
	public var duration 	: Int = 0;
	
	public inline function new(k,x=0.,y=0.) {
		kind = k;
		this.relX = x;
		this.relY = y;
	}
	
	public function toString() {
		return kind + "[" + Std.int(relX) + "," + Std.int(relY) + "]";
	}
	
	public function clone() {
		var e = new Event(kind);
		
		e.relX 		    = relX 		   	;
		e.relY 		    = relY 		   	;
		e.propagate     = propagate    	;
		e.cancel 		= cancel 		;
		e.button 		= button 		;
		e.touchId 		= touchId 		;
		e.keyCode 		= keyCode 		;
		e.charCode 	    = charCode 	   	;
		e.wheelDelta    = wheelDelta    ;
		e.duration		= duration		;
		
		return e;
	}
}