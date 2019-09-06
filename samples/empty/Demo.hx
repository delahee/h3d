import h2d.Graphics;
import hxd.Stage;
import h2d.YuvSurface;

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	var sb : h2d.SpriteBatch;
	
	function new() {
		super();
		
		//hxd.System.debugLevel = 2;
		
		engine = new h3d.Engine();
		
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
		
	}
	
	function init() {
		hxd.System.setLoop(update,render);
		scene = new h2d.Scene();
		
		var g = new h2d.Graphics(scene);
		g.beginFill(0x00FFFF,0.5);
		g.lineStyle(2.0);
		g.drawRect( 0, 0, 50, 50);
		g.endFill();
		
		g.beginFill(0x00FFFF,0.2);
		g.drawRect( 50, 50, 50, 500);
		g.endFill();
		
		var s = new h2d.Sprite(scene );
		s.x = 50;
		s.y = 250;
		s.scaleX = (0.5); 
		s.scaleY = (1.5); 
		
		
		var t = h2d.Tile.fromColor(0xffcd00cd, 4, 8);
		sb = new h2d.SpriteBatch( t ,s  );
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		e.x = 100;
		e.y = 100;
		
		var t = t.centerRatio(0.5, 0.5);
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		e.x = 200;
		e.y = 100;
		
		var t = t.centerRatio(1, 1);
		var e = sb.alloc( t );
		e.setSize (32 , 32 );
		e.x = 300;
		e.y = 100;
		
		var s = new h2d.Simple( scene );
		s.scale(5);
		s.x = 500;
		s.y = 500;
		
		var s = new h2d.Simple( scene );
		s.tile = h2d.Tile.fromColor(0xff7fabaa);
		s.scale( 5 );
		s.x = 500;
		s.y = 400;
		
		
		var s = new h2d.YuvSurface( scene );
		
		s.texY = h3d.mat.Texture.fromColor(0x0);
		s.texUV = h3d.mat.Texture.fromColor(0x0);
		
		s.uploadingTexY 	= h3d.mat.Texture.fromColor(0xffffffff);
		s.uploadingTexUV 	= h3d.mat.Texture.fromColor(0xffffffff);
		
		var m : h3d.Matrix = new h3d.Matrix();
		m.set( 
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1 );
		s.srcXForm = m;
		s.scale( 5 );
		s.x = 500;
		s.y = 300;
		
		//test rect tex
		var t = new h3d.mat.Texture( 18, 6 );
		t.clear(0xffff00ff);
		
		var bmp = new h2d.Bitmap( h2d.Tile.fromTexture(t), scene );
		bmp.x = 550;
		bmp.y = 300;
		
		//
		var w = 24;
		var h = 32;
		var r200 = hxd.impl.Tmp.getBytesView( Math.round(w * h ));
		for ( i in 0...r200.length )
			r200.set( i, 200 );
		var px = new hxd.Pixels(w, h, r200 , Mixed(8, 0, 0, 0));
		trace( "0x"+ StringTools.hex( px.getPixel( 0, 0) ));
		var bmp = new h2d.Bitmap( h2d.Tile.fromPixels(px), scene );
		bmp.x = 580;
		bmp.y = 300;
		hxd.impl.Tmp.saveBytesView( r200 );
		
		//
		trace("trying 16 bit");
		var w = 24;
		var h = 32;
		var rg200100 = hxd.impl.Tmp.getBytesView( Math.round(w * h * 2));
		trace( rg200100.length );
		trace("writing everything");
		
		for ( i in 0...rg200100.length ){
			rg200100.set( i, 0xff );
		}
		
		for ( i in 0...(rg200100.length>>1) ){
			rg200100.set( (i<<1), 		0xde );
			rg200100.set( (i<<1) + 1, 	0xad );
		}
		var px = new hxd.Pixels(w, h, rg200100 , Mixed(8, 8, 0, 0));
		trace( "0x"+ StringTools.hex( px.getPixel( 0, 0) ));
		var bmp = new h2d.Bitmap( h2d.Tile.fromPixels(px), scene );
		bmp.x = 630;
		bmp.y = 300;
		hxd.impl.Tmp.saveBytesView( rg200100 );
		trace( "init ok" );
		
		//
		trace("trying 16 bit");
		var w = 640;
		var h = 360;
		var rg200100 = hxd.impl.Tmp.getBytesView( Math.round(w * h * 2));
		trace( rg200100.length );
		trace("writing everything");
		
		for ( i in 0...rg200100.length ){
			rg200100.set( i, 0xff );
		}
		for ( i in 0...(rg200100.length>>1) ){
			rg200100.set( (i<<1), 		0xde );
			rg200100.set( (i<<1) + 1, 	0xad );
		}
		var px = new hxd.Pixels(w, h, rg200100 , Mixed(8, 8, 0, 0));
		trace( "0x" + StringTools.hex( px.getPixel( 0, 0) ));
		
		var t0 = haxe.Timer.stamp();
		var tile = h2d.Tile.fromPixels(px);
		var t1 = haxe.Timer.stamp();
		trace("tex gen " + (t1 - t0) + "sec");
		
		var bmp = new h2d.Bitmap( tile, scene );
		bmp.x = 680;
		bmp.y = 300;
		hxd.impl.Tmp.saveBytesView( rg200100 );
		trace( "init ok" );
	}
	
	function update() 	{
		#if cpp 
		flash.Lib.current.invalidate();
		#end
		
		hxd.Timer.update();
		scene.checkEvents();
		
		if(sb!=null)
		for ( e in sb.getElements() ) {
			e.rotation += 0.1;
			var g = h2d.Graphics.fromBounds( sb.getElementBounds(e,scene),scene, 0xff0000,0.1);
			haxe.Timer.delay( g.dispose , 30);
		}
	}
		
	function render(){
		//trace("render");
		#if (lime >= "7.1.1")
		engine.triggerClear = true;
		#end
		
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
