package h2d.css;
import h2d.css.Defs;

enum Token {
	TIdent( i : String );
	TString( s : String );
	TInt( i : Int );
	TFloat( f : Float );
	TDblDot;
	TSharp;
	TPOpen;
	TPClose;
	TExclam;
	TComma;
	TEof;
	TPercent;
	TSemicolon;
	TBrOpen;
	TBrClose;
	TDot;
	TSpaces;
	TSlash;
	TStar;
}

enum Value {
	VIdent( i : String );
	VString( s : String );
	VUnit( v : Float, unit : String );
	VFloat( v : Float );
	VInt( v : Int );
	VHex( v : String );
	VList( l : Array<Value> );
	VGroup( l : Array<Value> );
	VCall( f : String, vl : Array<Value> );
	VLabel( v : String, val : Value );
	VSlash;
}

class Parser {
	
	public static var unitConverter : Null < Float -> String -> Float > = null;
	public static var fontResolver = function(name, size:Int ) { };
	public static var tileResolver = function( v : Value ) : TileStyle { return null; };

	var css : String;
	var s : Style;
	var simp : Style;
	var pos : Int;

	var spacesTokens : Bool;
	var tokens : Array<Token>;

	public function new() {
	}
	
	// ----------------- style apply ---------------------------
	#if debug
	function notImplemented( ?pos : haxe.PosInfos ) {
		haxe.Log.trace("Not implemented", pos);
	}
	#else
	inline function notImplemented() {
	}
	#end

	static var DOCK_IDENTS 				= ["top" => Top, "bottom" => Bottom, "left" => Left, "right" => Right, "full" => Full];
	static var REPEAT_IDENTS 			= ["repeat-x" => RepeatX, "repeat-y" => RepeatY, "repeat" => Repeat, "no-repeat" => NoRepeat];
	static var BG_SIZE_IDENTS	 		= ["auto" => Auto, "cover" => Cover, "contain" => Contain,"zoom"=>Zoom];
	static var TEXT_TRANSFORM_IDENTS 	= ["none" => None, "uppercase" => Uppercase, "lowercase" => Lowercase, "capitalize" => Capitalize ];
	static var BLENDMODE_IDENTS 		= ["normal" => h2d.BlendMode.Normal, "add" => h2d.BlendMode.Add, "multiply" => h2d.BlendMode.Multiply, "softOverlay" => h2d.BlendMode.SoftOverlay ];
	static var TEXT_VALIGN_IDENTS 		: Map<String,TextVAlign> = ["top" => Top, "bottom" => Bottom, "middle" => Middle];
	
	public static var LAYOUT_IDENTS = ["horizontal" => Horizontal, "vertical" => Vertical, "absolute" => Absolute, "dock" => Dock, "inline" => Inline];
	public static var LAYOUT_NAMES = {
		var n = new Map();
		for ( id in LAYOUT_IDENTS.keys()) 
			n.set( LAYOUT_IDENTS.get( id ), id );
		n;
	}
	
