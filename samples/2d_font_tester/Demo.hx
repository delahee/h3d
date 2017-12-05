import h2d.Graphics;
import hxd.Stage;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
		
	var fonts : Array<h2d.Font>;
	var editor : h2d.comp.Component;
	
	function new() {
		super();
		
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFF000000;
		engine.init();
		
		//editor = new h2d.
	}
	public var nokia16 : h2d.Font;
	
	var f:flash.text.Font;
	var sb :h2d.SpriteBatch;
	
	function init() {
		h2d.Drawable.DEFAULT_FILTER = false;
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		haxe.Timer.delay(function(){
			nokia16 = hxd.res.FontBuilder.getFont( openfl.Assets.getFont("assets/nokiafc22.ttf").fontName, 16 );
			createDoc(scene);
		},1);
	}
	
	var fontName = "nokia";
	var fontPath = "assets/nokiafc22.ttf";
	
	var fontNames 	= ['nokia','_3572','basis33','Hardpixel','Roboto-Black','Roboto-Regular', 'Haeccity DW','Haeccity DW Bold'];
	var fontPathes 	= [	
		'assets/nokiafc22.ttf', 
		'assets/_3572.ttf', 
		'assets/basis33.ttf', 
		'assets/Hardpixel.OTF', 
		'assets/Roboto-Black.ttf', 
		'assets/Roboto-Regular.ttf', 
		"assets/Haeccity DW.ttf",
		"assets/Haeccity DW Bold.ttf",
	];
	var pos = 0;
	
	
	var iSize 			: h2d.Input;
	var iEdgeAlpha 		: h2d.Input;
	var iEdgeEnabled 	: Bool = true;
	var iEdgeLum 		: h2d.Input;
	var iAA 			: Bool = true;
	
	var defaultLum		= 0.99;
	var defaultA		= 250;
	public function createDoc(p)  {
		var stage : hxd.Stage = hxd.Stage.getInstance();
		var wid = 300;
		var s = new h2d.Sprite(p);
		
		s.x = stage.width - wid;
		s.y = 10;
		
		var mf = new h2d.Flow(s);
		mf.isVertical = true;
		
		var t = new h2d.Text(nokia16, mf, "fontname:" + fontName);
		var i = new h2d.Interactive( t.textWidth, t.textHeight, t);
		i.onClick = function(e){
			pos++;
			if ( pos >= fontNames.length )
				pos = 0;
			fontName = fontNames[pos];
			fontPath = fontPathes[pos];
			t.text = "fontname:" + fontName;
			
		}
		
		{
			var f = new h2d.Flow(mf);
			f.y++;
			f.isVertical = false;
			f.maxWidth = 200;
			new h2d.Text(nokia16, f, "size");
			iSize = new h2d.Input({font:nokia16, txt:"10", width:40}, f);
		}
		
		{
			var f = new h2d.Flow(mf);
			f.y++;
			f.isVertical = false;
			f.maxWidth = 200;
			var t = new h2d.Text(nokia16, f, "antialias : on");
			var i = new h2d.Interactive( t.textWidth, t.textHeight, t);
			i.onClick = function(e){
				iAA = !iAA;
				t.text = "antialias : " + (iAA?"on":"off");
			};
		}
		
		{
			var f = new h2d.Flow(mf);
			f.y++;
			f.isVertical = false;
			f.maxWidth = 200;
			var t = new h2d.Text(nokia16, f, "edge : "+'on');
			var i = new h2d.Interactive( t.textWidth, t.textHeight, t);
			i.onClick = function(e){
				iEdgeEnabled = !iEdgeEnabled;
				t.text = "edge : " + (iEdgeEnabled?"on":"off");
			};
		}
		
		{
			var f = new h2d.Flow(mf);
			f.y++;
			f.isVertical = false;
			f.maxWidth = 200;
			new h2d.Text(nokia16, f, "edge_lum");
			var i = iEdgeLum = new h2d.Input({font:nokia16, txt: Std.string(defaultLum), width:40}, f);
			i.deferValidation = true;
			i.onChange = function(str:String){
				trace("lum:" + str);
			}
		}
		
		{
			var f = new h2d.Flow(mf);
			f.y++;
			f.isVertical = false;
			f.maxWidth = 200;
			new h2d.Text(nokia16, f, "edge_alpha");
			var i = iEdgeAlpha = new h2d.Input({font:nokia16, txt:Std.string(defaultA), width:40}, f);
			i.deferValidation = true;
			i.onChange = function(str:String){
				trace("alpha:" +str);
			}
		}
		
		{
			var t = new h2d.Text( nokia16, mf, "generate" );
			var i = new h2d.Interactive( t.textWidth, t.textHeight, t );
			i.onClick = function(_){
				//trace("OK");
				var opt : hxd.res.FontBuilder.FontBuildOptions = { 
					antiAliasing:iAA, 
					edgify:
						iEdgeEnabled ?{ 
							lum: Std.parseFloat(iEdgeLum.value), 
							a:Std.parseInt(iEdgeAlpha.value) 
						} : null, 
					chars: hxd.Charset.DEFAULT_CHARS + hxd.Charset.CYRILLIC };
				trace(opt);
				var f = hxd.res.FontBuilder.getFont( openfl.Assets.getFont(fontPath).fontName, Std.parseInt(iSize.value),opt);
				var t = new h2d.Text(f, scene, "toto Здравствуйте!");
				t.x = 50;
				t.y =  Math.round(cy);
				t.filter = false;
				t.setScale(3);
				cy += Math.round(t.textHeight * 2 + 2);
				
				if ( cy > stage.height - 50 ){
					cy = 10;
					for ( a in all)
						a.dispose();
					all = [t];
				}
				else 
					all.push(t);
				
			};
		}
		
		
	}
	
	var all = [];
	var cy = 10;
	
	function update() 	{
		
		engine.render(scene);
		engine.restoreOpenfl();
		
		scene.checkEvents();
	}
	
	static function main() {
		new Demo();
	}
}
