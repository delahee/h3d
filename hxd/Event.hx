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
	public var destroyed 	= true;
	
	public var nbRef 		= 0;
	
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
	
	public function reset(k, x = 0., y = 0.) {
		destroyed = false;
		kind = k;
		this.relX = x;
		this.relY = y;
		propagate = false;
		cancel = false;
		button = 0;
		touchId = 0;
		keyCode = 0;
		charCode = 0;
		wheelDelta = 0;
		duration = 0;
	}
	
	public static var pool : hxd.Stack<Event> = new hxd.Stack();
	
	public static function alloc(k : EventKind,x=0.0,y=0.0){
		var e : hxd.Event = null;
		e = pool.pop();
		if ( e == null ) 
			e = new hxd.Event( k, x, y);
		e.reset(k,x,y);
		return e;
	}
	
	public static function free(e:hxd.Event){
		e.destroyed = true;
		e.reset(ESimulated,-1,-1);
		pool.push(e);
	}
	
	public function tryFree(){
		if (nbRef == 0 ){
			free(this);
		}
	}
}