	function applyStyle( r : String, v : Value, s : Style ) : Bool {
		switch( r ) {
		case "padding":
			switch( v ) {
			case VGroup([a, b]):
				var a = getVal(a), b = getVal(b);
				if( a != null && b != null ) {
					s.paddingTop = s.paddingBottom = a;
					s.paddingLeft = s.paddingRight = b;
					return true;
				}
			default:
				var i = getVal(v);
				if( i != null ) { s.padding(i); return true; }
			}
		case "padding-top":
			var i = getVal(v);
			if( i != null ) { s.paddingTop = i; return true; }
		case "padding-left":
			var i = getVal(v);
			if( i != null ) { s.paddingLeft = i; return true; }
		case "padding-right":
			var i = getVal(v);
			if( i != null ) { s.paddingRight = i; return true; }
		case "padding-bottom":
			var i = getVal(v);
			if( i != null ) { s.paddingBottom = i; return true; }
		case "margin":
			switch( v ) {
			case VGroup([a, b]):
				var a = getVal(a), b = getVal(b);
				if( a != null && b != null ) {
					s.marginTop = s.marginBottom = a;
					s.marginLeft = s.marginRight = b;
					return true;
				}
			default:
				var i = getVal(v);
				if( i != null ) { s.margin(i); return true; }
			}
		case "margin-top":
			var i = getVal(v);
			if( i != null ) { s.marginTop = i; return true; }
		case "margin-left":
			var i = getVal(v);
			if( i != null ) { s.marginLeft = i; return true; }
		case "margin-right":
			var i = getVal(v);
			if( i != null ) { s.marginRight = i; return true; }
		case "margin-bottom":
			var i = getVal(v);
			if( i != null ) { s.marginBottom = i; return true; }
		case "width":
			s.widthIsPercent = false;
			var i = getUnit(v);
			if ( i != null ) {
				switch(i) {
					case Pix(v):s.width = v;
					case Percent(v):
						s.width = v;
						s.widthIsPercent = true;
					default:notImplemented();
				}
				return true;
			}
			if( getIdent(v) == "auto" ) {
				s.width = null;
				s.autoWidth = true;
				return true;
			}
		case "height":
			s.heightIsPercent = false;
			var i = getUnit(v);
			if ( i != null ) {
				switch(i) {
					case Pix(v): s.height = v;
					case Percent(v):
						s.height = v;
						s.heightIsPercent = true;
					default:notImplemented();
				}
				return true;
			}
			if( getIdent(v) == "auto" ) {
				s.height = null;
				s.autoHeight = true;
				return true;
			}
		case "background-color":
			var f = getFill(v);
			if( f != null ) {
				s.backgroundColor = f;
				return true;
			}
		
		case "background-tile","background-image":
			switch(v) {
				case VIdent("none"):
					s.backgroundTile = null;
					return true;
				default:
				var f = getTile(v);
				if ( v != null ) {
					s.backgroundTile = f;
					return true;
				}
			}
		
		case "background-size":
			var i = mapIdent(v, BG_SIZE_IDENTS);
			if( i != null ) {
				s.backgroundSize = i;
				return true;
			}
			else {
				switch( v ) {
					case VGroup([a, b]):
						var ra :Null<Float>;
						var rb :Null<Float>;
						function getPercent( a ) { return
							switch(a) {
								case VUnit(val, "%"):val;
							default:null;
							}
						}
						ra = getPercent(a);
						rb = getPercent(b);
						
						//TODO support if one is a percent and the other is not...
						if ( ra != null && rb != null )
							s.backgroundSize = Percent(ra, rb);
						else {
							ra = getVal(a);
							rb = getVal(b);
							s.backgroundSize = Rect( ra, rb );
						}
						return true;
					default:
				}
			}
		
		case "background-9slice":
			return applyComposite(["background-9slice-tile","background-9slice-rect"], v, s);
			
		case "background-9slice-tile":
			var f = getTile(v);
			if ( v != null ) {
				s.background9sliceTile = f;
				return true;
			}
			
		case "background-9slice-rect":
			switch( v ) {
				case VCall("rect",[left, top, right, down]):
					s.background9sliceRect = new h2d.col.Rect( getVal(left), getVal(top), getVal(right), getVal(down) );
					return true;
				default:
			}
			
		case "background-repeat": 
			var i = mapIdent(v, REPEAT_IDENTS);
			if( i != null ) {
				s.backgroundRepeat = i;
				return true;
			}
			
		case "background-blend": 
			var i = mapIdent(v, BLENDMODE_IDENTS);
			if( i != null ) {
				s.backgroundBlend = i;
				return true;
			}
		
		case "background":
			return applyComposite(["background-color"], v, s);
			
		case "font-family":
			var l = getFontName(v);
			if( l != null ) {
				s.fontName = l;
				return true;
			}
		case "font-size":
			var i = getUnit(v);
			if( i != null ) {
				switch( i ) {
				case Pix(v):
					s.fontSize = v;
				default:
					notImplemented();
				}
				return true;
			}
		case "color":
			var c = getCol(v);
			if( c != null ) {
				s.color = c;
				return true;
			}
			
		case "opacity":
			var f = getVal(v);
			if( f != null ) {
				s.opacity = f;
				return true;
			}
			
		case "border":
			if( applyComposite(["border-width", "border-style", "border-color"], v, s) )
				return true;
			if( getIdent(v) == "none" ) {
				s.borderSize = 0;
				s.borderColor = Transparent;
				return true;
			}
		case "border-width":
			var i = getVal(v);
			if( i != null ) {
				s.borderSize = i;
				return true;
			}
		case "border-style":
			if( getIdent(v) == "solid" )
				return true;
		case "border-color":
			var c = getFill(v);
			if( c != null ) {
				s.borderColor = c;
				return true;
			}
		case "offset":
			return applyComposite(["offset-x", "offset-y"], v, s);
		case "offset-x":
			var i = getVal(v);
			if( i != null ) {
				s.offsetX = i;
				return true;
			}
		case "offset-y":
			var i = getVal(v);
			if( i != null ) {
				s.offsetY = i;
				return true;
			}
		case "layout":
			var i = mapIdent(v, LAYOUT_IDENTS);
			if( i != null ) {
				s.layout = i;
				return true;
			}
			
		case "letter-spacing":
			var i = getVal(v);
			if ( i != null ) {
				s.letterSpacing = Math.round(i);
				return true;
			}
			
		case "line-spacing":
			var i = getVal(v);
			if ( i != null ) {
				s.lineSpacing = Math.round(i);
				return true;
			}
			
		case "spacing":
			return applyComposite(["vertical-spacing", "horizontal-spacing"], v, s);
		case "horizontal-spacing":
			var i = getVal(v);
			if( i != null ) {
				s.horizontalSpacing = i;
				return true;
			}
		case "vertical-spacing":
			var i = getVal(v);
			if( i != null ) {
				s.verticalSpacing = i;
				return true;
			}
		case "increment":
			var i = getVal(v);
			if( i != null ) {
				s.increment = i;
				return true;
			}
		case "max-increment":
			var i = getVal(v);
			if( i != null ) {
				s.maxIncrement = i;
				return true;
			}
		case "tick-color":
			var i = getFill(v);
			if( i != null ) {
				s.tickColor = i;
				return true;
			}
		case "tick-spacing":
			var i = getVal(v);
			if( i != null ) {
				s.tickSpacing = i;
				return true;
			}
		case "dock":
			var i = mapIdent(v, DOCK_IDENTS);
			if( i != null ) {
				s.dock = i;
				return true;
			}
		case "cursor-color":
			var i = getColAlpha(v);
			if( i != null ) {
				s.cursorColor = i;
				return true;
			}
		case "selection-color":
			var i = getColAlpha(v);
			if( i != null ) {
				s.selectionColor = i;
				return true;
			}
		case "overflow":
			switch( getIdent(v) ) {
			case "hidden":
				s.overflowHidden = true;
				return true;
			case "visible":
				s.overflowHidden = false;
				return true;
			}
		case "icon":
			var i = getImage(v);
			if( i != null ) {
				s.icon = i;
				return true;
			}
		case "icon-color":
			var c = getColAlpha(v);
			if( c != null ) {
				s.iconColor = c;
				return true;
			}
		case "icon-left":
			var i = getVal(v);
			if( i != null ) {
				s.iconLeft = i;
				return true;
			}
		case "icon-top":
			var i = getVal(v);
			if( i != null ) {
				s.iconTop = i;
				return true;
			}
		case "position":
			switch( getIdent(v) ) {
			case "absolute":
				s.positionAbsolute = true;
				return true;
			case "relative":
				s.positionAbsolute = false;
				return true;
			default:
			}
		case "text-align":
			switch( getIdent(v) ) {
			case "left":
				s.textAlign = Left;
				return true;
			case "right":
				s.textAlign = Right;
				return true;
			case "center":
				s.textAlign = Center;
				return true;
			default:
			}
		case "text-valign":
			var i = mapIdent(v, TEXT_VALIGN_IDENTS);
			if( i != null ) {
				s.textVAlign = i;
				return true;
			}
		case "text-position":
			return applyComposite(["text-position-x", "text-position-y"], v, s);
			
		case "text-position-x":
			var i = getVal(v);
			if( i != null ) {
				s.textPositionX = i;
				return true;
			}
			
		case "text-position-y":
			var i = getVal(v);
			if( i != null ) {
				s.textPositionY = i;
				return true;
			}
		
		case "text-transform":
			var i = mapIdent(v, TEXT_TRANSFORM_IDENTS);
			if( i != null ) {
				s.textTransform = i;
				return true;
			}
			
		case "text-shadow":
			s.textShadow = { dx:0, dy:0, color:0, alpha:1 };
			return applyComposite(["text-shadow-x", "text-shadow-y", "text-shadow-color"], v, s);
			
		case "text-shadow-x":
			var i = getVal(v);
			if( i != null ) {
				s.textShadow.dx = i;
				return true;
			}
			
		case "text-shadow-y":
			var i = getVal(v);
			if( i != null ) {
				s.textShadow.dy = i;
				return true;
			}
			
		case "text-shadow-color":
			var c = getColAlpha(v);
			if( c != null ) {
				s.textShadow.color = (c & 0x00ffffff);
				s.textShadow.alpha = hxd.Math.b2f(c >>> 24);
				return true;
			}
			
		case "transform":
			function match(a:h2d.css.Value) : Transform {
				return 
					switch(a) {
						case VCall( "rotate", [VFloat(val)]): 
							Rotate(val);
							
						case VCall( "translate", [VFloat(v0),VFloat(v1)]): 
							Translate( v0, v1);
							
						case VCall( "translateRatio", [VFloat(v0),VFloat(v1)]): 
							TranslateRatio( v0, v1 );
							
						case VCall( "scale", [VFloat(val)]): 
							Scale(val,val);
							
						default:
							Scale(1.0,1.0);
					};
			};
			
			var arr :Array<Transform> = [];
			switch(v) {
				case VCall(_,_):
					arr.push( match(v) );
				case VGroup(a):
					for ( e in a ) 
						arr.push( match(e) );
				case VIdent("none"):
				default:
					return false;
			}
			s.transform = arr;
			return true;
			
		case "background-color-transform","text-color-transform":
			var d = 1.0 / 255.0;
			
			function match(a) {
				return
				switch( a  ) {
					case VCall( "brightness", 	[VFloat(val)]):	Brightness(val * d);
					case VCall( "brightness", 	[VInt(val)]):	Brightness(val * d);
					
					case VCall( "contrast", 	[VFloat(val)]):	Contrast(val * d);
					case VCall( "contrast", 	[VInt(val)]):	Contrast(val * d);
					
					case VCall( "saturation", 	[VFloat(val)]): Saturation(1.0 + val * d);
					case VCall( "saturation", 	[VInt(val)]): 	Saturation(1.0 + val * d);
					
					case VCall( "hue", 			[VFloat(val)]): Hue(val * hxd.Math.DEGTORAD);
					case VCall( "hue", 			[VInt(val)]): 	Hue(val * hxd.Math.DEGTORAD);
					
					default: 
					#if debug 
					throw "css.textColorTransform : invalid value literal" + a;
					#end
					null;
				}
			}
			
			var args = null;
			switch(v) {
				case VCall(_,_):
					args = [match(v)];
				case VGroup(arr):
					args = arr.map(match);
				case VIdent("none"):
					args = null;
					return true;
				default:
					
			}
			
			if( args!=null){
				if ( r == "text-color-transform") 
					s.textColorTransform = args;
				else 
					s.backgroundColorTransform = args;
				return true;
			}
		
		case "visibility":
			switch( getIdent(v) ) {
				case "hidden": s.visibility = false; return true;
				case "visible" : s.visibility = true; return true;
			}
			
		case "display":
			switch( getIdent(v) ) {
			case "none":
				s.display = false;
				return true;
			case "block", "inline-block":
				s.display = true;
				return true;
			default:
			}
		default:
			throw "Not implemented '"+r+"' = "+valueStr(v);
		}
		return false;
	}

