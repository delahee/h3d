package h2d;

import hxd.Key;
using StringTools;
enum ConsoleArg {
	AInt;
	AFloat;
	AString;
	ABool;
	AEnum( values : Array<String> );
}

typedef Args = { name : String, t : ConsoleArg, ?opt : Bool };
private typedef Cmd = { help : String, args : Array<Args>, callb : Dynamic };
class Console extends h2d.Sprite {

	public static var HIDE_LOG_TIMEOUT = 3.;

	var bg : h2d.Bitmap;
	var tf : h2d.Text;
	var logTxt : h2d.HtmlText;
	var cursor : h2d.Bitmap;
	var cursorPos(default, set) : Int;
	var lastLogTime : Float 				= 0.0;
	var commands : Map < String, Cmd>;
	var aliases : Map<String,String>;
	var logDY : Float = 0;
	var logs : hxd.Stack<String>;
	var logIndex:Int;
	var curCmd			: String;
	var cheight 		: Float=0;
	var cwidth 			: Float=0;
	public var shortKeyChars : Array<Int> = ["/".code,"²".code];
	public var useMouseWheel = true;
	
	public var data : Dynamic = {};

	/**
	* One can attach the console to his render
	* you can use the / key to open the console then execute added commands
	*/
	public function new(font:h2d.Font,?parent) {
		super(parent);
		cheight = font.lineHeight + 2;
		logTxt = new h2d.HtmlText(font, this);
		logTxt.name = "console.logText";
		logTxt.x = 2;
		logTxt.visible = false;
		logs = new Stack();
		logIndex = -1;
		bg = new h2d.Bitmap(h2d.Tile.fromColor(0xFF000000), this);
		bg.name = "console.bg";
		bg.visible = false;
		tf = new h2d.Text(font, bg);
		tf.name = "console.tf";
		tf.x = 2;
		tf.y = 1;
		tf.textColor = 0xFFFFFFFF;
		cursor = new h2d.Bitmap(h2d.Tile.fromColor(tf.textColor | 0xFF000000, 1, font.lineHeight), tf);
		cursor.name = "console.cursor";
		commands = new Map();
		aliases = new Map();
		defaultCommands();
	}
	
	public function setFont( font:h2d.Font ){
		logTxt.font = font;
		tf.font = font;
	}
	
	public function defaultCommands(){
		addCommand("help", "Show help", [ { name : "command", t : AString, opt : true } ], showHelp);
		addCommand("set", "sets a console's value", [ { name : "name", t : AString }, { name : "val", t : AString } ], setVal);
		addCommand("setInt", "sets a console's value", [ { name : "name", t : AString }, { name : "val", t : AInt } ], setVal);
		addCommand("setFloat", "sets a console's value", [ { name : "name", t : AString }, { name : "val", t : AFloat} ], setVal);
		addAlias("?", "help");
	}

	public function addCommand( name, help, args:Array<Args>, callb : Dynamic ) {
		commands.set(name, { help : help, args:args, callb:callb } );
	}

	public function addAlias( alias, command ) {
		aliases.set(alias, command); 
		#if debug
		if ( !commands.exists(command) ) trace("invalid alias "+alias+" > "+command);
		#end
	}

	public function runCommand( commandLine : String ) {
		handleCommand(commandLine);
	}

	override function onAlloc() {
		super.onAlloc();
		getScene().addEventListener(onEvent);
	}

	override function onDelete() {
		getScene().removeEventListener(onEvent);
		super.onDelete();
	}

	function onEvent( e : hxd.Event ) {
		//#if debug
		//trace("Console:recv " + e.keyCode);
		//#end
		switch( e.kind ) {
		case EWheel:
			if( logTxt.visible && useMouseWheel ) {
				logDY -= tf.font.lineHeight * e.wheelDelta * 3;
				if( logDY < 0 ) logDY = 0;
				if( logDY > logTxt.textHeight ) logDY = logTxt.textHeight;
				e.propagate = false;
			}
		case EKeyDown:
			handleKey(e);
			if( bg.visible ) e.propagate = false;
		default:
		}
	}
	
	function setVal(name,val) 		Reflect.setField( data, name, val );

