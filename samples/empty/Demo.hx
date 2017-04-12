import h2d.Graphics;
import hxd.Stage;

import com.newgonzo.midi.file.MIDITrack;
import com.newgonzo.midi.messages.VoiceMessage;
import com.newgonzo.midi.file.MIDIFile;

//import flash.system.WorkerDomain;
//import flash.system.Worker;
import flash.events.Event;

import stb.format.vorbis.Reader;
import stb.format.vorbis.flash.VorbisSound;
import stb.format.vorbis.flash.VorbisSoundChannel;


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
	}
	
	function update() 	{
		engine.render(scene);
		engine.restoreOpenfl();
	}
	
	static function main() {
		new Demo();
	}
}