	function applyComposite( names : Array<String>, v : Value, s : Style ) {
		var vl = switch( v ) {
		case VGroup(l): l;
		default: [v];
		};
		while( vl.length > 0 ) {
			var found = false;
			for( n in names ) {
				var count = 1;
				if( count > vl.length ) count = vl.length;
				while( count > 0 ) {
					var v = (count == 1) ? vl[0] : VGroup(vl.slice(0, count));
					if( applyStyle(n, v, s) ) {
						found = true;
						names.remove(n);
						for( i in 0...count )
							vl.shift();
						break;
					}
					count--;
				}
				if( found ) break;
			}
			if( !found )
				return false;
		}
		return true;
	}

	function getGroup<T>( v : Value, f : Value -> Null<T> ) : Null<Array<T>> {
		switch(v) {
		case VGroup(l):
			var a = [];
			for( v in l ) {
				var v = f(v);
				if( v == null ) return null;
				a.push(v);
			}
			return a;
		default:
			var v = f(v);
			return (v == null) ? null : [v];
		}
	}

	function getList<T>( v : Value, f : Value -> Null<T> ) : Null<Array<T>> {
		switch(v) {
		case VList(l):
			var a = [];
			for( v in l ) {
				var v = f(v);
				if( v == null ) return null;
				a.push(v);
			}
			return a;
		default:
			var v = f(v);
			return (v == null) ? null : [v];
		}
	}

