import h2d.Graphics;
import hxd.Stage;


class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	
	function new() {
		super();
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFaaaaaa;
		engine.init();
		
	}
	
	function init() {
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		
		var b = new h2d.Bitmap(h2d.Tile.fromAssets("assets/carPlay1.png"),scene );
		b.x = 100;
		b.y = 200;
		b.isBlurredG3T = true;
		b.blurRadius = 2.5;
		
		var b = new h2d.Bitmap(h2d.Tile.fromAssets("assets/carPlay1.png"),scene );
		b.x = 100;
		b.y = 100;
		b.isBlurredG3T = true;
		b.color = new h3d.Vector(0, 0, 0, 1);
		b.colorAdd = new h3d.Vector(1, 0, 0, 0);
		b.blurRadius = 2.5;
		
		var b = new h2d.Bitmap(h2d.Tile.fromAssets("assets/carPlay1.png"),scene );
		b.x = 100;
		b.y = 100;
		
		var b = new h2d.Bitmap(h2d.Tile.fromAssets("assets/carPlay1.png"),scene );
		b.x = 300;
		b.y = 200;
		b.isBlurredG3x3T = true;
		b.blurRadius = 2.5;
		
		var b = new h2d.Bitmap(h2d.Tile.fromAssets("assets/carPlay1.png"),scene );
		b.x = 300;
		b.y = 100;
		b.isBlurredG3x3T = true;
		b.blurRadius = 2.5;
		b.color = new h3d.Vector(0, 0, 0, 1);
		b.colorAdd = new h3d.Vector(1, 0, 0, 0);
		
		var b = new h2d.Bitmap(h2d.Tile.fromAssets("assets/carPlay1.png"),scene );
		b.x = 300;
		b.y = 100;
		
		var fname = openfl.Assets.getFont("assets/Big Brother.ttf").fontName;
		var fnt = hxd.res.FontBuilder.getFont( fname, 60 );
		
		var tt : h2d.Text = new h2d.Text(fnt, scene,"SAPIN!");
		tt.x = 600; 
		tt.y = 100;
		tt.isBlurredG3x3T = true;
		tt.blurRadius = 2.5;
		tt.textColor = 0x0;
		
		var t = new h2d.Text(fnt, scene,"SAPIN!");
		t.x = 600;
		t.y = 100;
		t.textColor = 0xcdcdcd;
		
		var t = new h2d.Text(fnt, scene,"SAPIN!");
		t.x = 600;
		t.y = 200;
		t.isBlurredG3x3T = true;
		t.blurRadius = 2.5;
		t.textColor = 0xcdcdcd;
		
		var fname = openfl.Assets.getFont("assets/Big Brother.ttf").fontName;
		var f = new flash.filters.BlurFilter(8, 8);
		var bfnt = hxd.res.FontBuilder.getFont( fname, 60, { antiAliasing:true, filters:[f] } );
		
		var t = new h2d.Text(bfnt, scene,"SAPIN! ");
		t.x = 600;
		t.y = 300;
		t.textColor = 0x0;
		
		var t = new h2d.Text(fnt, scene,"SAPIN!");
		t.x = 600;
		t.y = 300;
		t.textColor = 0xcdcdcd;
		
		var b = new h2d.CachedBitmap( scene);
		var t = new h2d.Text(fnt, b,"SAPIN! -CB");
		t.x = 800;
		t.y = 100;
		t.textColor = 0x0;
		b.isBlurredG3x3T = true;
		b.blurRadius = 2.5;
		
		var t = new h2d.Text(fnt, scene,"SAPIN! -CB");
		t.x = 800;
		t.y = 100;
		t.textColor = 0xcdcdcd;
		
		//var b = new h2d.BlurredBitmap( scene, h2d.BlurredBitmap.BlurMethod.Gaussian7x1TwoPass);
		var b = new h2d.BlurredBitmap( scene, h2d.BlurredBitmap.BlurMethod.Gaussian3x3OnePass);
		//var b = new h2d.BlurredBitmap( scene, h2d.BlurredBitmap.BlurMethod.Scale(2,true));
		var t = new h2d.Text(fnt, b,"SAPIN! -BB");
		t.x = 800;
		t.y = 400;
		t.textColor = 0x0;
		
		var t = new h2d.Text(fnt, scene,"SAPIN! -BB");
		t.x = 800;
		t.y = 400;
		t.textColor = 0xcdcdcd;
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
