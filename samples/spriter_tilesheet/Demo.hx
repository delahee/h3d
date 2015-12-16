import h2d.Graphics;
import hxd.Stage;

import flash.display.BitmapData;
import flash.display.Bitmap;

import spriter.library.BitmapLibrary;
import spriter.library.H2dBitmapLibrary;
import spriter.library.H2dSpritebatchLibrary;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var e : spriter.engine.SpriterEngine;
	var h2de : spriter.engine.SpriterEngine;
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
		
		var canvas:BitmapData = new flash.display.BitmapData(800, 480);
		var spriterRoot:Bitmap = new Bitmap(canvas, flash.display.PixelSnapping.AUTO, true);
		var lib : spriter.library.BitmapLibrary = new BitmapLibrary('assets/GreyGuy/', canvas);
		e = new spriter.engine.SpriterEngine(openfl.Assets.getText('assets/GreyGuy/player.scml'), lib, null );
		flash.Lib.current.stage.addChild( spriterRoot );
		
		var ent : spriter.engine.Spriter = e.addEntity('Player');
		ent.info.x = 300;
		ent.info.y = -300;
		
		var ent : spriter.engine.Spriter = e.addEntity('Player');
		ent.info.x = 300;
		ent.info.y = -200;
		
		
		var lib : spriter.library.H2dSpritebatchLibrary = new H2dSpriteBatchLibrary('assets/GreyGuy/', scene);
		h2de = new spriter.engine.SpriterEngine(openfl.Assets.getText('assets/GreyGuy/player.scml'), lib, null );
		var ent : spriter.engine.Spriter = h2de.addEntity('Player');
		ent.info.x = 100;
		ent.info.y = -200;
		
		var ent : spriter.engine.Spriter = h2de.addEntity('Player');
		ent.info.x = 100;
		ent.info.y = -100;
		h2d.Drawable.DEFAULT_FILTER = true;
	}
	
	function update() 	{
		e.update();
		h2de.update();
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
