package hxd;
using StringTools;

typedef BaseConf = {
	var ids:Array<String>;	//identifier for matching and default setups
	var name:String;		//identifier for matching and default setups
	var names:Array<String>;
	var dpadUp 		: Int;
	var dpadDown 	: Int;
	var dpadLeft 	: Int;
	var dpadRight 	: Int;
	
	var analogX 	:Int;
	var analogY 	:Int;
	
	var A 	:Int;
	var B 	:Int;
	var X 	:Int;
	var Y 	:Int;
	var LB 	:Int;
	var RB 	:Int;
	var defaultYInverted :Bool;
	var matchString :String;
	var metaName : String;
}

class Pad {
	
	public static var USE_POLLING = true; //requires .update call at frame end
	public static var CONFIG_XBOX : BaseConf = cast {
		ids:["XINPUT_DEVICE_0"],
		name:"Xbox 360 Controller (XInput STANDARD GAMEPAD)",
		matchString:"XInput",
		metaName:"Pad XboxOne/360",
		
		analogX : 0,
		analogY : 1,
		ranalogX : 2,
		ranalogY : 3,
		A : 4,
		B : 5,
		X : 6,
		Y : 7,
		LB : 8,
		RB : 9,
		LT : 10,
		RT : 11,
		back : 12,
		start : 13,
		analogClick : 14,
		ranalogClick : 15,
		dpadUp : 16,
		dpadDown : 17,
		dpadLeft : 18,
		dpadRight : 19,
		names : ["LX", "LY", "RX", "RY", "A", "B", "X", "Y", "LB", "RB", "LT", "RT", "Select", "Start", "LCLK", "RCLK", "DUp", "DDown", "DLeft", "DRight"],
		defaultYInverted:true,
	};
	
	public static var CONFIG_XARCADE : BaseConf = cast {
		ids:["0B345A50-1D48-11E6-8002-444553540000","0B343340-1D48-11E6-8001-444553540000"],
		name:"USB GamePad",
		matchString:"USB GamePad",
		metaName:"XArcade",
		analogX : 0,
		analogY : 1,
		
		X:11,
		Y:9,
		LB:14,
		
		A:10,
		B:8,
		RB:15,
		
		start : 17,
		dpadUp : 20,
		dpadDown : 22,
		dpadLeft : 23,
		dpadRight : 21,
		names : [
		"LX", "LY", "", "", "",//0-4
		"", "", "", "B", "Y",//5-9
		"A", "X", "", "", "LB",//10-14
		"RB", "", "start", "", "",//15-19
		"DUp","DRight","DDown","DLeft"
		],
		defaultYInverted:false,
	}
	
	public static var CONFIG_RAP4 : BaseConf = cast {
		ids:["E8AFC630-E6DE-11E5-8002-444553540000"],
		name:"Real Arcade Pro.4",
		matchString:"Real Arcade",
		metaName:"RAP4",
		analogX : 30,
		analogY : 31,
		
		X:10,
		Y:13,
		LB:14,
		
		A:11,
		B:12,
		RB:15,
		
		start : 19,
		dpadUp : 6,
		dpadDown : 7,
		dpadLeft : 8,
		dpadRight : 9,
		names : [
		"", "", "", "", "",//0-4
		"", "DUp", "DDown", "DLeft", "DRight", //5-9
		"SQUARE", "CROSS", "CIRCLE", "TRIANGLE", "L1",//10-14
		"R1", "L2", "R2", "Share", "Options", //15-19
		"L3","R3","PS Button",//20-24
		],
		defaultYInverted:false,
	}
	
	public static var CONFS :Array<Dynamic> = [CONFIG_XARCADE, CONFIG_XBOX,CONFIG_RAP4];

	public var connected(default, null) = true;
	public var name(get, never) : String;
	public var index : Int = -1;
	public var xAxis : Float = 0.;
	public var yAxis : Float = 0.;
	
	public var xAxisIndex = 0;
	public var yAxisIndex = 1;
	
	public var xInverted = false;
	public var yInverted = false;
	
	public var buttons : Array<Bool> = [];
	public var values : Array<Float> = [];
	public var axis : Array<Bool> = [];
	
	/**
	 * Requires .update calls at frame end
	 */
	public var prevButtons : Array<Bool> = [];
	
	/**
	 * Requires .update calls at frame end
	 */
	public var prevValues : Array<Float> = [];
	
	public var nativeIds : Array<String> = [];
	
	#if flash
	public var nativeControls : Array<flash.ui.GameInputControl> = [];
	#end
	
	public var conf:BaseConf;
	public var destroyed = false;

	function new() {
	}

	function get_name() {
		if( index < 0 ) return "Dummy GamePad";
		#if flash
		return d.name;
		#else
		return "GamePad";
		#end
	}
	
	public dynamic function onRemoval() {
		
	}

	public inline function isDown(idx:Int) : Bool {
		return values[idx] <= -0.25 || values[idx] >= 0.25;
	}
	
	public inline function wasDown(idx:Int) : Bool {
		return prevValues[idx] <= -0.25 || prevValues[idx] >= 0.25;
	}
	
	public inline function isAxis(btIdx:Int){
		return nativeIds[btIdx].startsWith("AXIS_");
	}
	
	public inline function onPress(idx:Int) : Bool {
		return isDown(idx)&&!wasDown(idx);
	}
	
	public function getButtonName(idx:Int) {
		return 
		if ( conf == null)
			"BUTTON_" + idx;
		else 
			conf.names[idx];
	}
	/**
		Creates a new dummy unconnected game pad, which can be used instead of checking for null everytime. Use wait() to get real physical game pad access.
	**/
	public static function createDummy() {
		var p = new Pad();
		p.connected = false;
		return p;
	}

