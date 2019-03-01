package hxd;
import haxe.Log;
import haxe.PosInfos;


enum Cursor {
	Default;
	Button;
	Move;
	TextInput;
	Hide;
}

class System {
	
	public static var width(get,never) : Int;
	public static var height(get,never) : Int;
	public static var isTouch(get,never) : Bool;
	public static var isWindowed(get,never) : Bool;
	public static var lang(get, never) : String;
	
	public static var isAndroid(get, never) : Bool;
	public static var isWindows(get, never) : Bool;
	public static var isLinux(get, never) : Bool;
	public static var isMac(get, never) : Bool;
	public static var isIOS(get, never) : Bool;
	
	public static var screenDPI(get, never) : Float;
	/**
opengl	
	 * 0- no trace
	 * 1- user space traces
	 * 2- engine space traces
	 * 3- engine dev space traces
	 */
	public static var debugLevel = #if debug 0 #else 0 #end;

	
	public static function ensureViewBelow() {
		#if (!flash && (lime < "7.1.1"))
		if( VIEW == null ) {
			VIEW = new openfl.display.OpenGLView();
			VIEW.name = "glView";
			flash.Lib.current.addChildAt(VIEW,0);	
		}
		#end
	}
	
	
	#if flash
	
	static function get_isWindowed() {
		var p = flash.system.Capabilities.playerType;
		return p == "ActiveX" || p == "PlugIn" || p == "StandAlone" || p == "Desktop";
	}

	static function get_isTouch() {
		return flash.system.Capabilities.touchscreenType == flash.system.TouchscreenType.FINGER;
	}

	static function get_width() {
		var Cap = flash.system.Capabilities;
		return isWindowed ? flash.Lib.current.stage.stageWidth : Std.int(Cap.screenResolutionX > Cap.screenResolutionY ? Cap.screenResolutionX : Cap.screenResolutionY);
	}

	static function get_height() {
		var Cap = flash.system.Capabilities;
		return isWindowed ? flash.Lib.current.stage.stageHeight : Std.int(Cap.screenResolutionX > Cap.screenResolutionY ? Cap.screenResolutionY : Cap.screenResolutionX);
	}
	
	static function get_isAndroid() { return flash.system.Capabilities.manufacturer.indexOf('Android') 	!= -1;	}
	static function get_isWindows() { return flash.system.Capabilities.manufacturer.indexOf('Windows') 	!= -1;	}
	static function get_isIOS() 	{ return flash.system.Capabilities.manufacturer.indexOf('iPhone') 	!= -1;	}
	static function get_isMac() 	{ return flash.system.Capabilities.manufacturer.indexOf('Mac') 		!= -1;	}
	static function get_isLinux() 	{ return flash.system.Capabilities.manufacturer.indexOf('Linux') 	!= -1;	}
	static function get_isSwitch() 	{ return false;	}
	
	static function get_screenDPI() return flash.system.Capabilities.screenDPI;
	
	static var loop = null;
	public static function setLoop( update : Void -> Void, ?render: Void->Void ) {
		if( loop != null ) flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, loop);
			
