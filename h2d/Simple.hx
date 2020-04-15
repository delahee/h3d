package h2d;
import h3d.Engine;
import h3d.Vector;
import hxd.Profiler;

class SimpleShader extends h3d.impl.Shader {
	#if flash
	public override function clone(?c:h3d.impl.Shader) : h3d.impl.Shader {
		var n : SimpleShader = (c != null) ? cast c :Type.createEmptyInstance( cast Type.getClass(this) );
		super.clone( n );
		return n;
	}
	
	static var SRC = {
		var input : {
			pos : Float2,
			uv : Float2,
		};
		var tuv : Float2;
		var uvScale : Float2;
		var uvPos : Float2;
			
		var zValue : Float;
		var pixelAlign : Bool;
		var texelAlign : Bool;
		var halfPixelInverse 	: Float2;
		var halfTexelInverse	: Float2;
		
		var texResolution 		: Float2;
		var texResolutionFS 	: Float2;
		
		function vertex( size : Float3, matA : Float3, matB : Float3 ) {
			var tmp : Float4;
			var spos = input.pos.xyw;
			if( size != null ) spos *= size;
			tmp.x = spos.dp3(matA);
			tmp.y = spos.dp3(matB);
			tmp.z = zValue;
			tmp.w = 1;
			if ( pixelAlign )
				tmp.xy -= halfPixelInverse;
			out = tmp;
			var t = input.uv;
			if ( uvScale != null ) t *= uvScale;
			if ( uvPos != null ) t += uvPos;
			if ( texelAlign )
				t.xy += halfTexelInverse;
			tuv = t;
		}
		
		var filter : Bool;
		var tileWrap : Bool;
		
		function fragment( tex : Texture ) {
			var tcoord = tuv;
			
			var col:Float4;
			col = tex.get(tcoord, filter = ! !filter, wrap = tileWrap);

			out = col;
		}
	}
	
	#elseif (js || cpp)
	
	public override function clone(?c:h3d.impl.Shader) {
		hxd.Profiler.begin("shader clone");
		var cl = Type.getClass(this);
		var n = (c != null) ? (cast c) : Type.createEmptyInstance( cast cl );
		super.clone(n);
		for ( c in Type.getInstanceFields(cl)) {
			var	val =  Reflect.getProperty( this, c );
			if( !Reflect.isFunction(val ))
				Reflect.setField( n, c, val);
		}
		hxd.Profiler.end("shader clone");
		return n;
	}
	
	public var filter : Bool;				
	public var tileWrap : Bool;	        
	
	/**
	 * This is the constant set, they are set / compiled for first draw and will enabled on all render thereafter
	 * 
	 */
	override function getConstants( cst : hxd.Stack<String>, vertex : Bool ) : hxd.Stack<String>{
		var engine = h3d.Engine.getCurrent();
		
		if( vertex ) {
			if( size != null ) cst.push("#define hasSize");
			if( uvScale != null ) cst.push("#define hasUVScale");
			if( uvPos != null ) cst.push("#define hasUVPos");
		} 
		
		return cst;
	}
	
	static var VERTEX = "
	
		attribute vec2 pos;
		attribute vec2 uv;
		
		varying vec2 tuv;
		
		uniform vec2 texResolution;
		
		#if hasSize
		uniform vec3 size;
		#end
		
		uniform vec3 matA;
		uniform vec3 matB;
		uniform float zValue;
		
		#if hasUVPos
		uniform vec2 uvPos;
		#end
        #if hasUVScale
		uniform vec2 uvScale;
		#end

		void main(void) {
			vec3 spos = vec3(pos.x,pos.y, 1.0);
			#if hasSize
				spos = spos * size;
			#end
			vec4 tmp;
			tmp.x = dot(spos,matA);
			tmp.y = dot(spos,matB);
			tmp.z = zValue;
			tmp.w = 1.;
			gl_Position = tmp;
			lowp vec2 t = uv;
			#if hasUVScale
				t *= uvScale;
			#end
			#if hasUVPos
				t += uvPos;
			#end
			tuv = t;
		}
	";
	
	static var FRAGMENT = "
		varying vec2 tuv;
		
		uniform sampler2D tex;
		uniform vec2 texResolutionFS;
		
		void main(void) {
			gl_FragColor = texture2D(tex, tuv);
		}
	";
	
	#end
}

class Simple extends h2d.Sprite {
	
	public static inline var HAS_SIZE = 1;
	public static inline var HAS_UV_SCALE = 2;
	public static inline var HAS_UV_POS = 4;
	public static inline var BASE_TILE_DONT_CARE = 8;

	public var shader : SimpleShader;
	
	//public var alpha(get, set) : Float;
	
	public var filter(get, set) : Bool;
	public var blendMode(default, set) : BlendMode;
	public var tileWrap(get, set) : Bool;
	
	public static var DEFAULT_EMIT = false;
	public static var DEFAULT_FILTER = false;
		
