import h2d.Graphics;
import hxd.Stage;
import hxd.Pad;


class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	var pads : Array<hxd.Pad>;
	
	function new() {
		super();
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
		
		pads = [];
	}
	
	var g:h2d.Graphics;
	var tButton : h2d.Text;
	
	var bs :Array<h2d.Graphics>= [];
	function init() {
		var p = haxe.Log.trace;
		
		#if flash
		haxe.Log.setColor(0xFF0000);
		#end
		
		hxd.System.setLoop(update);
		scene = new h2d.Scene();
		g = new h2d.Graphics(scene);
		g.x = 150;
		g.y = 150;
		g.beginFill(0x00FFFF,0.5);
		g.lineStyle(2.0);
		g.drawRect( 0, 0, 50, 50);
		g.endFill();
		
		var pos = 0;
		function onPad(p) {
			pads.push(p);
			
			var t = new h2d.Text(hxd.res.FontBuilder.getFont("consolas", 14), scene);
			t.text = "name: "+p.d.name+" id:"+p.d.id+(p.conf!=null?"[MATCHED]":"");
			t.x = hxd.Stage.getInstance().width - 10 - t.textWidth; 
			t.y = pos += 50;
			t.textColor = 0xff0000ff;
		}
		var stage = hxd.Stage.getInstance();
		
		var t = tButton = new h2d.Text(hxd.res.FontBuilder.getFont("consolas", 14), scene);
		t.text = "last pressed :";
		t.x = 10; 
		t.y = stage.height - t.textHeight - 10;
		t.textColor = 0xFD4E02;
		
		hxd.Pad.wait(onPad);
		
		//hxd.Pad.scanForPad(onPad);
		//hxd.Pad.scanForPad(onPad);
		
		var accX = 0;
		for ( i in 0...32) {
			var x = accX + 50;
			var y = 50 + ((i >= 16)?50:0);
			var b = mt.gx.h2d.Proto.circle( x, y, 16, 0xffffff, scene);
			b.alpha = 0.5;
			bs.push(b);
			accX += 32;
			if ( i == 16-1) 
				accX = 0;
			var t = new h2d.Text(hxd.res.FontBuilder.getFont("consolas", 14), b);
			t.text = "" + i;
			t.x -= 8;
			t.y -= 8;
			t.textColor = 0xff000000;
		}
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
		
		var dt = hxd.Timer.rdeltaT;
		
		inline function isActionned(v) {
			return v<-0.1||v>0.1;
		}
		
		for (b in bs ) {
			b.alpha = 0.5;
		}
		
		for( pad in pads){
			if ( pad.xAxis < -0.1 || pad.xAxis > 0.1) {
				g.x += 5 * dt * pad.xAxis;
				trace(pad.xAxis);
			}
			if ( pad.yAxis < -0.1 || pad.yAxis > 0.1) {
				g.y += 5 * dt * pad.yAxis;
				trace(pad.yAxis);
			}
			for ( i in 0...pad.buttons.length) {
				var b = pad.buttons[i];
				if ( isActionned(pad.values[i])) {
					//trace('${pad.index} is using ' + pad.nativeIds[i] );
					bs[i].alpha = pad.values[i] * 0.5 + 0.5;
					if( tButton != null)
						tButton.text = "last pressed : "+pad.getButtonName(i);
				}
			}
			
			
			
			for ( i in 0...pad.buttons.length) {
				if ( pad.onPress(i)) {
					trace(pad.getButtonName(i)+" on press ");
				}
			}
			
			for ( i in 0...pad.buttons.length) {
				if ( pad.isDown(i)) {
					trace(pad.getButtonName(i)+" is down");
				}
			}
		}
		
		hxd.Pad.update();
	}
	
	static function main() {
		new Demo();
	}
}
