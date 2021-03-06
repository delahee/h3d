import flash.Lib;
import h3d.Engine;
import h3d.impl.Shader;
import h3d.impl.Shaders.LineShader;
import h3d.impl.Shaders.PointShader;
import h3d.mat.Material;
import h3d.mat.MeshMaterial;
import h3d.mat.Texture;
import h3d.prim.Plan2D;
import h3d.prim.Primitive;
import h3d.scene.CustomObject;
import h3d.scene.Scene;
import h3d.scene.Mesh;
import h3d.Vector;
import haxe.CallStack;
import haxe.io.Bytes;
import hxd.BitmapData;
import hxd.Pixels;
import hxd.res.Embed;
import hxd.res.EmbedFileSystem;
import hxd.res.LocalFileSystem;
import hxd.System;
import openfl.Assets;

@:keep
class SpriteShader extends Shader{
	
	#if flash 
		static var SRC = {
			var input : {
				pos : Float3,
				uv : Float2,
			};
			
			var tuv : Float2;
			
			function vertex(mproj:Matrix) {
				var tout = input.pos.xyzw*mproj;
				tuv =  input.uv;
				out = tout;
			}
			
			function fragment( tex : Texture ) {
				var tout = tex.get(tuv.xy);
				out = tout;
			}
		};
	
	#else
	static var VERTEX = "
		attribute vec3 pos;
		attribute vec2 uv;
		
		uniform mat4 mproj;
		
		varying vec2 tuv;
		
		void main(void) {
			gl_Position = vec4(pos,1.0)*mproj;
			tuv = uv;
		}";
		
	static var FRAGMENT = "
		uniform sampler2D tex;
		varying vec2 tuv;
		void main(void) {
			gl_FragColor = texture2D(tex, tuv);
		}
	";
	#end
}


@:keep
class SpriteMaterial extends Material {
	public var tex : Texture;
	var pshader : SpriteShader;
	var ortho : h3d.Matrix;
	public function new(tex) {
		this.tex = tex;
		pshader = new SpriteShader();
		
		ortho = new h3d.Matrix();
		var w = Lib.current.stage.stageWidth;
		var h = Lib.current.stage.stageHeight;
		ortho.makeOrtho(Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		
		super(pshader);
		culling = None;
		depthTest = h3d.mat.Data.Compare.Always;
		depthWrite = false;
		blendMode = Normal;
	}
	
	override function setup( ctx : h3d.scene.RenderContext ) {
		super.setup(ctx);
		pshader.tex = tex;
		pshader.mproj = ortho;
	}
}

@:publicFields
class CustomPlan2D extends Plan2D {
	
	var x : Float;
	var y : Float;
	var z : Float;
	
	var width : Float;
	var height : Float;
	
	override function alloc( engine : h3d.Engine ) {
		
		var v = new hxd.FloatBuffer();
		
		//vertex0
		//vertex0 pos
		v.push( x);
		v.push( y);
		v.push( z);
		
		
		//vertex0 uv
		v.push( 0);
		v.push( 0);

		//vertex1
		v.push( x);
		v.push( y+height);
		v.push( z);
		
		v.push( 0);
		v.push( 1);

		//vertex2
		v.push( x+width);
		v.push( y);
		v.push( z);
		
		v.push( 1);
		v.push( 0);

		//vertex3
		v.push( x+width);
		v.push( y+height);
		v.push( z);
		
		v.push( 1);
		v.push( 1);
		
		//stride : 3+2 = pox.xyz + uv.xy
		buffer = engine.mem.allocVector(v,  3 + 2, 4);
	}
}

class Sprite extends CustomObject {
	
	public var tex(get,set) : Texture;
	
	var sm:SpriteMaterial;
	public function new(tex,parent)
	{
		var prim = new CustomPlan2D();
		prim.x = 1;
		prim.y = 4;
		prim.z = 0;
		prim.width = 200;
		prim.height = 150;
		
		super(prim, sm = new SpriteMaterial(tex),parent);
	}	
	
	function get_tex() {
		return sm.tex;
	}
	
	function set_tex(v) {
		return sm.tex = v;
	}
}

class Demo {
	
	var engine : h3d.Engine;
	var time : Float;
	var scene : Scene;
	
	var sprite  : Sprite;
	
	function new() {
		time = 0;
		engine = new h3d.Engine();
		engine.debug = true;
		engine.backgroundColor = 0xFFcd20cd;
		engine.onReady = start;
		engine.init();
	}
	
	
	function start() {
		trace("start !");
		
		if ( System.debugLevel>=2) trace("prim ok");
		
		scene = new Scene();
		
		function onLoaded( path:String) {
			var tex : Texture = Texture.fromAssets( path );
			
			sprite = new Sprite(tex,scene);
			sprite.tex = tex;
			
			update();
			hxd.System.setLoop(update);
			trace("looping!");
		}
		
		onLoaded("assets/hxlogo.png");
	}
	
	var fr = 0;
	function update() {	
		var dist = 5;
		time += 0.01;
		engine.render(scene);
		engine.restoreOpenfl();
		if (fr++ % 100 == 0) {
			//trace("plouf");
			var a = [0xffFF0000, 0xffFF00FF,0xff0000FF ];
			engine.backgroundColor = a[Std.random( a.length - 1 )];
		}
	}
	
	
	static var lfs: LocalFileSystem;
	static function main() {
		
		#if flash
		haxe.Log.setColor(0xFF0000);
		#end
		
		new Demo();
	}
	
}