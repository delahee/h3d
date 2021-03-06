import h2d.Bitmap;
import h2d.comp.Box;
import h2d.comp.Component;
import h2d.comp.Image;
import h2d.comp.JQuery;
import h2d.comp.Label;
import h2d.css.Fill;
import h2d.css.Style;
import h2d.css.Defs;
import h2d.Drawable.DrawableShader;
import h2d.Graphics;
import h2d.IText;
import h2d.Scene;
import h2d.Sprite;
import h2d.SpriteBatch;
import h2d.Text;
import h2d.TextBatchElement;
import h2d.Tile;
import h3d.Engine;
import h3d.mat.Texture;
import h3d.mat.Texture;
import h3d.Matrix;
import h3d.Vector;
import haxe.Timer;
import hxd.BitmapData;
import hxd.DrawProfiler;
import hxd.Key;
import hxd.Pixels;
import hxd.Profiler;
import hxd.res.FontBuilder;
import h2d.NumberOpt;
import h2d.FPSMeter;
import Keys;

typedef Col = {
	r	: Int, // 0-255
	g	: Int, // 0-255
	b	: Int, // 0-255
}

typedef ColHsl = {
	h	: Float, // 0-1
	s	: Float, // 0-1
	l	: Float, // 0-1
}

class Demo extends flash.display.Sprite
{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	
	function new() {
		super();
		engine = new h3d.Engine();
		hxd.System.debugLevel = 1;
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
		k = new Keys();
	}
	
	function getBmp(path:String) {
		var n = openfl.Assets.getBitmapData( path );
		var b = hxd.BitmapData.fromNative( n );
		return b;
	}
	
	function getTile(path:String) {
		return h2d.Tile.fromAssets(path);
	}
	
	var enableTest : hxd.BitArray = new hxd.BitArray().fillRange(true,0,64);
	var arial : openfl.text.Font;
	
