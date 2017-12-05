package h2d;

typedef InputConf = {
	font:h2d.Font,
	txt:String,
	
	width:Float,
	
	?bgAlpha:Float,
	?bgColor:Int,
};

class Input extends h2d.Interactive
{
	var tf : h2d.Text;
	var cursorImg : h2d.Bitmap;
	var cursorPos(default,set) : Int;
	public var deferValidation = false;
	public var value(default, set) : String;
	
	public var bg:h2d.Sprite;
	
	var conf : InputConf;
	
	public var sigFocus 		: hxd.Signal = new hxd.Signal();
	public var sigClick 		: hxd.Signal = new hxd.Signal();
	public var sigFocusLost 	: hxd.Signal = new hxd.Signal();
	public var sigEnter 		: hxd.Signal = new hxd.Signal();
	
	var mask : h2d.Mask;
	var subMask : h2d.Sprite;
	
	static function retrieveClipboad() {
		return flash.desktop.Clipboard.generalClipboard.getData(flash.desktop.ClipboardFormats.TEXT_FORMAT);
	}
	
	public function new(conf:InputConf,?parent:h2d.Sprite) {
		super( conf.width, conf.font.lineHeight, parent);
		this.conf = conf;
		
		var guessedHeight = conf.font.lineHeight;
		
		var gfx = new h2d.Graphics(this);
		mask = new h2d.Mask( conf.width+1, guessedHeight, this );
		subMask = new h2d.Sprite(mask);
		subMask.x = 1;
		tf = new h2d.Text( conf.font, subMask);
		
		this.value = tf.text = conf.txt;
		
		if( conf.bgAlpha!=null && conf.bgAlpha > 0.0 ){
			gfx.beginFill(conf.bgColor, conf.bgAlpha);
			gfx.drawRect(0,0,conf.width, guessedHeight);
			gfx.endFill();
		}
		bg = gfx;
		
		if ( tf.textWidth > conf.width ) {
			trace("input is too small");
		}
		
		cursor = TextInput;
		cursorImg = new h2d.Bitmap(Tools.getWhiteTile(), this);
		cursorImg.height = guessedHeight;
		cursorImg.width = 2;
		cursorImg.visible = false;
		this.onFocus = function(_) {
			cursorImg.visible = true;
			#if (openfl && cpp)
			flash.Lib.current.requestSoftKeyboard();
			#end
			sigFocus.trigger();
		};
		this.onFocusLost = function(_) {
			cursorImg.visible = false;
			onBlur();
			sigFocusLost.trigger();
		};
		this.onKeyDown = function(e:hxd.Event) {
			if ( hasFocus() ) {
				var k = hxd.Key;
				
				//TODO factorise in a custom event handler
				if ( k.isDown( hxd.Key.CTRL ) && k.isReleased( hxd.Key.V )) {
					//trace(Lib.retrieveClipboad());
					insertAtCaret( retrieveClipboad() );
					return;
				}
				
				// BACK
				switch( e.keyCode ) {
					
				case hxd.Key.ESCAPE:
					onFocusLost(null);
					
				case hxd.Key.LEFT:
					if( cursorPos > 0 )
						cursorPos--;
				case hxd.Key.RIGHT:
					if( cursorPos < value.length )
						cursorPos++;
				case hxd.Key.HOME:
					cursorPos = 0;
				case hxd.Key.END:
					cursorPos = value.length;
				case hxd.Key.DELETE:
					value = value.substr(0, cursorPos) + value.substr(cursorPos + 1);
					if (!deferValidation) onChange(value);
					syncVal();
					set_cursorPos( cursorPos );
					return;
				case hxd.Key.BACKSPACE:
					if( cursorPos > 0 ) {
						value = value.substr(0, cursorPos - 1) + value.substr(cursorPos);
						cursorPos--;
						if (!deferValidation) onChange(value);
						syncVal();
						set_cursorPos(cursorPos);
					}
					return;
				case hxd.Key.ENTER:
					if ( deferValidation )
						onChange(value);
					syncVal();
					sigEnter.trigger();
					blur();
					return;
				}
				
				if ( e.charCode != 0 ) 
					insertAtCaret(String.fromCharCode(e.charCode) );
			}
			//else ?
			return;
		};
		onClick = function(_) {
			inputFocus();
			sigClick.trigger();
		}
		
		tf.x = conf.width - tf.textWidth;
	}
	
	function insertAtCaret(str:String) {
		value = value.substr(0, cursorPos) + str + value.substr(cursorPos);
		if (!deferValidation) onChange(value);
		syncVal();
		cursorPos+=str.length;
	}
	
	function syncVal() {
		tf.text = value;
		tf.x = conf.width - tf.textWidth;
	}
	
	function set_cursorPos(v:Int) {
		cursorImg.x = tf.x + tf.calcTextWidth(value.substr(0, v)) ;
		
		if ( cursorImg.x >= tf.x + tf.width ) {
			cursorImg.x = tf.x + tf.width - 2;
		}
		
		return cursorPos = v;
	}

	function inputFocus() {
		super.focus();
		cursorPos = value.length;
	}
	
	function get_value() {
		return tf.text;
	}
	
	function set_value(t:String) {
		if (t == null) t = "";
		return value = t;
	}

	public dynamic function onChange( value : String ) { }
	public dynamic function onBlur() {}
	
	var d = 0.0;
	public override function sync(c) {
		super.sync(c);
		d += hxd.Timer.rdeltaT;
		if ( d > 0.1 ) {
			cursorImg.alpha = 1.0 - cursorImg.alpha;
			d = hxd.Math.fumod( d, 0.1 );
		}
	}

	public function isEditing() {
		return cursorImg.visible;
	}
}