	public var tile : Tile;

	public function new(parent, ?sh:SimpleShader) {
		super(parent);
		
		blendMode = Normal;
		
		shader = (sh == null) ? new SimpleShader() : cast sh;
		shader.zValue = 0;
		filter = DEFAULT_FILTER;
		
		shader.texResolution 	= new h3d.Vector(0, 0, 0, 0);
		shader.texResolutionFS 	= new h3d.Vector(0, 0, 0, 0);
		
		tile = h2d.Tile.fromTexture(h2d.Tools.getWhiteTexture());
	}

	public override function clone<T>( ?s:T ) : T {
		if ( s == null ) {
			var cl : Class<T> = cast Type.getClass(this);
			throw "impossible hierarchy cloning. Cloning not yet implemented for " + Std.string(cl);
		}
			
		var d : Simple = cast s;
		
		super.clone(s);
		
		d.blendMode = blendMode;
		d.filter = filter;
		
		return cast d;
	}
	
	function set_blendMode(b) {
		blendMode = b;
		return b;
	}

	inline function get_filter() {
		return shader.filter;
	}
	
	inline function set_filter(v) {
		return shader.filter = v;
	}

	function get_tileWrap() {
		return shader.tileWrap;
	}
	
	function set_tileWrap(v) {
		return shader.tileWrap = v;
	}
	
	static var tmpColor = h3d.Vector.ONE.clone();
	
	function drawTile( ctx:RenderContext, tile ) {
		ctx.flush();
		setupShader(ctx.engine, tile, HAS_SIZE | HAS_UV_POS | HAS_UV_SCALE);
		ctx.engine.renderQuadBuffer(Tools.getCoreObjects().planBuffer);
	}
	
	function setupShader( engine : h3d.Engine, tile : h2d.Tile, options : Int ) {
		var core = Tools.getCoreObjects();
		var shader = shader;
		var mat = core.tmpMaterial;
		
		if ( tile == null ) 
			return;

		var tex : h3d.mat.Texture = tile.getTexture();
		
		var oldFilter = tex.filter;
		if( tex!=null){
			tex.filter = (filter)? Linear:Nearest;
		}
		
		switch( blendMode ) {
			case Normal:
				mat.blend(SrcAlpha, OneMinusSrcAlpha);
				
			case None:
				mat.blend(One, Zero);
				mat.sampleAlphaToCoverage = false;
				
			case Add:
				mat.blend(SrcAlpha, One);
			case SoftAdd:
				mat.blend(OneMinusDstColor, One);
			case Multiply:
				mat.blend(DstColor, OneMinusSrcAlpha);
			case Erase:
				mat.blend(Zero, OneMinusSrcAlpha);
			case SoftOverlay:
				mat.blend(DstColor, One);
			case Screen:
				mat.blend(One, OneMinusSrcColor);
		}
		
		if( options & HAS_SIZE != 0 ) {
			var tmp = core.tmpSize;
			tmp.x = tile.width;
			tmp.y = tile.height;
			tmp.z = 1;
			shader.size = tmp;
		}
		
		if( options & HAS_UV_POS != 0 ) {
			core.tmpUVPos.x = tile.u;
			core.tmpUVPos.y = tile.v;
			
			shader.uvPos = core.tmpUVPos;
		}
		
		if( options & HAS_UV_SCALE != 0 ) {
			core.tmpUVScale.x = tile.u2 - tile.u;
			core.tmpUVScale.y = tile.v2 - tile.v;
			
			shader.uvScale = core.tmpUVScale;
		}
		
		mat.colorMask = 7;
		
		var tmp = core.tmpMatA;
		tmp.x = matA;
		tmp.y = matC;
		
		if ( options & BASE_TILE_DONT_CARE!=0 ) tmp.z = absX;
		else tmp.z = absX + tile.dx * matA + tile.dy * matC;
		
		shader.matA = tmp;
		var tmp = core.tmpMatB;
		tmp.x = matB;
		tmp.y = matD;
		
		if ( options & BASE_TILE_DONT_CARE!=0 )	tmp.z = absY
		else 									tmp.z = absY + tile.dx * matB + tile.dy * matD;
		
		shader.texResolution.x = 1.0 / tex.width;
		shader.texResolution.y = 1.0 / tex.height;
		shader.texResolutionFS.load( shader.texResolution);
		
		shader.matB = tmp;
		shader.tex = tile.getTexture();
		
		mat.shader = shader;
		engine.selectMaterial(mat);
		
		tex.filter = oldFilter;
	}
	
	public override function set_width(w:Float):Float {
		scaleX = w / tile.width;
		return w;
	}
	
	public override function set_height(h:Float):Float {
		scaleY = h / tile.height;
		return h;
	}
	
	override function draw( ctx : RenderContext ) {		
		drawTile(ctx, tile);	
	}
	
	public function canEmit() {
		return false;
	}
	
}
