package hxd;

class Signal {
	var signals:Array<Void->Void> = [];
	var signalsOnce:Array<Void->Void> = [];
	
	public var isTriggering = false; 
	public inline function add(f:Void->Void) 		signals.push( f );
	public inline function addOnce(f:Void->Void) 	signalsOnce.push( f );
	public inline function new() {}
	public function trigger() {
		if ( isTriggering ) return;//avoid critical blow
		
		isTriggering = true;
		
		if( signals.length > 0 )
			for (s in signals) 
				if(s!=null)
					s();
		
		if( signalsOnce.length > 0 ){
			for (s in signalsOnce) 
				if(s!=null)
					s();
			signalsOnce=[];
		}
		isTriggering = false;
	}
	
	public inline function remove(f) {
		signals.remove(f);
		signalsOnce.remove(f);
	}
	
	public inline function clear() purge();
	public inline function purge() {
		dispose();
	}
	
	public inline function dispose() {
		signals=[];
		signalsOnce=[];
	}
	
	public inline function getHandlerCount() return signals.length + signalsOnce.length;
}