	#if flash
	public var d : flash.ui.GameInputDevice;
	static var initDone = false;
	static var inst : flash.ui.GameInput;
	static var dummy : Pad;
	#end
	public static var padList : Array<Pad> = [];

	/**
		Wait until a gamepad gets connected. On some platforms, this might require the user to press a button until it activates
	**/
		
	#if flash
	public static function nbPads() return flash.ui.GameInput.numDevices;
	#end
	
	public static function getPadByIndex(idx) {
		for ( p in padList)
			if ( p.index == idx )
				return p;
		return dummy;
	}
	
	public static function getPadByName(name:String) {
		for ( p in padList)
			if ( p.name == name )
				return p;
		return dummy;
	}
	
	#if flash
	public static function getPadById(id:String) {
		for ( p in padList)
			if ( p.d.id == id )
				return p;
		return dummy;
	}
	#end
	
	public static function wait( onPad : Pad -> Void ) {
		#if flash
		if( !initDone ) {
			initDone = true;
			inst = new flash.ui.GameInput();
			dummy = createDummy();
			scanForPad(onPad);
		}
		#else
		#end
	}

	#if flash
	static function onDeviceUnusable(e:flash.events.GameInputEvent) {
		trace(e.device.name+" is unusable");
	}
	
	static function onDeviceRemoved(e:flash.events.GameInputEvent) {
		trace(e.device.name+" is removed");
		for (p in padList.copy()) {
			if (p.d == e.device ) {
				p.destroyed = true;
				p.onRemoval();
				padList.remove(p);
			}
		}
	}
	
	static function onDeviceAdded(onPad:Pad->Void, e:flash.events.GameInputEvent) {
		//trace(e.device.name+" is added");
		var p = new Pad();
		p.d = e.device;
		
		for( i in 0...flash.ui.GameInput.numDevices )
			if( p.d == flash.ui.GameInput.getDeviceAt(i) )
				p.index = i;
				
		for ( ps in padList ) {
			if ( ps.d.id == p.d.id )
				return;
		}
		
		//match device to see if known
		var pid = p.d.id;
		var pname = p.d.name;
		for ( c in CONFS) {
			if ( pname.toLowerCase().indexOf( c.matchString.toLowerCase() ) >= 0 ) {
				//trace("found one match " + c.name);
				p.conf = c;
				if ( c.defaultXInverted ) p.xInverted = true;
				if ( c.defaultYInverted ) p.yInverted = true;
				break;
			}
		}
		
		p.d.enabled = true;
		var axisCount = 0;
		var axisX = 0, axisY = 1;
		
		for( i in 0...p.d.numControls ) {
			var c = p.d.getControlAt(i);
			var cid = c.id;
			var valID = i;
			var min = c.minValue, max = c.maxValue;
			
			p.values.push(0.);
			p.nativeIds.push(c.id);
			p.nativeControls.push(c);
			p.buttons.push(false);
			
			if( StringTools.startsWith(c.id, "AXIS_") ) {
				var axisID = axisCount++;
				p.axis[valID] = true;
				if( !USE_POLLING)
					c.addEventListener(flash.events.Event.CHANGE, function(_) {
						var v = (c.value - min) * 2 / (max - min) - 1;
						p.values[valID] = v;
						
						if( axisID == axisX ) 		p.xAxis = !p.xInverted?v:-v;
						else if ( axisID == axisY ) p.yAxis = !p.yInverted?v: -v;
					});
			} else if ( StringTools.startsWith(c.id, "BUTTON_") ) {
				p.axis[valID] = false;
				if( !USE_POLLING)
					c.addEventListener(flash.events.Event.CHANGE, function(_) {
						var v = (c.value - min) / (max - min);
						p.values[valID] = v;
						p.buttons[valID] = v > 0.5;
					});
			}
			else {
				p.axis[valID] = false;
				p.values[valID] = 0;
				p.buttons[valID] = false;
			}
			//else trace("unrecognised id " + c.id);
		}

		if ( onPad != null ) onPad(p);
		
		padList.push(p);
	}
	
	public static function scanForPad(onPad:Pad->Void) {
		inst.addEventListener(flash.events.GameInputEvent.DEVICE_UNUSABLE,onDeviceUnusable);
		inst.addEventListener(flash.events.GameInputEvent.DEVICE_ADDED, onDeviceAdded.bind(onPad));
		inst.addEventListener(flash.events.GameInputEvent.DEVICE_REMOVED, onDeviceRemoved);
		var count = flash.ui.GameInput.numDevices; // necessary to trigger added
	}
	#end
	
	/**
	 * Allows polling and prevValues
	 */
	public static function update() {
		for ( p in padList) {
			for (i in 0...p.buttons.length) {
				p.prevButtons[i] = p.buttons[i];
				p.prevValues[i] = p.values[i];
				
				if ( USE_POLLING ) {
					var c = p.nativeControls[i];
					var axisX = 0;
					var axisY = 1;
						
					if ( p.axis[i]) {
						var v = (c.value - c.minValue) * 2 / (c.maxValue - c.minValue) - 1;
						
						if( i == axisX ) 		p.xAxis = !p.xInverted?v:-v;
						else if ( i == axisY ) 	p.yAxis = !p.yInverted?v:-v;
						
						p.values[i] = v;
					}
					else {
						var v = (c.value - c.minValue) / (c.maxValue - c.minValue);
						p.values[i] = v;
						p.buttons[i] = v > 0.5;
					}
				}
			}
		}
		
	}
} 