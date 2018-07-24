import h2d.Graphics;
import hxd.Stage;

#if false
@:font("assets/OpenSans-Bold.ttf")
class OpenSansBold extends flash.text.Font{
	
}

@:font("assets/OpenSans-ExtraBold.ttf")
class OpenSansBoldExtra extends flash.text.Font{
	
}

@:font("assets/soupofjustice.ttf")
class Soup extends flash.text.Font{
	
}
#end


class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	
	function new() {
		super();
		hxd.System.debugLevel = 1;

		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
	}
	
	function init() {
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		var g = new h2d.Graphics(scene);
		g.beginFill(0x00FFFF,0.5);
		g.lineStyle(2.0);
		g.drawRect( 0, 0, 50, 50);
		g.endFill();
		
		
		//var font = com.furusystems.bmfont.Reader.read( openfl.Assets.getText("assets/arial_16.fnt") );
		var font = hxd.fmt.fnt.Reader.read( openfl.Assets.getText("assets/chopin.fnt") );
		var b = new hxd.res.BMFont( font, function(str) return h2d.Tile.fromAssets( "assets/" + str) );
		
		var t = new h2d.Text( b.nativeFont, scene );
		t.x = 100;
		t.y = 100;
		//t.color = h3d.Vector.fromColor(0xff00FF00);
		t.text = "Je NE suis pas la.je suis à poil\nMOURREZZZ";
		t.setScale( 3 );
		t.filter = false;
		
		
		var bmp : h2d.Bitmap = new h2d.Bitmap( b.pageTextures[0], scene);
		bmp.x = 100;
		bmp.y = 140;
		
		
		var a = 0;
		
		for( f in flash.text.Font.enumerateFonts() ) {
			trace( f.fontName );
		}
		
		#if false
		flash.text.Font.registerFont(OpenSansBold);
		flash.text.Font.registerFont(OpenSansBoldExtra);
		var f = new OpenSansBold();
		var fe = new OpenSansBoldExtra();
		var fs = new Soup();
		#else
		var f = openfl.Assets.getFont("assets/OpenSans-Bold.ttf");
		var fe = openfl.Assets.getFont("assets/OpenSans-ExtraBold.ttf");
		var fs = openfl.Assets.getFont("assets/soupofjustice.ttf");
		var fa = openfl.Assets.getFont("assets/ariblk.ttf");
		#end
		
		var sz = 71;
		var text = "Sapinator LUDUM P";
		var t = new flash.text.TextField(); 
		var tfmt = new flash.text.TextFormat(f.fontName,sz);
		t.defaultTextFormat = tfmt;
		t.x = 100; 
		t.y = 100;
		t.text = text;
		t.width = t.textWidth + 5;  
		t.height = t.textHeight + 5;  
		t.embedFonts = true;
		flash.Lib.current.addChild(t);
		
		var t = new flash.text.TextField(); 
		var tfmt = new flash.text.TextFormat(fe.fontName,sz);
		t.defaultTextFormat = tfmt;
		t.x = 100; 
		t.y = 175;
		t.text = text;
		t.width = t.textWidth + 5;  
		t.height = t.textHeight + 5;  
		t.embedFonts = true;
		flash.Lib.current.addChild(t);
		
		var t = new flash.text.TextField(); 
		var tfmt = new flash.text.TextFormat(fs.fontName,sz);
		t.defaultTextFormat = tfmt;
		t.x = 100; 
		t.y = 250;
		t.text = text;
		t.width = t.textWidth + 5;  
		t.height = t.textHeight + 5;  
		t.embedFonts = true;
		flash.Lib.current.addChild(t);
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(f.fontName, sz), scene );
		t.x = 100;
		t.y = 350;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(fe.fontName, sz), scene );
		t.x = 100;
		t.y = 450;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(fs.fontName, sz), scene );
		t.x = 100;
		t.y = 550;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(fa.fontName, sz), scene );
		t.x = 100;
		t.y = 625;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(f.fontName, 12), scene );
		t.x = 100;
		t.y = 10;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(fe.fontName, 12), scene );
		t.x = 100;
		t.y = 25;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(fs.fontName, 12), scene );
		t.x = 100;
		t.y = 50;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		var t = new h2d.Text( hxd.res.FontBuilder.getFont(fa.fontName, 12), scene );
		t.x = 100;
		t.y = 60;
		t.color = h3d.Vector.fromColor(0xff000000);
		t.text = text;
		
		
		
		var a = 0;
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
