import flash.Lib;
import flash.utils.ByteArray;
import format.h3d.AnimationWriter;
import format.h3d.Data;
import format.h3d.Tools;
import h3d.anim.Animation;
import h3d.mat.Material;
import h3d.mat.MeshMaterial;
import h3d.mat.Texture;
import h3d.scene.Scene;
import h3d.scene.Mesh;
import h3d.Vector;
import haxe.CallStack;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.Log;
import haxe.Serializer;
import haxe.Unserializer;
import hxd.BitmapData;
import hxd.ByteConversions;
import hxd.Pixels;
import hxd.Profiler;
import hxd.res.LocalFileSystem;
import hxd.System;
import openfl.Assets;
import sys.io.FileInput;
using StringTools;

class Convert {
	
	var engine : h3d.Engine;
	var time : Float;
	var scene : Scene;
	
	var curFbx : h3d.fbx.Library = null;
	var animMode : h3d.fbx.Library.AnimationMode = h3d.fbx.Library.AnimationMode.LinearAnim;
	var anim : Animation = null;
	
	function new() {
		engine = new h3d.Engine();
		engine.backgroundColor = 0xFF203020;
		engine.onReady = start;
		
		engine.init();
	}
	
	function start() {
		scene = new Scene();
		loadFbx();
	}
	
	function processArgs( args:Array<String>){
		var pathes = [];
		
		for ( i in 0...args.length ) {
			var arg = args[i].toLowerCase();
			switch(arg) {
				case "-m", "--mode": 
					var narg = args[i + 1].toLowerCase();
					switch(narg) {
						case "linear": animMode = h3d.fbx.Library.AnimationMode.LinearAnim;
						case "frame": animMode = h3d.fbx.Library.AnimationMode.FrameAnim;
					}
				default: pathes.push( arg );
			}
		}
		
		return pathes;
	}
	
	function loadFbx(){
		var pathes = null;
		var args = Sys.args();
		trace(args);
		
		if ( args.length < 1 ) {
			pathes = systools.Dialogs.openFile("Open .fbx to convert", "open", 
			{ count:1000, descriptions:[".fbx files"], extensions:["*.fbx", "*.FBX"] } );
			trace("Converting : "+ pathes[0]);
		}
		else pathes = processArgs(args);
		
		for( path in pathes){
			var file = sys.io.File.getContent(path);
			loadData(file);
			save(path);
					
			while (scene.childs.length > 0 )  scene.childs[0].remove();	
				
			curFbx = null;
		}
		
		trace("finished !");
		Sys.exit(0);
	}
	
	function loadData( data : String, newFbx = true ) {
		curFbx = new h3d.fbx.Library();
		var fbx = h3d.fbx.Parser.parse(data);
		curFbx.load(fbx);
		var frame = 0;
		var o : h3d.scene.Object = null;
		scene.addChild(o = curFbx.makeObject( function(str, mat) return null ));
		setSkin();
	}
	
	function setSkin() {
		anim = curFbx.loadAnimation(animMode);
		if ( anim != null ) anim = scene.playAnimation(anim);
		else throw "no animation found";
	}
	
	public function save(path:String){
		
		var aData = anim.toData();
		var out = new haxe.io.BytesOutput();
		var builder = new format.h3d.AnimationWriter(out);
		builder.write(anim);
		
		var bytes = out.getBytes();
		
		var temp = path.split(".");
		temp.splice( temp.length - 1, 1);
		var outpath = temp.join(".") + ".h3d.anim";
		
		trace("Saving : " + outpath);
		
		#if windows 
		outpath = outpath.replace("/", "\\");
		#end
		
		#if flash
		var f = new flash.net.FileReference();
		var ser = Serializer.run(bytes.toString());
		f.save( ByteConversions.bytesToByteArray( bytes) );
		
		#elseif sys
		//trace("saving file " + bytes.length);
		sys.io.File.saveBytes( outpath, bytes );
		#end
	}
	
	static function main() {
		var p = haxe.Log.trace;
		
		trace("STARTUP");
		#if flash
		haxe.Log.setColor(0xFF0000);
		#end
		
		trace("Booting App");
		new Convert();
	}
	
}