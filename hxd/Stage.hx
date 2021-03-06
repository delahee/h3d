package hxd;

class Stage {
	
	#if (flash || openfl)
	var stage : flash.display.Stage;
	var fsDelayed : Bool;
	#end
	var resizeEvents : List<Void -> Void>;
	var eventTargets : List<Event -> Void>;
	
	public var width(get, null) 	: Float;
	public var height(get, null) 	: Float;
	public var mouseX(get, null) 	: Float;
	public var mouseY(get, null) 	: Float;
	public var clicked 				: Bool = false;
	
	function new() {
		
		if ( System.debugLevel >= 2) trace("Stage:new()");
		
		eventTargets = new List();
		resizeEvents = new List();
		
		#if (flash || openfl)
		stage = flash.Lib.current.stage;
		stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		stage.addEventListener(flash.events.Event.RESIZE, onResize);
		
		if( hxd.System.isTouch ) {
			flash.ui.Multitouch.inputMode = flash.ui.MultitouchInputMode.TOUCH_POINT;
			stage.addEventListener(flash.events.TouchEvent.TOUCH_BEGIN, onTouchDown);
			stage.addEventListener(flash.events.TouchEvent.TOUCH_MOVE, onTouchMove);
			stage.addEventListener(flash.events.TouchEvent.TOUCH_END, onTouchUp);
		} else {
			stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(flash.events.MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			stage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(flash.events.KeyboardEvent.KEY_UP, onKeyUp);
			
			//#if !openfl
			stage.addEventListener(flash.events.MouseEvent.RIGHT_MOUSE_DOWN, onRMouseDown);
			stage.addEventListener(flash.events.MouseEvent.RIGHT_MOUSE_UP, onRMouseUp);
			//#end
		}
		#elseif js
		js.Browser.window.addEventListener("mousedown", onMouseDown);
		js.Browser.window.addEventListener("mousemove", onMouseMove);
		js.Browser.window.addEventListener("mouseup", onMouseUp);
		js.Browser.window.addEventListener("mousewheel", onMouseWheel);
		js.Browser.window.addEventListener("keydown", onKeyDown);
		js.Browser.window.addEventListener("keyup", onKeyUp);
		js.Browser.window.addEventListener("resize", onResize);
		#end
	}
	
	public function event( e : hxd.Event ) {
		for ( et in eventTargets ){
			e.nbRef++;
			et(e);
		}
	}
	
	public function addEventTarget(et) {
		eventTargets.add(et);
	}

	public function removeEventTarget(et) {
		eventTargets.remove(et);
	}
	
	public function addResizeEvent( f : Void -> Void ) {
		resizeEvents.push(f);
	}

	public function removeResizeEvent( f : Void -> Void ) {
		resizeEvents.remove(f);
	}
	
	public function getFrameRate() : Float {
		#if (flash || openfl)
		return stage.frameRate;
		#else
		return 60.;
		#end
	}

	public function setFullScreen( v : Bool ) {
		#if flash
		var isAir = flash.system.Capabilities.playerType == "Desktop";
		var state = v ? (isAir ? flash.display.StageDisplayState.FULL_SCREEN_INTERACTIVE : flash.display.StageDisplayState.FULL_SCREEN) : flash.display.StageDisplayState.NORMAL;
		if( stage.displayState != state ) {
			var t = flash.Lib.getTimer();
			// delay first fullsrceen toggle on OSX/Air to prevent the command window to spawn over
			if( v && isAir && t < 5000 && !fsDelayed && flash.system.Capabilities.os.indexOf("Mac") != -1 ) {
				fsDelayed = true;
				haxe.Timer.delay(function() this.setFullScreen(v), 1000);
				return;
			}
			stage.displayState = state;
		}
		#else
		#end
	}
	
	static var inst = null;
	public static function getInstance() {
		if( inst == null ) inst = new Stage();
		return inst;
	}
	
#if (flash || openfl)

	inline function get_mouseX() {
		return stage.mouseX;
	}

	inline function get_mouseY() {
		return stage.mouseY;
	}

	inline function get_width() {
		return stage.stageWidth;
	}

	inline function get_height() {
		return stage.stageHeight;
	}
	
	function onResize(_) {
		for( e in resizeEvents )
			e();
	}

	function onMouseDown(e:Dynamic) {
		event( hxd.Event.alloc(EPush, mouseX, mouseY));
		clicked=true;
	}
	
	function onRMouseDown(e:Dynamic) {
		var e = hxd.Event.alloc(EPush, mouseX, mouseY);
		e.button = 1;
		event(e);
	}
	
	function onMouseUp(e:Dynamic) {
		event( hxd.Event.alloc(ERelease, mouseX, mouseY));
		clicked=false;
	}

	function onRMouseUp(e:Dynamic) {
		var e = hxd.Event.alloc(ERelease, mouseX, mouseY);
		e.button = 1;
		event(e);
	}
	
	function onMouseMove(e:Dynamic) {
		event( hxd.Event.alloc(EMove, mouseX, mouseY));
	}
	
	function onMouseWheel(e:flash.events.MouseEvent) {
		var ev = hxd.Event.alloc(EWheel, mouseX, mouseY);
		ev.wheelDelta = -e.delta / 3.0;
		event(ev);
	}
	
	function onKeyUp(e:flash.events.KeyboardEvent) {
		var ev = hxd.Event.alloc(EKeyUp);
		ev.keyCode = e.keyCode;
		ev.charCode = getCharCode(e);
		event(ev);
	}

	function onKeyDown(e:flash.events.KeyboardEvent) {
		var ev = hxd.Event.alloc(EKeyDown);
		ev.keyCode = e.keyCode;
		ev.charCode = getCharCode(e);
		event(ev);
	}
	
	static var lang :Null<String> = null;
	function getCharCode( e : flash.events.KeyboardEvent ) {
		#if openfl
			if ( lang == null) lang = flash.system.Capabilities.language;
			//var character:String = String.fromCharCode(e.charCode);
			//trace( "-> key segment: kc:" + e.keyCode+" cc:" + e.charCode+" char:" + character + " " + e.commandKey + " " + e.controlKey + " " + e.keyLocation );
			var charCode = e.charCode;
			charCode = switch( lang ) {
				default:
					e.charCode;
				case "fr":
					//trace("french translation");
					switch(e.keyCode){
						default: e.charCode;
						//TODO finish
						case 49: if( e.altKey ) 0 				else if( e.shiftKey ) '1'.code else '&'.code;
						case 50: if( e.altKey ) '~'.code 		else if( e.shiftKey ) '2'.code else 'é'.code;
						case 51: if( e.altKey ) '#'.code 		else if( e.shiftKey ) '3'.code else '"'.code;
						case 52: if( e.altKey ) '{'.code 		else if( e.shiftKey ) '4'.code else '\''.code;
						case 53: if( e.altKey ) '['.code 		else if( e.shiftKey ) '5'.code else '('.code;
						case 54: if( e.altKey ) '|'.code 		else if( e.shiftKey ) '6'.code else '-'.code;
						case 55: if( e.altKey ) '`'.code 		else if( e.shiftKey ) '7'.code else 'è'.code;
						case 56: if( e.altKey ) '\\'.code 		else if( e.shiftKey ) '8'.code else '_'.code;
						case 57: if( e.altKey ) '^'.code 		else if( e.shiftKey ) '9'.code else 'ç'.code;
						case 48:	if ( e.altKey ) '@'.code else if ( e.shiftKey ) '0'.code else 'à'.code;//9
						case 109: 	'-'.code;
						case 111: 	'/'.code;
					}
			}
			//var character:String = String.fromCharCode(charCode);
			//trace( "<- key segment: kc:"+e.keyCode+" cc:"+charCode+" char:"+character);
			return charCode;
		#else
		// disable some invalid charcodes
		if( e.keyCode == 27 ) e.charCode = 0;
		// Flash charCode are not valid, they assume an english keyboard. Let's do some manual translation here (to complete with command keyboards)
		if ( lang == null) lang = flash.system.Capabilities.language;
		switch( lang ) {
		case "fr":
			return switch( e.keyCode ) {
			case 49: if( e.altKey ) 0 			else if( e.shiftKey ) '1'.code else '&'.code;
			case 50: if( e.altKey ) '~'.code 	else if( e.shiftKey ) '2'.code else e.charCode;
			case 51: if( e.altKey ) '#'.code 	else if( e.shiftKey ) '3'.code else e.charCode;
			case 52: if( e.altKey ) '{'.code 	else if( e.shiftKey ) '4'.code else e.charCode;
			case 53: if( e.altKey ) '['.code 	else if( e.shiftKey ) '5'.code else e.charCode;
			case 54: if( e.altKey ) '|'.code 	else if( e.shiftKey ) '6'.code else e.charCode;
			case 55: if( e.altKey ) '`'.code 	else if( e.shiftKey ) '7'.code else e.charCode;
			case 56: if( e.altKey ) '\\'.code 	else if( e.shiftKey ) '8'.code else e.charCode;
			case 57: if( e.altKey ) '^'.code 	else if( e.shiftKey ) '9'.code else e.charCode;
			case 48: if( e.altKey ) '@'.code 	else if( e.shiftKey ) '0'.code else e.charCode;
			case 219: if( e.altKey ) ']'.code 	else if( e.shiftKey ) '°'.code else e.charCode;
			case 187: if( e.altKey ) '}'.code 	else if( e.shiftKey ) '+'.code else e.charCode;
			case 188: if( e.altKey ) 0 else if( e.shiftKey ) '?'.code else e.charCode;
			case 190: if( e.altKey ) 0 else if( e.shiftKey ) '.'.code else e.charCode;
			case 191: if( e.altKey ) 0 else if( e.shiftKey ) '/'.code else e.charCode;
			case 223: if( e.altKey ) 0 else if( e.shiftKey ) '§'.code else e.charCode;
			case 192: if( e.altKey ) 0 else if( e.shiftKey ) '%'.code else e.charCode;
			case 220: if( e.altKey ) 0 else if( e.shiftKey ) 'µ'.code else e.charCode;
			case 221: if( e.altKey ) 0 else if( e.shiftKey ) '¨'.code else '^'.code;
			case 186: if( e.altKey ) '¤'.code else if( e.shiftKey ) '£'.code else e.charCode;
			default:
				e.charCode;
			}
		default:
			return e.charCode;
		}
		#end
	}
	
	function onTouchDown(e:flash.events.TouchEvent) {
		var ev = hxd.Event.alloc(EPush, e.localX, e.localY);
		ev.touchId = e.touchPointID;
		event(ev);
		clicked=true;
	}

	function onTouchUp(e:flash.events.TouchEvent) {
		var ev = hxd.Event.alloc(ERelease, e.localX, e.localY);
		ev.touchId = e.touchPointID;
		event(ev);
		clicked=false;
	}
	
	function onTouchMove(e:flash.events.TouchEvent) {
		var ev = hxd.Event.alloc(EMove, e.localX, e.localY);
		ev.touchId = e.touchPointID;
		event(ev);
	}
	
#elseif js

	var curMouseX : Float;
	var curMouseY : Float;

	function get_width() {
		return js.Browser.document.width;
	}

	function get_height() {
		return js.Browser.document.height;
	}

	function get_mouseX() {
		return curMouseX;
	}

	function get_mouseY() {
		return curMouseY;
	}

	function onMouseDown(e:js.html.MouseEvent) {
		event( hxd.Event.alloc(EPush, mouseX, mouseY));
		clicked=true;
	}

	function onMouseUp(e:js.html.MouseEvent) {
		event( hxd.Event.alloc(ERelease, mouseX, mouseY));
		clicked=false;
	}
	
	function onMouseMove(e:js.html.MouseEvent) {
		curMouseX = e.clientX;
		curMouseY = e.clientY;
		event( hxd.Event.alloc(EMove, mouseX, mouseY));
	}
	
	function onMouseWheel(e:js.html.MouseEvent) {
		var ev = hxd.Event.alloc(EWheel, mouseX, mouseY);
		ev.wheelDelta = untyped -e.wheelDelta / 30.0;
		event(ev);
	}
	
	function onKeyUp(e:js.html.KeyboardEvent) {
		var ev = hxd.Event.alloc(EKeyUp);
		ev.keyCode = e.keyCode;
		ev.charCode = e.charCode;
		event(ev);
	}

	function onKeyDown(e:js.html.KeyboardEvent) {
		var ev = hxd.Event.alloc(EKeyDown);
		ev.keyCode = e.keyCode;
		ev.charCode = e.charCode;
		event(ev);
	}
	
	function onResize(e) {
		for( r in resizeEvents )
			r();
	}

#else

	function get_mouseX() {
		return 0;
	}

	function get_mouseY() {
		return 0;
	}
	
	function get_width() {
		return 0;
	}

	function get_height() {
		return 0;
	}

#end

#if openfl
	static function openFLBoot(callb) {
		
		System.trace1("ofl boot !");
		// init done with OpenFL ApplicationMain
		if ( flash.Lib.current.stage != null ) {
			callb();
			#if debug
			trace("sytem start cbk ok");
			#end
			return;
		}
		else {
			callb();
			#if debug
			trace("sytem start cbk failed...trying nonetheless ");
			#end
		}
	}
#end

	public static function requestSoftKeyboard(){
		#if (openfl && switch)
		trace("requestSoftKeyboard");
		var str = lime.console.nswitch.Swkbd.SwkbdLib.getKeyboardResult();
		if ( str == null ){
			var stage = hxd.Stage.getInstance();
			var ke = new flash.events.KeyboardEvent("anon",true,false,0,0);
			
			function simKey(code){
				var ev = hxd.Event.alloc(EKeyDown);
				ev.charCode = ev.keyCode = code;
				stage.event(ev);
				
				var ev = hxd.Event.alloc(EKeyUp);
				ev.charCode = ev.keyCode = code;
				stage.event(ev);
			}
			
			haxe.Utf8.iter( str, function(code:Int){
				ke.charCode = ke.keyCode = code;
				simKey(code);
			});
			simKey( '\n'.code );
		}
		#elseif ( openfl )
		trace("dunno what to do..");
		flash.Lib.current.requestSoftKeyboard();
		#else 
		trace("dunno what to do...");
		#end
	}

}