	function getInt( v : Value ) : Null<Int> {
		return switch( v ) {
		case VUnit(f, u):
			if ( unitConverter != null )
				Std.int(unitConverter(f, u));
			else
				switch( u ) {
				case "px": Std.int(f);
				case "pt": Std.int(f * 4 / 3);
				default: null;
				}
		case VInt(v):
			Std.int(v);
		default:
			null;
		};
	}

	function getVal( v : Value ) : Null<Float> {
		return switch( v ) {
		case VUnit(f, u):
			if ( unitConverter != null )
				unitConverter(f, u);
			else
				switch( u ) {
				case "px": f;
				case "pt": f * 4 / 3;
				default: null;
				}
		case VInt(v):
			v;
		case VFloat(v):
			v;
		default:
			null;
		};
	}

	function getUnit( v : Value ) : Null<Unit> {
		return switch( v ) {
		case VUnit(f, u):
			switch( u ) {
				case "px": Pix(f);
				case "pt": Pix(f * 4 / 3);
				case "%": Percent(f / 100);
				default: 
					if ( unitConverter != null )
						Pix( unitConverter( f, u ) );
					else 
						throw "unhandled unit " + v;
			}
		case VInt(v):
			Pix(v);
		case VFloat(v):
			Pix(v);
		default:
			null;
		};
	}
	