		if( update == null )
			loop = null;
		else {
			loop = function(_) {
				update();
				if( render !=null ) render();
			}
			flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, loop);
		}
	}

	static function isAir() {
		return flash.system.Capabilities.playerType == "Desktop";
	}
	
	public static function exit() {
		if( isAir() ) {
			var d : Dynamic = flash.Lib.current.loaderInfo.applicationDomain.getDefinition("flash.desktop.NativeApplication");
			Reflect.field(Reflect.field(d,"nativeApplication"),"exit")();
		} else
			flash.system.System.exit(0);
	}
	
	public static var setCursor = setNativeCursor;
	public static var currentCursor : Cursor;
	
	public static function isCursorHidden() return currentCursor == Hide;
	public static function setNativeCursor( c : Cursor ) {
		currentCursor = c;
		flash.ui.Mouse.cursor = switch( c ) {
		case Default: "auto";
		case Button: "button";
		case Move: "hand";
		case TextInput: "ibeam";
		case Hide: "auto";
		}
		if( c == Hide ) flash.ui.Mouse.hide() else flash.ui.Mouse.show();
	}
		

	/**
		Returns the device name:
			"PC" for a desktop computer
			Or the android device name
			(will add iPad/iPhone/iPod soon)
	**/
	static var CACHED_NAME = null;
	public static function getDeviceName() {
		if( CACHED_NAME != null )
			return CACHED_NAME;
		var name;
		if( isAndroid && isAir() ) {
			try {
				var f : Dynamic = Type.createInstance(flash.Lib.current.loaderInfo.applicationDomain.getDefinition("flash.filesystem.File"), ["/system/build.prop"]);
				var fs : flash.utils.IDataInput = Type.createInstance(flash.Lib.current.loaderInfo.applicationDomain.getDefinition("flash.filesystem.FileStream"), []);
				Reflect.callMethod(fs, Reflect.field(fs, "open"), [f, "read"]);
				var content = fs.readUTFBytes(fs.bytesAvailable);
				name = StringTools.trim(content.split("ro.product.model=")[1].split("\n")[0]);
			} catch( e : Dynamic ) {
				name = "Android";
			}
		} else
			name = "PC";
		CACHED_NAME = name;
		return name;
	}

	static function get_lang() {
		return flash.system.Capabilities.language;
	}
	
	#elseif js//useless target ?

	static var LOOP = null;
	static var LOOP_INIT = false;
	
	static function loopFunc() {
		var window : Dynamic = js.Browser.window;
		var rqf : Dynamic = window.requestAnimationFrame ||
			window.webkitRequestAnimationFrame ||
			window.mozRequestAnimationFrame;
		rqf(loopFunc);
		if( LOOP != null ) LOOP();
	}
	
	public static function setLoop( f : Void -> Void ) {
		if( !LOOP_INIT ) {
			LOOP_INIT = true;
			loopFunc();
		}
		LOOP = f;
	}

	public static var setCursor = setNativeCursor;
	
	public static function setNativeCursor( c : Cursor ) {
		var canvas = js.Browser.document.getElementById("webgl");
		if( canvas != null ) {
			canvas.style.cursor = switch( c ) {
			case Default: "";
			case Button: "pointer";
			case Move: "move";
			case TextInput: "text";
			case Hide: "none";
			};
		}
	}
	
	static function get_lang() {
		return "en";
	}
	
	static function get_screenDPI() {
		return 72.;
	}
	
	static function get_isAndroid() 	return false;
	static function get_isWindows() 	return false;
	static function get_isIOS() 		return false;
	static function get_isMac() 		return false;
	static function get_isLinux() 		return false;
	static function get_isWindowed() 	return true;
	static function get_isTouch() 		return false;
	static function get_isSwitch() 		return false;
	
	static function get_width() {
		return js.Browser.document.width;
	}
	
	static function get_height() {
		return js.Browser.document.height;
	}
	
	#elseif openfl

	static function get_isAndroid() { return #if android true 			#else false #end;	}
	static function get_isWindows() { return #if windows true 			#else false #end;	}
	static function get_isIOS() 	{ return #if ios true 				#else false #end;	}
	static function get_isMac() 	{ return #if mac true 				#else false #end;	}
	static function get_isLinux() 	{ return #if linux true 			#else false #end;	}
	static function get_isSwitch() 	{ return #if (lime_switch) true 	#else false #end;	}
	
	static var updateLoop = null;
	static var renderLoop = null;
	
	public static function setLoop( update : Void -> Void, ?render: Void->Void) {
		if ( renderLoop != null ) 	flash.Lib.current.removeEventListener(openfl.events.RenderEvent.RENDER_OPENGL, renderLoop);
		if ( updateLoop != null ) 	flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, updateLoop);
		
		
		if ( updateLoop == null ) updateLoop = null;
		if ( renderLoop == null ) renderLoop = null;
		
		if ( render != null){
			hxd.System.trace1("render loop added");
			renderLoop = function(_) {
				render();
			}
			flash.Lib.current.addEventListener(openfl.events.RenderEvent.RENDER_OPENGL, renderLoop);
		}
		
		if ( update != null){
			hxd.System.trace1("update loop added");
			updateLoop = function(e) {
				update();
			}
			flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, updateLoop);
		}
		
		
	}
	
	public static var setCursor = setNativeCursor;
	public static function setNativeCursor( c : Cursor ) {
		/* not supported by openFL
		flash.ui.Mouse.cursor = switch( c ) {
		case Default: "auto";
		case Button: "button";
		case Move: "hand";
		case TextInput: "ibeam";
		case Hide: "auto";
		}
		*/
		if( c == Hide ) flash.ui.Mouse.hide() else flash.ui.Mouse.show();
	}
	
	static function get_lang() {
		return flash.system.Capabilities.language.split("-")[0];
	}
	
	static function get_screenDPI() {
		return flash.system.Capabilities.screenDPI;
	}
	
	static var CACHED_NAME = null;
	public static function getDeviceName() {
		if( CACHED_NAME != null )
			return CACHED_NAME;
		var name;
		if( isAndroid ) {
			try {
				var content = sys.io.File.getContent("/system/build.prop");
				name = StringTools.trim(content.split("ro.product.model=")[1].split("\n")[0]);
			} catch( e : Dynamic ) {
				name = "Android";
			}
		} else
			name = "PC";
		CACHED_NAME = name;
		return name;
	}
	
	public static function exit() {
		Sys.exit(0);
	}

	static function get_isWindowed() {
		return true;
	}
	
	static function get_isTouch() {
		return false;
	}
	
	static function get_width() {
		var Cap = flash.system.Capabilities;
		return isWindowed ? flash.Lib.current.stage.stageWidth : Std.int(Cap.screenResolutionX > Cap.screenResolutionY ? Cap.screenResolutionX : Cap.screenResolutionY);
	}

	static function get_height() {
		var Cap = flash.system.Capabilities;
		return isWindowed ? flash.Lib.current.stage.stageHeight : Std.int(Cap.screenResolutionX > Cap.screenResolutionY ? Cap.screenResolutionY : Cap.screenResolutionX);
	}

	#end
	
	/**
	 * trace in the user space channel log
	 */
	public inline static function rtrace1(msg : Dynamic, ?pos:PosInfos) {
		if ( debugLevel >= 1) trace(pos.fileName + ":" + pos.methodName + ":" + pos.lineNumber + " " + msg);
		return msg;
	}
	
	/**
	 * trace in the user space channel log
	 */
	public inline static function trace1(msg : Dynamic, ?pos:PosInfos) {
		#if debug
		if ( debugLevel >= 1) trace(pos.fileName + ":" + pos.methodName + ":" + pos.lineNumber + " " + msg);
		return msg;
		#end
	}
	
	/**
	 * trace in the engine space channel log
	 */
	public inline static function trace2(msg : Dynamic, ?pos:PosInfos) {
		#if debug
		if ( debugLevel >= 2) trace(pos.fileName + ":" + pos.methodName + ":" + pos.lineNumber + " " + msg);
		return msg;
		#end
	}
	
	/**
	 * trace in the debug engine space channel log
	 */
	public inline static function trace3(msg : Dynamic, ?pos:PosInfos) {
		#if debug
		if ( debugLevel >= 3) trace(pos.fileName + ":" + pos.methodName + ":" + pos.lineNumber + " " + msg);
		return msg;
		#end
	}
	
	public inline static function trace4(_) {
	}
}
