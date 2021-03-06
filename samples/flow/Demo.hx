import h2d.Graphics;
import hxd.Stage;


class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	
	function new() {
		super();
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
		
		
		var g = new h2d.Graphics(scene);
		g.beginFill();
		g.addPointFull( 100, 100, 1, 0, 0, 1 );
		g.addPointFull( 200, 100, 0, 1, 0, 0 );
		g.addPointFull( 200, 200, 1, 0, 1, 0.3 );
		g.addPointFull( 100, 200, 1, 1, 0, 1 );
		g.endFill();
		
		var f = new h2d.FlowWeird( scene );
		f.maxWidth = 300;
		f.maxHeight = 300;
		f.horitontalSpacing = 4;
		f.x = 250;
		f.y = 300;
		
		var g = new h2d.Graphics(scene);
		g.lineStyle(1);
		g.drawLine(f.x, f.y, f.x + 2, f.y);
		
		var fnt = hxd.res.FontBuilder.getFont("arial", 12);
		
		var t = new h2d.Text(fnt, f);
		t.text = "_" + 13 + "__" + 5389 + "_";
				
		//if(false)
		for ( i in 0...50) {
			haxe.Timer.delay( function(){
				var t = new h2d.Text(fnt, f);
				t.text = "_" + i + "______" + i + "_";
			},500*i);
		}
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