	function mapIdent<T:EnumValue>( v : Value, vals : haxe.ds.StringMap<T> ) : T {
		var i = getIdent(v);
		if ( i == null ) return null;
		return vals.get( i );
	}

	function getIdent( v : Value ) : Null<String> {
		return switch( v ) {
		case VIdent(v): v;
		default: null;
		};
	}

	function getColAlpha( v : Value ) {
		var c = getCol(v);
		if( c != null && (c >>> 24) == 0 )
			c |= 0xFF000000;
		return c;
	}
	
	
	function getTile( v : Value) {
		
		function make(path, ?x, ?y, ?w, ?h, ?dx, ?dy) {
			var t = new TileStyle();
			t.mode = Assets;
			
			if ( path == null )
				throw "err getTile";
				
			t.file = path;
			t.x = x==null?0:getVal(x);
			t.y = y==null?0:getVal(y);
			
			if ( w == null ) {
				t.w = 100;
				t.widthAsPercent = true;
			}
			else 
			switch(w) {
				
				default:
					t.w = getVal(w);
				case VUnit( f, "%" ): 
					t.w = f;
					t.widthAsPercent = true;
			}
			
			if ( h == null ) {
				t.h = 100;
				t.heightAsPercent = true;
			}
			else 
			switch(h) {
				default: 
					t.h = getVal(h);
				case VUnit( f, "%" ): 
					t.h = f; t.heightAsPercent = true;
			}
			
			if( dx != null)	t.dx = getVal(dx);
			if( dy != null)	t.dy = getVal(dy);
			return t;
		}
		
		return 
		switch( v ) {
			case VCall( "tile", params=[VCall( "asset",[VString(str)])]):	
				make(str, params[1],params[2],params[3],params[4], params[5], params[6]);
				
			case VCall( "tile", params=[VCall( "asset",[VString(str)]),x,y,w,h]):	
				make(str, x, y, w, h, params[5], params[6]);
		
			case VCall( name, params ):
				Parser.tileResolver(v);
				
			default: 
				
				return null;
		}
	}

	function getFill( v : Value ) {
		var c = getColAlpha(v);
		if( c != null )
			return Color(c);
		switch( v ) {
		case VCall("gradient", [a, b, c, d]):
			var ca = getColAlpha(a);
			var cb = getColAlpha(b);
			var cc = getColAlpha(c);
			var cd = getColAlpha(d);
			if( ca != null && cb != null && cc != null && cd != null )
				return Gradient(ca, cb, cc, cd);
		case VIdent("transparent"):
			return Transparent;
		default:
		}
		return null;
	}

