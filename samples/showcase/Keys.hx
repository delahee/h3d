
class Keys {
	
	public static inline var BACKSPACE	= 8;
	public static inline var TAB		= 9;
	public static inline var ENTER		= 13;
	public static inline var SHIFT		= 16;
	public static inline var CTRL		= 17;
	public static inline var ALT		= 18;
	public static inline var ESCAPE		= 27;
	public static inline var SPACE		= 32;
	public static inline var PGUP		= 33;
	public static inline var PGDOWN		= 34;
	public static inline var END		= 35;
	public static inline var HOME		= 36;
	public static inline var LEFT		= 37;
	public static inline var UP			= 38;
	public static inline var RIGHT		= 39;
	public static inline var DOWN		= 40;
	public static inline var INSERT		= 45;
	public static inline var DELETE		= 46;
	
	public static inline var NUMBER_0	= 48;
	public static inline var NUMBER_1	= 49;
	public static inline var NUMBER_2	= 50;
	public static inline var NUMBER_3	= 51;
	public static inline var NUMBER_4	= 52;
	public static inline var NUMBER_5	= 53;
	public static inline var NUMBER_6	= 54;
	public static inline var NUMBER_7	= 55;
	public static inline var NUMBER_8	= 56;
	public static inline var NUMBER_9	= 57;
	
	public static inline var A			= 65;
	public static inline var B			= 66;
	public static inline var C			= 67;
	public static inline var D			= 68;
	public static inline var E			= 69;
	public static inline var F			= 70;
	public static inline var G			= 71;
	public static inline var H			= 72;
	public static inline var I			= 73;
	public static inline var J			= 74;
	public static inline var K			= 75;
	public static inline var L			= 76;
	public static inline var M			= 77;
	public static inline var N			= 78;
	public static inline var O			= 79;
	public static inline var P			= 80;
	public static inline var Q			= 81;
	public static inline var R			= 82;
	public static inline var S			= 83;
	public static inline var T			= 84;
	public static inline var U			= 85;
	public static inline var V			= 86;
	public static inline var W			= 87;
	public static inline var X			= 88;
	public static inline var Y			= 89;
	public static inline var Z			= 90;
	
	public static inline var NUMPAD_0		= 96;
	public static inline var NUMPAD_1		= 97;
	public static inline var NUMPAD_2		= 98;
	public static inline var NUMPAD_3		= 99;
	public static inline var NUMPAD_4		= 100;
	public static inline var NUMPAD_5		= 101;
	public static inline var NUMPAD_6		= 102;
	public static inline var NUMPAD_7		= 103;
	public static inline var NUMPAD_8		= 104;
	public static inline var NUMPAD_9		= 105;
	
	public static inline var NUMPAD_MULT 	= 106;
	public static inline var NUMPAD_ADD		= 107;
	public static inline var NUMPAD_ENTER 	= 108;
	public static inline var NUMPAD_SUB 	= 109;
	public static inline var NUMPAD_DOT 	= 110;
	public static inline var NUMPAD_DIV 	= 111;
	
	public static inline var F1			= 112;
	public static inline var F2			= 113;
	public static inline var F3			= 114;
	public static inline var F4			= 115;
	public static inline var F5			= 116;
	public static inline var F6			= 117;
	public static inline var F7			= 118;
	public static inline var F8			= 119;
	public static inline var F9			= 120;
	public static inline var F10		= 121;
	public static inline var F11		= 122;
	public static inline var F12		= 123;
	
	
	public static inline var DOLLAR		= 186;
	public static inline var CLOSE_BRACKET	= 221;
	
	public static inline var SQUARE = 222;
	
	var prevFrameKeys 	: hxd.BitArray 	= new hxd.BitArray();
	var frameKeys 		: hxd.BitArray 	= new hxd.BitArray();
	var keyDown 		: hxd.BitArray 	= new hxd.BitArray();
	
	public var customOnKeyDown : flash.events.KeyboardEvent -> Void;
	
	public var onKeyDownStealer : Array<flash.events.KeyboardEvent -> Void>=[];
	public var onKeyUpStealer : Array<flash.events.KeyboardEvent -> Void>=[];
	
	public function new() {
		for( i in 0...256 ){
			prevFrameKeys.set(i, false);
			frameKeys.set(i,false);
			keyDown.set(i,false);
		}
	}
	