	function showHelp( ?command : String ) {
		//#if debug
		//trace("Showing help!");
		//#end
		
		var all;
		if( command == null ) {
			all = Lambda.array( { iterator : function() return commands.keys() } );
			all.sort(Reflect.compare);
			all.remove("help");
			all.push("help");
		} else {
			if( aliases.exists(command) ) command = aliases.get(command);
			if( !commands.exists(command) )
				throw 'Command not found "$command"';
			all = [command];
		}
		for( cmdName in all ) {
			var c = commands.get(cmdName);
			var str = "/" + cmdName;
			for( a in aliases.keys() )
				if( aliases.get(a) == cmdName )
					str += " | " + a;
			for( a in c.args ) {
				var astr = a.name;
				switch( a.t ) {
				case AInt, AFloat:
					astr += ":"+a.t.getName().substr(1);
				case AString:
					// nothing
				case AEnum(values):
					astr += "=" + values.join("|");
				case ABool:
					astr += "=0|1";
				}
				str += " " + (a.opt?"["+astr+"]":astr);
			}
			if( c.help != "" )
				str += " : " + c.help;
			log(str);
		}
	}

	public function isInactive() {
		return !bg.visible&&!logTxt.visible;
	}
	
	public function isActive() {
		return !isInactive();
	}

	function set_cursorPos(v:Int) {
		cursor.x = tf.calcTextWidth(tf.text.substr(0, v));
		return cursorPos = v;
	}

	function handleKey( e : hxd.Event ) {
		if ( (shortKeyChars.indexOf(e.charCode) >= 0) && !bg.visible ) {
			lastLogTime = haxe.Timer.stamp();
			bg.visible = true;
			logIndex = -1;
			//trace("SHOW");
		}
		else {
			//trace("hmm "+ bg.visible+" "+shortKeyChars+" "+e.charCode);
		}
		
		if( !bg.visible )
			return;
		switch( e.keyCode ) {
		case Key.PGUP :
			logDY += tf.font.lineHeight;
			if( logDY < 0 ) logDY = 0;
			if( logDY > logTxt.textHeight ) logDY = logTxt.textHeight;
		case Key.PGDOWN :
			logDY -= tf.font.lineHeight;
			if( logDY < 0 ) logDY = 0;
			if( logDY > logTxt.textHeight ) logDY = logTxt.textHeight;

		case Key.LEFT:
			if( cursorPos > 0 )
				cursorPos--;
		case Key.RIGHT:
			if( cursorPos < tf.text.length )
				cursorPos++;
		case Key.HOME:
			cursorPos = 0;
		case Key.END:
			cursorPos = tf.text.length;
		case Key.DELETE:
			tf.text = tf.text.substr(0, cursorPos) + tf.text.substr(cursorPos + 1);
			return;
		case Key.BACKSPACE:
			if( cursorPos > 0 ) {
				tf.text = tf.text.substr(0, cursorPos - 1) + tf.text.substr(cursorPos);
				cursorPos--;
			}
			return;
		case Key.ENTER, Key.CTRL:
			//#if debug
			//trace("ENTER!");
			//#end
			var cmd = tf.text;
			tf.text = "";
			cursorPos = 0;
			lastLogTime = haxe.Timer.stamp();
			handleCommand(cmd);
			if( !logTxt.visible ) bg.visible = false;
			return;
		case Key.ESCAPE:
			hide();
			return;
		case Key.UP:
			if(logs.length == 0 || logIndex == 0) return;
			if(logIndex == -1) {
				curCmd = tf.text;
				logIndex = logs.length - 1;
			}
			else logIndex--;
			tf.text = logs.get(logIndex);
			cursorPos = tf.text.length;
		case Key.DOWN:
			if(tf.text == curCmd) return;
			if(logIndex == logs.length - 1) {
				tf.text = curCmd;
				cursorPos = tf.text.length;
				logIndex = -1;
				return;
			}
			logIndex++;
			tf.text = logs.get(logIndex);
			cursorPos = tf.text.length;
		}
		if( e.charCode != 0 ) {
			tf.text = curCmd = tf.text.substr(0, cursorPos) + String.fromCharCode(e.charCode) + tf.text.substr(cursorPos);
			cursorPos++;
		}
	}