	function getCol( v : Value ) : Null<Int> {
		return switch( v ) {
		case VHex(v):
			(v.length == 6) ? Std.parseInt("0x" + v) : ((v.length == 3) ? Std.parseInt("0x"+v.charAt(0)+v.charAt(0)+v.charAt(1)+v.charAt(1)+v.charAt(2)+v.charAt(2)) : null);
		case VIdent(i):
			switch( i ) {
			case "black":	0x000000;
			case "red": 	0xFF0000;
			case "lime":	0x00FF00;
			case "blue":	0x0000FF;
			case "white":	0xFFFFFF;
			case "aqua":	0x00FFFF;
			case "fuchsia":	0xFF00FF;
			case "yellow":	0xFFFF00;
			case "maroon":	0x800000;
			case "green":	0x008000;
			case "navy":	0x000080;
			case "olive":	0x808000;
			case "purple": 	0x800080;
			case "teal":	0x008080;
			case "silver":	0xC0C0C0;
			case "deeppink":0xFF1493;
			case "pink":	0xFFC0CB;
			
			case "darkorange": 0xFF8C00;
			case "orangered":	0xFF4500;
			case "orange":		0xFFA500;
			
			case "gray", "grey": 0x808080;
			default: null;
			}
		case VCall("rgba", [r, g, b, a]):
			var r = getVal(r), g = getVal(g), b = getVal(b), a = getVal(a);
			inline function conv(k:Float) {
				var v = Std.int(k * 255);
				if( v < 0 ) v = 0;
				if( v > 255 ) v = 255;
				return v;
			}
			if( r != null && g != null && b != null && a != null ) {
				var a = conv(a); if( a == 0 ) a = 1; // prevent setting alpha to FF afterwards
				(a << 24) | (conv(r) << 16) | (conv(g) << 8) | conv(b);
			}
			else
				null;
		default:
			null;
		};
	}

	function getFontName( v : Value ) {
		return switch( v ) {
		case VString(s): s;
		case VGroup(_):
			var g = getGroup(v, getIdent);
			if( g == null ) null else g.join(" ");
		case VIdent(i): i;
		default: null;
		};
	}
	
	function getImage( v : Value ) {
		switch( v ) {
		case VCall("url", [VString(url)]):
			if( !StringTools.startsWith(url, "data:image/png;base64,") )
				return null;
			url = url.substr(22);
			if( StringTools.endsWith(url, "=") ) url = url.substr(0, -1);
			var bytes = haxe.crypto.Base64.decode(url);
			return hxd.res.Any.fromBytes("icon",bytes).toImage().getPixels();
		default:
			return null;
		}
	}

	// ---------------------- generic parsing --------------------

	function unexpected( t : Token ) : Dynamic {
		throw "Unexpected " + Std.string(t);
		return null;
	}

	function expect( t : Token ) {
		var tk = readToken();
		if( tk != t ) unexpected(tk);
	}

	inline function push( t : Token ) {
		tokens.push(t);
	}

	function isToken(t) {
		var tk = readToken();
		if( tk == t ) return true;
		push(tk);
		return false;
	}

	public function parse( css : String, s : Style ) {
		this.css = css;
		this.s = s;
		pos = 0;
		tokens = [];
		parseStyle(TEof);
	}

	function valueStr(v) {
		return switch( v ) {
		case VIdent(i): i;
		case VString(s): '"' + s + '"';
		case VUnit(f, unit): f + unit;
		case VFloat(f): Std.string(f);
		case VInt(v): Std.string(v);
		case VHex(v): "#" + v;
		case VList(l):
			[for( v in l ) valueStr(v)].join(", ");
		case VGroup(l):
			[for( v in l ) valueStr(v)].join(" ");
		case VCall(f,args): f+"(" + [for( v in args ) valueStr(v)].join(", ") + ")";
		case VLabel(label, v): valueStr(v) + " !" + label;
		case VSlash: "/";
		}
	}

	function parseStyle( eof ) {
		while( true ) {
			if( isToken(eof) )
				break;
			var r = readIdent();
			expect(TDblDot);
			var v = readValue();
			var s = this.s;
			switch( v ) {
			case VLabel(label, val):
				if( label == "important" ) {
					v = val;
					if( simp == null ) simp = new Style();
					s = simp;
				}
			default:
			}
			if( !applyStyle(r, v, s) )
				throw "Invalid value " + valueStr(v) + " for css " + r;
			if( isToken(eof) )
				break;
			expect(TSemicolon);
		}
	}

	public function parseRules( css : String ) {
		this.css = css;
		pos = 0;
		tokens = [];
		var rules = [];
		while( true ) {
			if( isToken(TEof) )
				break;
			var classes = readClasses();
			expect(TBrOpen);
			this.s = new Style();
			this.simp = null;
			parseStyle(TBrClose);
			for( c in classes )
				rules.push( { c : c, s : s, imp : false } );
			if( this.simp != null )
				for( c in classes )
					rules.push( { c : c, s : simp, imp : true } );
		}
		return rules;
	}
	
	public function parseClasses( css : String ) {
		this.css = css;
		pos = 0;
		tokens = [];
		var c = readClasses();
		expect(TEof);
		return c;
	}

