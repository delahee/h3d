import h2d.Graphics;
import hxd.Stage;


class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	var resLoader : hxd.res.Loader;
	
	public function loadWav(path:String):flash.media.Sound {
		var t0 = haxe.Timer.stamp();
		var ba : flash.utils.ByteArray;
		//trace("loading " + path);
		if ( ! resLoader.fs.exists(path) ) {
			trace("-wav not found " + path);
			return null;
		}
		
		ba = resLoader.fs.get(path).getBytes().getData();
		var wavReader = new format.wav.Reader( new haxe.io.BytesInput( haxe.io.Bytes.ofData( ba )));
		var waveData :format.wav.Data.WAVE = wavReader.read();
		if ( waveData == null ){
			trace("cant read wav " + path);
			return null;
		}
		var f = new flash.media.Sound();
		var channels = waveData.header.channels;
		var bytesPerSample = waveData.header.bitsPerSample >> 3;
		var samples = Math.round( waveData.data.length / ( channels * bytesPerSample ) );
		var ba = waveData.data.getData();
		ba.position = 0;
		var t1 = haxe.Timer.stamp();
		f.loadPCMFromByteArray( ba, samples, bytesPerSample == 2?"short":"float", channels >= 2, 44100 );//maybe try "short"
		var t2 = haxe.Timer.stamp();
		
		ba = null;
		
		return f;
	}
	
				
	function new() {
		super();
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		engine.init();
		
		
		
		var lfs = new hxd.res.LocalFileSystem( "../../../assets" );
		resLoader = new hxd.res.Loader( lfs );
		
		var snd = loadWav( "GUNDILLAC_START.wav" );
		var fx = new mt.flash.Sfx( snd );
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
		//g.lineStyle(2.0);
		//g.drawRect( 0, 0, 50, 50);
		g.addPointFull( 100, 100, 1, 0, 0, 1 );
		g.addPointFull( 200, 100, 0, 1, 0, 0 );
		g.addPointFull( 200, 200, 1, 0, 1, 0.3 );
		g.addPointFull( 100, 200, 1, 1, 0, 1 );
		g.endFill();
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