	public function init() {
		flash.Lib.current.stage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, 	okd);
		flash.Lib.current.stage.addEventListener(flash.events.KeyboardEvent.KEY_UP, 	oku);
	}
	
	public function destroy() {
		flash.Lib.current.stage.removeEventListener(flash.events.KeyboardEvent.KEY_DOWN, 	okd);
		flash.Lib.current.stage.removeEventListener(flash.events.KeyboardEvent.KEY_UP, 		oku);
	}
	
	function okd(e:flash.events.KeyboardEvent) {
		if ( onKeyDownStealer.length>0)
			onKeyDownStealer[0](e);
		else {
			keyDown.set(e.keyCode, true);
			if ( customOnKeyDown !=	null )
				customOnKeyDown(e);
		}
	}
	
	function oku(e:flash.events.KeyboardEvent) {
		//trace("oku:"+e.keyCode);
		if ( onKeyUpStealer.length>0)
			onKeyUpStealer[0](e);
		else 	
			keyDown.set(e.keyCode, false);
	}
	
	public function update() {
		prevFrameKeys.copy( frameKeys );
		frameKeys.copy( keyDown );
	}
	
	public inline function isToggled( kc : Int ) {
		return isReleased(kc);
	}
	
	/**
	 * true the frame after key is pressed
	 */
	public inline function onPress( kc : Int ) {
		return frameKeys.has(kc)&&!prevFrameKeys.has(kc);
	}
	
	public inline function onHold( kc : Int ) {
		return frameKeys.has(kc)&&prevFrameKeys.has(kc);
	}
	
	public inline function clearKey(kc:Int ) {
		frameKeys.set(kc, false);
	}
	
	public inline function clearPrevKey(kc:Int ) {
		prevFrameKeys.set(kc, false);
	}
	
	/**
	 * true when the key is down
	 */
	public inline function isDown( kc : Int ) 
		return frameKeys.has(kc);
	
	public inline function onDown( kc : Int ) 
		return isDown(kc) && !wasDown(kc);
	
	public inline function wasDown( kc : Int ) 
		return prevFrameKeys.has(kc);
	
	public inline function isHold( kc : Int ) 
		return frameKeys.has(kc)&&prevFrameKeys.has(kc);
	
	public inline function onRelease( kc : Int ) {
		return isReleased( kc );
	}
	
	public inline function isReleased( kc : Int ) {
		return !frameKeys.has(kc)&&prevFrameKeys.has(kc);
	}
	
	public function clear() {
		frameKeys.clear();
		prevFrameKeys.clear();
		keyDown.clear();
	}
	
	public function keycodeToCode(kc:Int) : String {
		return
		switch(kc) {
			default				: "<error>";			
			case BACKSPACE		: "BACKSPACE";	
			case TAB			: "TAB";
			case ENTER			: "ENTER";	
			case SHIFT			: "SHIFT";	
			case CTRL			: "CTRL";
			case ALT			: "ALT";
			case ESCAPE			: "ESCAPE";	
			case SPACE			: "SPACE";	
			case PGUP			: "PGUP";
			case PGDOWN			: "PGDOWN";	
			case END			: "END";
			case HOME			: "HOME";
			case LEFT			: "LEFT";
			case UP				: "UP";	
			case RIGHT			: "RIGHT";	
			case DOWN			: "DOWN";
			case INSERT			: "INSERT";	
			case DELETE			: "DELETE";	
			case NUMBER_0		: "NUMBER_0";
			case NUMBER_1		: "NUMBER_1";
			case NUMBER_2		: "NUMBER_2";
			case NUMBER_3		: "NUMBER_3";
			case NUMBER_4		: "NUMBER_4";
			case NUMBER_5		: "NUMBER_5";
			case NUMBER_6		: "NUMBER_6";
			case NUMBER_7		: "NUMBER_7";
			case NUMBER_8		: "NUMBER_8";
			case NUMBER_9		: "NUMBER_9";
			case A				: "A";	
			case B				: "B";	
			case C				: "C";	
			case D				: "D";	
			case E				: "E";	
			case F				: "F";	
			case G				: "G";	
			case H				: "H";	
			case I				: "I";	
			case J				: "J";	
			case K				: "K";	
			case L				: "L";	
			case M				: "M";	
			case N				: "N";	
			case O				: "O";	
			case P				: "P";	
			case Q				: "Q";	
			case R				: "R";	
			case S				: "S";	
			case T				: "T";	
			case U				: "U";	
			case V				: "V";	
			case W				: "W";	
			case X				: "X";	
			case Y				: "Y";	
			case Z				: "Z";	
			case F1				: "F1";	
			case F2				: "F2";	
			case F3				: "F3";	
			case F4				: "F4";	
			case F5				: "F5";	
			case F6				: "F6";	
			case F7				: "F7";	
			case F8				: "F8";	
			case F9				: "F9";	
			case F10			: "F10";
			case F11			: "F11";
			case F12			: "F12";
			case NUMPAD_0		: "NUMPAD_0";	
			case NUMPAD_1		: "NUMPAD_1";	
			case NUMPAD_2		: "NUMPAD_2";	
			case NUMPAD_3		: "NUMPAD_3";	
			case NUMPAD_4		: "NUMPAD_4";	
			case NUMPAD_5		: "NUMPAD_5";	
			case NUMPAD_6		: "NUMPAD_6";	
			case NUMPAD_7		: "NUMPAD_7";	
			case NUMPAD_8		: "NUMPAD_8";	
			case NUMPAD_9		: "NUMPAD_9";	
			case NUMPAD_MULT 	: "NUMPAD_MULT";
			case NUMPAD_ADD		: "NUMPAD_ADD";	
			case NUMPAD_ENTER 	: "NUMPAD_ENTER";	
			case NUMPAD_SUB 	: "NUMPAD_SUB";
			case NUMPAD_DOT 	: "NUMPAD_DOT";
			case NUMPAD_DIV 	: "NUMPAD_DIV";
			case SQUARE 		: "SQUARE";
			case DOLLAR 		: "DOLLAR";
			case CLOSE_BRACKET 	: "CLOSE_BRACKET";
		};
	}
}