	// ----------------- class parser ---------------------------

	function readClasses() {
		var classes = [];
		while( true ) {
			spacesTokens = true;
			isToken(TSpaces); // skip
			var c = readClass(null);
			spacesTokens = false;
			if( c == null ) break;
			updateClass(c);
			classes.push(c);
			if( !isToken(TComma) )
				break;
		}
		if( classes.length == 0 )
			unexpected(readToken());
		return classes;
	}
	
	function updateClass( c : CssClass ) {
		// map html types to comp ones
		switch( c.node ) {
		case "div": c.node = "box";
		case "img":
			c.pseudoClass = c.node;
			c.node = "box";
		case "span", "em", "strong": 
			c.pseudoClass = c.node;
			c.node = "label";
		case "h1", "h2", "h3", "h4":
			c.pseudoClass = c.node;
			c.node = "label";
		}
		if( c.parent != null ) updateClass(c.parent);
	}
	
	function readClass( parent ) : CssClass {
		var c = new CssClass();
		c.parent = parent;
		var def = false;
		var last = null;
		while( true ) {
			var t = readToken();
			if( last == null )
				switch( t ) {
				case TStar: def = true;
				case TDot, TSharp, TDblDot: last = t;
				case TIdent(i): c.node = i; def = true;
				case TSpaces:
					return def ? readClass(c) : null;
				case TBrOpen, TComma, TEof:
					push(t);
					break;
					
				default:
					unexpected(t);
				}
			else
				switch( t ) {
				case TIdent(i):
					switch( last ) {
					case TDot: c.className = i; def = true;
					case TSharp: c.id = i; def = true;
					case TDblDot: c.pseudoClass = i; def = true;
					default: throw "assert";
					}
					last = null;
				default:
					unexpected(t);
				}
		}
		return def ? c : parent;
	}

	// ----------------- value parser ---------------------------

	function readIdent() {
		var t = readToken();
		return switch( t ) {
		case TIdent(i): i;
		default: unexpected(t);
		}
	}

	function readValue(?opt)  : Value {
		var t = readToken();
		var v = switch( t ) {
		case TSharp:
			VHex(readHex());
		case TIdent(i):
			VIdent(i);
		case TString(s):
			VString(s);
		case TInt(i):
			readValueUnit(i, i);
		case TFloat(f):
			readValueUnit(f, null);
		case TSlash:
			VSlash;
		default:
			if( !opt ) unexpected(t);
			push(t);
			null;
		};
		if( v != null ) v = readValueNext(v);
		return v;
	}

	function readHex() {
		var start = pos;
		while( true ) {
			var c = next();
			if( (c >= "A".code && c <= "F".code) || (c >= "a".code && c <= "f".code) || (c >= "0".code && c <= "9".code) )
				continue;
			pos--;
			break;
		}
		return css.substr(start, pos - start);
	}

	function readValueUnit( f : Float, ?i : Int ) {
		var t = readToken();
		return switch( t ) {
		case TIdent(i):
			VUnit(f, i);
		case TPercent:
			VUnit(f, "%");
		default:
			push(t);
			if( i != null )
				VInt(i);
			else
				VFloat(f);
		};
	}

	function readValueNext( v : Value ) : Value {
		var t = readToken();
		return switch( t ) {
		case TPOpen:
			switch( v ) {
			case VIdent(i):
				switch( i ) {
				case "url":
					readValueNext(VCall("url",[VString(readUrl())]));
				default:
					var args = switch( readValue() ) {
					case VList(l): l;
					case x: [x];
					}
					expect(TPClose);
					readValueNext(VCall(i, args));
				}
			default:
				push(t);
				v;
			}
		case TExclam:
			var t = readToken();
			switch( t ) {
			case TIdent(i):
				VLabel(i, v);
			default:
				unexpected(t);
			}
		case TComma:
			loopComma(v, readValue());
		default:
			push(t);
			var v2 = readValue(true);
			if( v2 == null )
				v;
			else
				loopNext(v, v2);
		}
	}

	function loopNext(v, v2) {
		return switch( v2 ) {
		case VGroup(l):
			l.unshift(v);
			v2;
		case VList(l):
			l[0] = loopNext(v, l[0]);
			v2;
		case VLabel(lab, v2):
			VLabel(lab, loopNext(v, v2));
		default:
			VGroup([v, v2]);
		};
	}