	override function hide() {
		bg.visible = false;
		tf.text = "";
	}

	var exp : EReg = ~/[ \t]+/g;
	
	function handleCommand( command : String ) {
		command = StringTools.trim(command);
		for ( s in shortKeyChars) 
			if ( command.startsWith( String.fromCharCode(s )))
				command = command.substr(1);
		
			if( command == "" ) {
			hide();
			return;
		}
		logs.push(command);
		logIndex = -1;

		var args = exp.split(command);
		var cmdName = args[0];
		if( aliases.exists(cmdName) ) cmdName = aliases.get(cmdName);
		var cmd = commands.get(cmdName);
		var errorColor = 0xC00000;
		if( cmd == null ) {
			log('Unknown command ${cmdName}', errorColor);
			#if debug
			trace('Unknown command : >${cmdName}<', errorColor);
			#end
			return;
		}
		var vargs = new Array<Dynamic>();
		for( i in 0...cmd.args.length ) {
			var a = cmd.args[i];
			var v = args[i + 1];
			if( v == null ) {
				if( a.opt ) {
					vargs.push(null);
					continue;
				}
				log('Missing argument ${a.name}',errorColor);
				return;
			}
			switch( a.t ) {
			case AInt:
				var i = Std.parseInt(v);
				if( i == null ) {
					log('$v should be Int for argument ${a.name}',errorColor);
					return;
				}
				vargs.push(i);
			case AFloat:
				var f : Float = Std.parseFloat(v);
				if( Math.isNaN(f) ) {
					log('$v should be Float for argument ${a.name}',errorColor);
					return;
				}
				vargs.push(f);
			case ABool:
				switch( v ) {
				case "true", "1": vargs.push(true);
				case "false", "0": vargs.push(false);
				default:
					log('$v should be Bool for argument ${a.name}',errorColor);
					return;
				}
			case AString:
				vargs.push(v);
			case AEnum(values):
				var found = false;
				for( v2 in values )
					if( v == v2 ) {
						found = true;
						vargs.push(v2);
						break;
					}
				if( !found ) {
					log('$v should be [${values.join("|")}] for argument ${a.name}', errorColor);
					return;
				}
			}
		}
		try {
			Reflect.callMethod(null, cmd.callb, vargs);
		} catch ( e : Dynamic ) {
			var msg : String = Std.string(e);
			#if (debug||!prod)
				trace("err running cmd :"+command);
				trace(e);
				
				#if cpp
				trace( haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
				#end
			
			#end
			log('ERROR $e', errorColor);
		}
	}

	public function clearLog(){
		logTxt.htmlText="";
	}

	public function log( text : Dynamic, ?color ) {
		var text = Std.string(text);
		if ( color == null ) color = tf.textColor;

		var oldH = logTxt.textHeight;
		logTxt.htmlText += '<font color="#${StringTools.hex(color&0xFFFFFF,6)}">${StringTools.htmlEscape(text)}</font><br/>';

		if( logDY != 0 ) logDY += logTxt.textHeight - oldH;
		logTxt.alpha = 1;
		logTxt.visible = true;
		lastLogTime = haxe.Timer.stamp();
		return text;
	}
	
	public function showBg() {
		bg.visible = true;
	}

	public var baseY :Null<Int>= null;
	override function sync(ctx:h2d.RenderContext) {
		var scene = getScene();
		if( scene != null ) {
			x = 0;
			y = baseY==null?scene.height:baseY - cheight;
			cwidth = scene.width;
			bg.tile.scaleToSize(Math.round(width), Math.round(cheight));
		}
		var log = logTxt;
		if( log.visible ) {
			log.y = bg.y - log.textHeight + logDY;
			var dt = haxe.Timer.stamp() - lastLogTime;
			if( dt > HIDE_LOG_TIMEOUT && !bg.visible ) {
				log.alpha -= ctx.elapsedTime * 4;
				if( log.alpha <= 0 )
					log.visible = false;
			}
		}
		super.sync(ctx);
	}

}