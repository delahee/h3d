package h2d.comp;
import hxd.Key;

@:access(h2d.comp.Input.scene)
class Input extends Interactive {
	
	var tf : h2d.Text;
	var cursorImg : h2d.Bitmap;
	var cursorPos(default,set) : Int;
	public var deferValidation = false;
	public var value(default, set) : String;
	
	public function new(?parent) {
		super("input",parent);
		tf = new h2d.Text(null, this);
		input.cursor = TextInput;
		cursorImg = new h2d.Bitmap(Tools.getWhiteTile(), bgFill);
		cursorImg.visible = false;
		input.onFocus = function(_) {
			addClass(":focus");
			cursorImg.visible = true;
			#if (openfl && cpp)
			flash.Lib.current.requestSoftKeyboard();
			#end
			onFocus();
		};
		input.onFocusLost = function(_) {
			removeClass(":focus");
			cursorImg.visible = false;
			//TODO
			//#if (openfl && cpp)
			//flash.Lib.current.__dismissSoftKeyboard();
			//#end
			onBlur();
		};
		input.onKeyDown = function(e:hxd.Event) {
			if( input.hasFocus() ) {
				// BACK
				switch( e.keyCode ) {
				case Key.LEFT:
					if( cursorPos > 0 )
						cursorPos--;
				case Key.RIGHT:
					if( cursorPos < value.length )
						cursorPos++;
				case Key.HOME:
					cursorPos = 0;
				case Key.END:
					cursorPos = value.length;
				case Key.DELETE:
					value = value.substr(0, cursorPos) + value.substr(cursorPos + 1);
					if(!deferValidation) onChange(value);
					return;
				case Key.BACKSPACE:
					if( cursorPos > 0 ) {
						value = value.substr(0, cursorPos - 1) + value.substr(cursorPos);
						cursorPos--;
						if(!deferValidation) onChange(value);
					}
					return;
				case Key.ENTER:
					if ( deferValidation )
						onChange(value);
					input.blur();
					return;
				}
				if( e.charCode != 0 ) {
					value = value.substr(0, cursorPos) + String.fromCharCode(e.charCode) + value.substr(cursorPos);
					cursorPos++;
					if(!deferValidation) onChange(value);
				}
			}
			return;
		};
		this.value = "";
	}
	
	function set_cursorPos(v:Int) {
		processText(tf);
		cursorImg.x = tf.x + tf.calcTextWidth(value.substr(0, v)) + extLeft();
		if( cursorImg.x > width - 4 ) {
			var dx = cursorImg.x - (width - 4);
			tf.x -= dx;
			cursorImg.x -= dx;
		}
		return cursorPos = v;
	}

	public function focus() {
		input.focus();
		cursorPos = value.length;
	}
	
	function get_value() {
		return tf.text;
	}
	
	function set_value(t) {
		if (t == null) t = "";
		needRebuild = true;
		return value = t;
	}
	
	override function resize( ctx : Context ) {
		if( ctx.measure ) {
			textResize( tf, value, ctx );
			processText(tf);
			if( cursorPos < 0 ) cursorPos = 0;
			if( cursorPos > value.length ) cursorPos = value.length;
		}
		super.resize(ctx);
		if( !ctx.measure ) {
			cursorImg.y = extTop() - 1;
			cursorImg.width = 1;
			cursorImg.scaleY = Std.int(height - extTop() - extBottom() + 2) / cursorImg.tile.height;
			cursorImg.color = h3d.Vector.fromColor(style.cursorColor);
		}
	}

	override function onClick() {
		focus();
	}

	public dynamic function onChange( value : String ) {
	}

	public dynamic function onFocus() {
	}
	
	public dynamic function onBlur() {
	}
	
}