	function loopComma(v,v2) {
		return switch( v2 ) {
		case VList(l):
			l.unshift(v);
			v2;
		case VLabel(lab, v2):
			VLabel(lab, loopComma(v, v2));
		default:
			VList([v, v2]);
		};
	}

	// ----------------- lexer -----------------------

	inline function isSpace(c) {
		return (c == " ".code || c == "\n".code || c == "\r".code || c == "\t".code);
	}

	inline function isLine(c) {
		return (c == "\n".code);
	}
	
	inline function isIdentChar(c) {
		return (c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || (c == "-".code) || (c == "_".code);
	}

	inline function isNum(c) {
		return c >= "0".code && c <= "9".code;
	}

	inline function next() {
		return StringTools.fastCodeAt(css, pos++);
	}

	function readUrl() {
		var c0 = next();
		while( isSpace(c0) )
			c0 = next();
		var quote = c0;
		if( quote == "'".code || quote == '"'.code ) {
			pos--;
			switch( readToken() ) {
			case TString(s):
				var c0 = next();
				while( isSpace(c0) )
					c0 = next();
				if( c0 != ")".code )
					throw "Invalid char " + String.fromCharCode(c0);
				return s;
			default: throw "assert";
			}

		}
		var start = pos - 1;
		while( true ) {
			if( StringTools.isEof(c0) )
				break;
			c0 = next();
			if( c0 == ")".code ) break;
		}
		return StringTools.trim(css.substr(start, pos - start - 1));
	}

	#if false
	function readToken( ?pos : haxe.PosInfos ) {
		var t = _readToken();
		haxe.Log.trace(t, pos);
		return t;
	}

	function _readToken() {
	#else
	function readToken() {
	#end
		var t = tokens.pop();
		if( t != null )
			return t;
		while( true ) {
			var c = next();
			if( StringTools.isEof(c) )
				return TEof;
			if( isSpace(c) ) {
				if( spacesTokens ) {
					while( isSpace(next()) ) {
					}
					pos--;
					return TSpaces;
				}

				continue;
			}
			if( isNum(c) || c == '-'.code ) {
				var i = 0, neg = false;
				if( c == '-'.code ) { c = "0".code; neg = true; }
				do {
					i = i * 10 + (c - "0".code);
					c = next();
				} while( isNum(c) );
				if( c == ".".code ) {
					var f : Float = i;
					var k = 0.1;
					while( isNum(c = next()) ) {
						f += (c - "0".code) * k;
						k *= 0.1;
					}
					pos--;
					return TFloat(neg? -f : f);
				}
				pos--;
				return TInt(neg ? -i : i);
			}
			if( isIdentChar(c) ) {
				var pos = pos - 1;
				do c = next() while( isIdentChar(c) || isNum(c) );
				this.pos--;
				return TIdent(css.substr(pos,this.pos - pos));
			}
			switch( c ) {
			case ":".code: return TDblDot;
			case "#".code: return TSharp;
			case "(".code: return TPOpen;
			case ")".code: return TPClose;
			case "!".code: return TExclam;
			case "%".code: return TPercent;
			case ";".code: return TSemicolon;
			case ".".code: return TDot;
			case "{".code: return TBrOpen;
			case "}".code: return TBrClose;
			case ",".code: return TComma;
			case "*".code: return TStar;
			case "/".code:
				var n = c = next();
				var isNextStar = n == '*'.code;
				var isNextSlash = n == '/'.code;
				if( !isNextStar && !isNextSlash ) {
					pos--;
					return TSlash;
				}
				
				if( isNextSlash ) {
					while ( true ) {
						c = next();
						if ( isLine(c) )
							break;
						if( StringTools.isEof(c) )
							return TEof;
					}
					return readToken();
				}
				else {//implicit isNextStar
					while( true ) {
						while( (c = next()) != '*'.code ) {
							if( StringTools.isEof(c) )
								throw "Unclosed comment";
						}
						c = next();
						if( c == "/".code ) break;
						if( StringTools.isEof(c) )
							throw "Unclosed comment";
					}
				}
				return readToken();
			case "'".code, '"'.code:
				var pos = pos;
				var k;
				while( (k = next()) != c ) {
					if( StringTools.isEof(k) )
						throw "Unclosed string constant";
					if( k == "\\".code ) {
						throw "todo";
						continue;
					}
				}
				return TString(css.substr(pos, this.pos - pos - 1));
			default:
			}
			pos--;
			throw "Invalid char " + css.charAt(pos);
		}
		return null;
	}

}