	function init() {
		hxd.System.setLoop(update,render);
		
		scene = new h2d.Scene();
		
		#if (lime>="7.1.1")
		trace(openfl.Assets.list(openfl.utils.AssetType.IMAGE));
		trace(openfl.Assets.list(openfl.utils.AssetType.FONT));
		#end
		//trace(openfl.Assets.defaultRootPath);
		
		var driver = h3d.Engine.getCurrent().driver;
		
		arial = openfl.Assets.getFont("assets/arial.ttf");
		trace("arial: " + arial);
		
		var font = hxd.res.FontBuilder.getFont( arial.fontName, 10);
		var tile = getTile("assets/haxe.png");
		tile.setCenterRatio(0.5, 0.5);
		
		var dcBg = getTile("assets/demoNight.png"); dcBg.setCenterRatio(0.5, 0.5);
		var dkhBg = getTile("assets/h3dA_128x128.png"); dkhBg.setCenterRatio(0.5, 0.5);
		var dcOverlay = getTile("assets/rampedLight.png"); dcOverlay.setCenterRatio(0.5, 0.5);
		var overlay = getTile("assets/overlay.png"); overlay.setCenterRatio(0.5, 0.5);
		var car = getTile("assets/carPlay1.png"); car.setCenterRatio(0.5, 0.5);
		
		//create multiple gpu textures
		var tiles = [ getTile("assets/haxe.png"), getTile("assets/haxe.png"), getTile("assets/haxe.png"), getTile("assets/haxe.png") ];
		
		tiles = tiles.map(function(tile){
			tile.setCenterRatio(0.5, 0.5);
			return tile;
		});
		
		var cellX = 40.0;
		var baseline = 48;
		var bmp;
		var incr = 24;
		var txtBaseLine = 48;
		
		var n = 0;
		
		var fbmp;
		var ftext;
		
		//var b = new h2d.Bitmap( h2d.Tools.getWhiteTile().clone(), scene );
		//b.setSize( 256, 256);
		
		if ( enableTest.get( n ))
		{
			//single bitmap no emit
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			var t = new h2d.Text( font, bmp );
			t.text = "Single Bitmap";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			
			ftext = t;
			
			bmp.blendMode = Normal;
			var bmp = bmp;
			actions.push( function() bmp.alpha = Math.abs(Math.sin(hxd.Timer.oldTime) ) );
			
			cellX += bmp.width + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			//single bitmap emit
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.emit = true;
			bmp.alpha = Math.random() * 0.25 + 0.5;
						
			var t = new h2d.Text( font, bmp );
			t.text = "Single Bitmap Emit";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			
			cellX += bmp.width + incr + 16;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			var root = new h2d.Sprite(scene);
			root.x = cellX;
			root.y = baseline;
			
			//fout bitmap emit
			for( i in 0...4){
				bmp = new h2d.Bitmap(tiles[i], root);
				bmp.scaleX = bmp.scaleY = 0.33;
				bmp.x = 4 - (((i % 2) == 0) ? 0 : 16 );
				bmp.y = 4 - ((((i >> 1) % 2) == 0) ? 0 : 16);
				bmp.emit = true;
				bmp.alpha = Math.random() * 0.5 + 0.4;
			}
				
			var t = new h2d.Text( font, root );
			t.text = "Four Bitmap Emit";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			cellX += 32 + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			//single bitmap add no emit
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.blendMode = Add;
			var t = new h2d.Text( font, bmp );
			t.text = "Single Bitmap Add";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			
			cellX += bmp.width + incr;
		}
		n++;
		
		//if( false )
		if ( enableTest.get( n ))
		{
			//sprite match
			var sb = new h2d.SpriteBatch(tile, scene);
			var spread = 32;
			var rspread = 12;
			for ( i in 0...300) {
				var e = sb.alloc(tile);
				
				var ex = cellX 		+ spread * Math.random() - spread*0.5; 
				var ey = baseline 	+ spread * Math.random() - spread*0.5;
				
				e.x = ex;
				e.y = ey;
				
				e.scaleX = 0.2;
				e.scaleY = 0.2;
				
				actions.push(
				function() {
					e.x = ex + rspread * Math.random() - rspread * 0.5;
					e.y = ey + rspread * Math.random() - rspread * 0.5;
				});
			}
			
			var t = new h2d.Text( font, scene );
			t.x = cellX;
			t.y = baseline + txtBaseLine;
			t.text = "SpriteBatch";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.x -= t.textWidth * 0.5;
			cellX += sb.width + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			//sprite match
			var sb = new h2d.SpriteBatch(tile, scene);
			var spread = 32;
			var rspread = 12;
			for ( i in 0...300) {
				var e = sb.alloc(tile);
				var ex = cellX 		+ spread * Math.random() - spread*0.5; 
				var ey = baseline 	+ spread * Math.random() - spread*0.5;
				
				e.x = ex;
				e.y = ey;
				
				e.scaleX = 0.2;
				e.scaleY = 0.2;
				
				e.x = ex + rspread * Math.random() - rspread * 0.5;
				e.y = ey + rspread * Math.random() - rspread * 0.5;
			}
			
			var t = new h2d.Text( font, scene );
			t.x = cellX;
			t.y = baseline + txtBaseLine;
			t.text = "Optimized SpriteBatch";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.x -= t.textWidth * 0.5;
			
			sb.optimizeForStatic(true);
			
			cellX += 48 + incr;
		}
		n++;
		
		
		if ( enableTest.get( n ))
		{
			//single bitmap no emit
			var root = new h2d.CachedBitmap(scene,1024,1024);
			bmp = new h2d.Bitmap(tile, root);
			
			root.x = cellX - bmp.width;
			root.y = baseline - bmp.height;
			
			bmp.x = bmp.width;
			bmp.y = bmp.height;
			
			
			var t = new h2d.Text( font, root );
			t.text = "Single Bitmap Cached No Freeze";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine + 32;
			
			var mbmp = bmp;
			actions.push(
			function() {
				mbmp.rotation += 0.1;
			});
			
			cellX += 48 + incr;
		}
		n++;
		
		
		if ( enableTest.get( n ) )
		{
			//single bitmap no emit
			var root = new h2d.CachedBitmap(scene, 1024, 1024);
			root.name = "cached";
			root.freezed = true;
			var bmp = new h2d.Bitmap(tile, root);
			
			root.x = cellX - bmp.width;
			root.y = baseline - bmp.height;
			
			bmp.x = bmp.width;
			bmp.y = bmp.height;
			
			var t = new h2d.Text( font, root );
			var str = "Single Bitmap Cached"; 
			t.text = str ;
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine + 32;
			t.textColor = 0xffff00ff;
			t.emit = true;
			
			var obmp = new h2d.Bitmap(tile, root);
			obmp.x = bmp.width + 30;
			obmp.y = txtBaseLine + 32;
		
			{
				var spin = 0;
				var period  = 500;
				actions.push(
				function() {
					if ( spin >= (period >> 1) ) { 
						if( !root.freezed ){
							root.freezed = true; 
							t.text = str + " FROZEN";
							root.invalidate();
						}
					}
					
					if ( spin < (period>>1) ) { 
						root.freezed = false; 
						t.text = str; 
						root.invalidate();
					}
					
					if ( spin == period)
						spin = 0;
					else 
						spin++;
					
					bmp.rotation += 0.1;
				});
			}
			
			cellX += 48 + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			//vector
			var gfx = new h2d.Graphics(scene);
			gfx.x = cellX;
			gfx.y = baseline;
			gfx.lineStyle(1.0, 0x0);
			gfx.beginFill( 0xFFFF00, 1.0);
			gfx.drawRect( -16, -16, 32, 32);
			gfx.endFill();
			
			var t = new h2d.Text( font, gfx );
			t.text = "Graphics";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			
			t.x = Std.int( t.x );
			
			cellX += 96 + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			var rt = new h2d.Mask(0,0,scene);
			
			//single bitmap no emit masked
			var bmp = new h2d.Bitmap(tile, rt);
			rt.x = cellX ;
			rt.y = baseline ;
			rt.offsetX = - bmp.width * 0.5;
			rt.offsetY = - bmp.height * 0.5;
			
			var t = new h2d.Text( font, bmp );
			t.text = "Single Bitmap Masked";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int( t.x );
			bmp.blendMode = Normal;
			var bmp = bmp;
			
			actions.push( function() bmp.alpha = Math.abs(Math.sin(hxd.Timer.oldTime) ) );
			actions.push(function (){
				rt.width = Math.abs(Math.sin(hxd.Timer.oldTime) * bmp.width * 2);
				rt.height = Math.abs(Math.sin(hxd.Timer.oldTime) * bmp.height * 2);
			});
			
			cellX += 96 + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			var t = new h2d.Text( font, scene );
			t.text = "Lorem ipsum dolor sit amet,\n consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n";
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.maxWidth = 128;
			t.x = cellX;
			t.y = baseline;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int( t.x );
			
			actions.push( function() t.alpha = Math.abs(Math.sin(hxd.Timer.oldTime) ) );
			
			cellX += 96 + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			var tile = h2d.Tile.fromAssets("assets/haxe.png");
			tile.getTexture().wrap = Repeat;
			//single bitmap no emit
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			var t = new h2d.Text( font, bmp );
			t.text = "Single Bitmap Repeat";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			bmp.blendMode = Normal;
			var bmp = bmp;
			var tile = bmp.tile;
			var ow = tile.width;
			var oh = tile.height;
			tile.setSize( tile.width * 2, tile.height * 2 );
			bmp.x -= tile.width*0.5;
			bmp.y -= tile.height*0.5;
			
			var bu = @:privateAccess tile.u;
			var bu2 = @:privateAccess tile.u2;
			
			actions.push( function() {
				var r = hxd.Math.fumod(hxd.Timer.oldTime, 1.0);
				
				@:privateAccess tile.u = bu + r;
				@:privateAccess tile.u2 = bu2 + r;
			});
		}
		n++;
		
		baseline = 250;
		cellX = 100;
		
		if ( enableTest.get( n ))
		{	//single bitmap aliased
			bmp = new h2d.Bitmap(h2d.Tile.fromAssets("assets/aliased.png").centerRatio(),scene);
			bmp.x = cellX;
			bmp.y = baseline;
			var t = new h2d.Text( font, bmp );
			t.text = "Bitmap Aliased";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int(t.x);
			bmp.blendMode = Normal;
			bmp.filter = true;
			cellX += bmp.width + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{	//single bitmap aliased
			bmp = new h2d.Bitmap(h2d.Tile.fromAssets("assets/aliased.png").centerRatio(),scene);
			bmp.x = cellX;
			bmp.y = baseline;
			var t = new h2d.Text( font, bmp );
			t.text = "Bitmap Anti-Aliased (fxaa) ";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int(t.x);
			bmp.blendMode = Normal;
			bmp.filter = true;
			bmp.hasFXAA = true;
			cellX += bmp.width + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{	//shared shader texts
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.blendMode = Normal;
			bmp.filter = true;
			var ts :Array<h2d.Text> = [];
			
			var t = new h2d.Text( font, bmp );
			t.text = "Shared shader texts 2 ";
			t.maxWidth = 32;
			t.dropShadow = { dx : 2.0, dy : 2.0, color : 0xFF0000FF, alpha : 0.5 };
			t.y = txtBaseLine * 2 - 30;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int(t.x);
			t.textColor = 0xFF00FF;
			t.alpha = 0.5;
			
			ts.push(t);
			
			var t = new h2d.Text( font, bmp, cast t.shader.clone() );
			t.text = "Shared shader texts 1";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF0000FF, alpha : 0.8 };
			t.y = txtBaseLine * 1.5 - 30;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int(t.x);
			t.textColor = 0x00FFFF;
			ts.push(t);
			
			var t = new h2d.Text( font, bmp , cast t.shader.clone() );
			t.text = "Shared shader texts 0";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine - 30;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int(t.x);
			t.alpha = 0.1;
			ts.push(t);
			
			ts.push(t);
			
			Timer.delay( function() {
				for ( t in ts ) {
					var s : DrawableShader = t.shader;
					#if flash
					var instance = s.getInstance();
					trace( instance.id );
					#else 
					var instance = s.getSignature();
					trace( instance );
					#end
				}
				trace(hxd.Profiler.dump(false));
			},50);
			cellX += bmp.width + incr;
			cellX += bmp.width + incr;
		}
		n++;

		if ( enableTest.get( n ))
		{	//single bitmap anisotropic filtered (useless i know)
			var tile = h2d.Tile.fromAssets("assets/aliased.png");
			if ( driver.hasFeature( AnisotropicFiltering )  ) {
				var tex = tile.getTexture();
				tex.anisotropicLevel = 2;
				tex.dispose();	
			}
			bmp = new h2d.Bitmap(tile.centerRatio(),scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.blendMode = Normal;
			bmp.filter = true;
			
			var t = new h2d.Text( font, bmp );
			t.text = "Anisotropic Filtering";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int(t.x);
			cellX += bmp.width + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{	//single bitmap anisotropic filtered (useless i know)
			var tile = h2d.Tile.fromColor(0xFF00FF00);
			bmp = new h2d.Bitmap(tile.centerRatio(),scene);
			bmp.x = cellX-16;
			bmp.y = baseline;
			bmp.blendMode = Normal;
			bmp.filter = true;
			
			var f = new flash.display.BitmapData(16, 16, true, 0xFFff0000);
			bmp = h2d.Bitmap.fromBitmapData( f, scene );
			bmp.x = cellX;
			bmp.y = baseline + 16;
			bmp.blendMode = Normal;
			bmp.filter = true;
			
			var p = hxd.Pixels.alloc( 16, 16, BGRA);
			var k = 0;
			for ( x in 0...16)
				for( y in 0...16){
					p.bytes.set(k++, 255);
					p.bytes.set(k++, 255);
					p.bytes.set(k++, 255);
					p.bytes.set(k++, 255);
				}
			bmp = h2d.Bitmap.fromPixels( p, scene );
			bmp.x = cellX;
			bmp.y = baseline - 16;
			bmp.blendMode = Normal;
			bmp.filter = true;
			
			var t = new h2d.Text( font, bmp );
			t.text = "Colored Tile";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int(t.x);
			cellX += bmp.width + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			
			bmp = bmp.clone();
			bmp.x = cellX+10;
			bmp.y = baseline;
			
			bmp = bmp.clone();
			bmp.x = cellX+20;
			bmp.y = baseline;
						
			var t = new h2d.Text( font, bmp );
			t.text = "Single Bitmap Clone";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			cellX += bmp.width + incr;
		}
		n++;
		
		var txt:Text;
		if ( enableTest.get( n ))
		{
			txt = new h2d.Text(font, scene);
			txt.text = "FOO";
			txt.x = cellX;
			txt.y = baseline;
			txt.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			
			txt = txt.clone();
			txt.x = cellX+5;
			txt.y = baseline+10;
			txt.text += "BAR";
			
			txt = txt.clone();
			txt.x = cellX+10;
			txt.y = baseline+20;
			txt.textColor = 0xFF00FF00;
						
			var t = new h2d.Text( font, txt );
			t.text = "Cloned Text";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
		}
		n++;
		
		baseline = 400;
		cellX = 10;
		
		if ( enableTest.get( n ))
		{
			var root : Component = new h2d.comp.Component("document", scene);
			root.id = "document";
			root.x = cellX;
			root.y = baseline;
			
			var style = new h2d.css.Style();
			style.borderColor = FillStyle.Color(0xFF00FFFF);
			style.borderSize = 2.0; 
			style.backgroundColor = FillStyle.Color(0xFFFFFF00);
			style.width = 100;
			style.height = 100;
			style.fontName = arial.fontName;
			style.fontSize = font.size;
			root.setStyle( style );
			
			var style = new h2d.css.Style();
			style.layout = h2d.css.Layout.Inline;
			style.color = 0xFF000000;
			style.borderColor = FillStyle.Color(0xFFff0000 );
			style.borderSize = 2.0; 
			style.fontName = arial.fontName;
			style.fontSize = font.size;
			
			var b = new Box( root );
			b.id = "container";
			var l = new Label( "foo", b);
			l.name = "#foo";
			l.setStyle( style);
			
			var l = new Label( "foo2", b);
			l.name = "#foo2";
			l.setStyle( style);
			
			var l = l.clone();
			l.text = "#foo3";
			
			var jqSrc = new JQuery( root,l );
			var jqDst = new JQuery( root,"#container" );
			
			jqDst.add( jqSrc );
			
			l.text = "#foo5";
			jqDst.add( jqSrc );
			
			var lbl = "<label>foo4</label>";
			var jqLbl = new JQuery( null, lbl );
			jqDst.add( jqLbl );
			
			var lbl = "<label>foo6</label>";
			var jqLbl = new JQuery( root, lbl );
			jqDst.add( jqLbl );
		
			var imgPrev : h2d.comp.Image = Image.fromAssets("assets/heart32.png");
			var style = style.clone();
			style.width = 20;
			style.height = 20;
			imgPrev.setStyle( style);
			jqDst.add( new JQuery( null, imgPrev) );
			
			var imgPrev : h2d.comp.Image = Image.fromAssets("assets/heart32.png");
			var style = style.clone();
			//style.width = 20;
			//style.height = 20;
			imgPrev.setStyle( style);
			jqDst.add( new JQuery( null, imgPrev) );
			
			@:privateAccess {
				root.needRebuild = true;
				for ( c in root.components) {
					trace(c.name);
					trace(c.x);
				}
			}
			
			var imgPrev : h2d.comp.Image = Image.fromAssets("assets/heart32.png");
			var style = style.clone();
			imgPrev.id = "COEUR";
			style = style.clone();
			style.backgroundSize = Rect(100,100);
			imgPrev.setStyle( style);
			jqDst.add( new JQuery( null, imgPrev) );
			
			@:privateAccess imgPrev.sync(new h2d.RenderContext(scene));
			
						
			var t = new h2d.Text( font, root );
			t.text = "Manual comps";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x = t.textWidth * 0.5;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			cellX += 500;
			
			var tile = h2d.Tile.fromAssets("assets/checker.png");
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.filter = true;
			bmp.scaleX = bmp.scaleY = 8;
						
			var t = new h2d.Text( font, scene );
			t.text = "Linear Filter";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine + bmp.y;
			t.x = bmp.x;
		
			cellX += 60;
			
			var tile = h2d.Tile.fromAssets("assets/checker.png");
			tile.getTexture().filter = Linear;
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.filter = false;
			bmp.scaleX = bmp.scaleY = 8;
						
			var t = new h2d.Text( font, scene );
			t.text = "Linear NO Filter";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine + bmp.y;
			t.x = bmp.x;
			
			cellX += 60;
			
			
			var tile = h2d.Tile.fromAssets("assets/checker.png");
			tile.getTexture().filter = Nearest;
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.filter = true;
			bmp.scaleX = bmp.scaleY = 8;
						
			var t = new h2d.Text( font, scene );
			t.text = "Nearest Filter";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine + bmp.y;
			t.x = bmp.x;
			
			cellX += 60;
			
			var tile = h2d.Tile.fromAssets("assets/checker.png");
			tile.getTexture().filter = Nearest;
			bmp = new h2d.Bitmap(tile,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.filter = false;
			bmp.scaleX = bmp.scaleY = 8;
						
			var t = new h2d.Text( font, scene );
			t.text = "Nearest NO Filter";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine + bmp.y;
			t.x = bmp.x;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			cellX += 120;
			
			var sb = new h2d.SpriteBatch( font.tile, scene);
			sb.x = cellX;
			sb.y = baseline;
			sb.hasVertexAlpha = false;
			
			inline function r<T>(arr:Array<T>) return arr[Std.random(arr.length)];
			
			var tb = new h2d.TextBatchElement( font, sb );
			tb.text = r(["ragnar", "rölf", "Lagerta", "floki"]);
			
			var tb = new h2d.TextBatchElement( font, sb );
			tb.text = "RAGNAR";
			tb.x = 10;
			tb.y = -20;
			tb.dropShadow = { dx : 1.0, dy : 1.0, color : 0, alpha : 1.0 };
			
			var tb = new h2d.TextBatchElement( font, sb );
			tb.text = "RAGNAR";
			tb.x = 10;
			tb.y = -35;
			tb.dropShadow = { dx : 1.0, dy : 1.0, color : 0, alpha : 1.0 }
			tb.scaleX = 0.5;
			tb.scaleY = 0.5;
			
			var tb = new h2d.TextBatchElement( font, sb );
			tb.text = r(["ragnar", "rölf", "Lagerta", "floki"]);
			tb.textColor = r([0xFA6E69, 0xFFCE74, 0x97D17A, 0x4C8DA6, 0x5B608C]);
			tb.alpha = 0.5;
			tb.x = 50;
			tb.y = 5;
			
			var tb2 = new h2d.TextBatchElement( font, sb );
			tb2.text = r(["ragnar", "rölf", "Lagerta", "floki"]);
			tb2.textColor = r([0xFA6E69, 0xFFCE74, 0x97D17A, 0x4C8DA6, 0x5B608C]);
			tb2.x = tb.x + tb.textWidth + 1;
			tb2.y = 5;
			
			var tb3 = new h2d.TextBatchElement( font, sb );
			tb3.text = "Lorem Ipsum\nLorem Ipsum\n";
			tb3.textColor = r([0xFA6E69, 0xFFCE74, 0x97D17A, 0x4C8DA6, 0x5B608C]);
			tb3.x = tb2.x + tb2.textWidth + 1;
			tb3.y = 5;
			
			var base = tb3.x;
			actions.push(
					function() {
						tb3.x+=0.2;
						tb3.y+=0.2;
						if ( tb3.x > base + 20 ){
							tb3.x = base;
							tb3.y = 5; 
						}
					}
				);
			
			for ( i in 0...2) {
				var tb = new h2d.TextBatchElement( font, sb );
				tb.x = 100 + Std.random(50);
				tb.y = -20 - i * 20;
				tb.dropShadow = { dx:1, dy:1, color:0xff0000, alpha : 0.5 };
				tb.text = r(["ragnar", "rölf", "Lagerta", "floki"]);
				tb.textColor = r([0x021F59, 0x034AA6, 0xD96704, 0x8C1C03, 0x400101]);
				tb.alpha = 0.8 + 0.2 * Math.random();
			}
			
			
			for( i in 0...4){
				var atb = new h2d.TextBatchElement( font, sb );
				atb.text = "WICKET";
				atb.dropShadow = { dx:1, dy:1, color:0x000000, alpha : 0.5 };
				atb.textColor = r([0xFA6E69, 0xFFCE74, 0x97D17A, 0x4C8DA6, 0x5B608C]);
				atb.x = 300 + i * 10;
				atb.y = 5 + i * 20;
				
				var l = Std.random(10) % 10;
				actions.push(function() {
					if( l > 10 ){
						atb.visible = !atb.visible;
						l = 0;
					}
					l++;
				});
				
			}
			
			var t = new h2d.Text( font, scene );
			t.text = "Text Batch " ;
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine + sb.y;
			t.x = sb.x;
		}
		n++;
		
		cellX = 80;
		baseline = 600;
		
		//
		// Typical usage : lightsabers, rays, overbrighting surfaces , fog 
		//
		if ( enableTest.get( n ))
		{
			var o = bmp = new h2d.Bitmap(dkhBg,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			
			var bmp = new h2d.Bitmap(overlay,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.blendMode = Screen;
			bmp.width = o.width;
			bmp.height = o.height;
			
			var t = new h2d.Text( font, bmp );
			t.text = "Blend Mode : Screen";
			t.maxWidth = 100;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int( t.x );
			cellX += 120 + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			bmp = new h2d.Bitmap(dkhBg,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			
			var bmp = new h2d.Bitmap(dcOverlay,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.blendMode = SoftOverlay;
			
			var t = new h2d.Text( font, bmp );
			t.text = "Blend Mode : Soft Overlay";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int( t.x );
			
			var bmp = bmp;
			actions.push(function (){
				bmp.alpha = Math.abs(Math.sin( hxd.Timer.oldTime * 2.0 ));
			});
			cellX += 120 + incr ;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			
			
			bmp = new h2d.Bitmap(dkhBg,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			
			bmp.alphaMap = overlay;
			bmp.alphaMapAsOverlay = true;
			
			var t = new h2d.Text( font, bmp );
			t.text = "Blend Mode :  Overlay";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = Std.int( t.x );
			cellX += 120 + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			
			
			var nscene = new h2d.Scene(); 
			var g = new h2d.Graphics(nscene);
			
			g.x = 30;
			g.lineStyle(1);
			g.beginFill(0xff00ff00);
			g.drawRotatedRect(10, 10, 30, 20, Math.PI * 0.33 );
			g.endFill();
			
			var b = nscene.captureBitmap();
			
			var bmp = new h2d.Bitmap( b.tile, scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.color = new h3d.Vector(1, 1, 1, 0.8);
			
			var t = new h2d.Text( font, scene );
			t.text = "2d Capture Bitmap";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = baseline + txtBaseLine;
			t.x -= t.textWidth * 0.5;
			t.x = cellX + Std.int( t.x );
			
			cellX += 120 + incr;
			
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			
			
			bmp = new h2d.Bitmap(car,scene);
			bmp.x = cellX;
			bmp.y = baseline;
			bmp.colorMatrix = h3d.Matrix.colorColorize(0xff21517A,0.25,0.75);
			
			var t = new h2d.Text( font, bmp );
			t.text = "Colorize";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.y = txtBaseLine;
			t.x = Std.int( t.x );
			
			cellX += bmp.width + incr;
		}
		n++;
		
		if ( enableTest.get( n ))
		{
			//sprite match
			var sb = new h2d.MultiSpriteBatch( scene);
			
			var e = sb.alloc(car);
			var ex = cellX - 50; 
			var ey = baseline;
			e.x = ex; 
			e.y = ey; 
			//e.visible = false;
			//e.blend = Add;

			
			var e = sb.alloc(dkhBg);
			var ex = cellX - 20; 
			var ey = baseline;
			e.x = ex; e.scaleX = 0.3;
			e.y = ey; e.scaleY = 0.3;
			//e.visible = false;
			
			
			var e = sb.alloc(dkhBg);
			var ex = cellX + 20; 
			var ey = baseline;
			e.x = ex; e.scaleX = 0.2;
			e.y = ey; e.scaleY = 0.2;
			//e.visible = false;
			//e.blend = Add;
			
			var e = sb.alloc(car);
			var ex = cellX + 80; 
			var ey = baseline;
			e.x = ex; e.scaleX = 0.25;
			e.y = ey; e.scaleY = 0.25;
			
			var e = sb.alloc(car);
			var ex = cellX + 120; 
			var ey = baseline;
			e.x = ex; e.scaleX = 0.25;
			e.y = ey; e.scaleY = 0.25;
			//e.visible = false;
			//e.visible = false;
			
			
			var t = new h2d.Text( font, scene );
			t.x = cellX;
			t.y = baseline + txtBaseLine;
			t.text = "MultiSpriteBatch";
			t.maxWidth = 32;
			t.dropShadow = { dx : 1.0, dy : 1.0, color : 0xFF000000, alpha : 0.8 };
			t.x -= t.textWidth * 0.5;
		}
		n++;
		
		{
			fps = new h2d.FPSMeter( scene );
			fps.x = scene.width - 200;
			fps.y = 0;
		}
		
	}
	
	var fps :h2d.FPSMeter;
	var atb:TextBatchElement;
	var actions = [];
	
	var fr = 0;
	
	var start = 0;
	var old : h2d.Sprite  = null;
	
	var k : Keys;
	function update() 	{
		#if cpp 
		flash.Lib.current.invalidate();
		#end
		
		k.update();
		
		hxd.Timer.update();
		scene.checkEvents();
		
		for ( a in actions ) 
			a();
			
		//if ( false )
		{
			
			if ( k.isDown(hxd.Key.D) ) {
				trace("Key is Down");
			}
			
			if ( k.isHold(hxd.Key.H) ) {
				trace("Key is Hold");
			}
			
			if ( k.isReleased(hxd.Key.R) ) {
				trace("Key is Released");
			}
			
			if ( k.onRelease(hxd.Key.R) ) {
				trace("Key is just released");
			}
			
			if ( k.onPress(hxd.Key.K) ) {
				trace("startTextureGC");
				h3d.Engine.getCurrent().mem.startTextureGC();
			}
			
			if ( k.onPress(hxd.Key.P) ) {
				trace("DrawProfiler full");
				if ( old != null)
					old.remove();
					
				var t = hxd.DrawProfiler.analyse(scene);
				t = t.slice( start );
				
				old = hxd.DrawProfiler.makeGfx( t );
				scene.addChild( old );
				start += 10;
			}
			
			if ( k.onPress(hxd.Key.L) ) {
				trace("DrawProfiler slice");
				var oldScene = scene;
				var tile = h2d.Tile.fromColor( 0xffFF0000 );
				var scene = new h2d.Scene();
				var bmp = new h2d.Bitmap(tile, scene); 
				var bmp = new h2d.Bitmap(tile, scene); 
				var bmp = new h2d.Bitmap(tile, scene); 
				var bmp = new h2d.Bitmap(tile, scene); 
				
				var g = new h2d.Graphics( scene); 
				g.beginFill();
				g.drawRect(0, 0, 10, 10);
				g.endFill();
				g.beginFill();
				g.drawRect(20,20,10,10);
				g.endFill();
				
				var t = hxd.DrawProfiler.analyse(scene);
				var g = hxd.DrawProfiler.makeGfx( t );
				oldScene.addChild( g );
			}
			
			if ( k.onPress(hxd.Key.C) ) {
				trace("hxd.Profiler slice");
				trace(hxd.Profiler.dump(true));
			}
		}
		
		fr++;
	}
	
	function render(){
		//trace("render request");
			
		//engine.triggerClear = true;
		#if (lime >= "7.1.1")
		engine.triggerClear = true;
		#end
		engine.render(scene);
		engine.restoreOpenfl();
	}
}
