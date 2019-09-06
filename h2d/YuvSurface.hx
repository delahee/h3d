package h2d;
import h3d.Engine;
import h3d.Vector;
import hxd.Profiler;

class YuvShader extends h3d.impl.Shader {
	#if flash
	public override function clone(?c:h3d.impl.Shader) : h3d.impl.Shader {
		var n : YuvShader = (c != null) ? cast c :Type.createEmptyInstance( cast Type.getClass(this) );
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
		
		var srcBias : Float3;
		var srcXForm : M33;
		
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
		
		function fragment( texY : Texture, texUV : Texture) {
			var tcoord = tuv;
			
			var y:Float 			= texY.get(tcoord, filter = ! !filter, wrap = tileWrap).r;
			var cbcr 	: Float2 	= texUV.get(tcoord, filter = ! !filter, wrap = tileWrap).rg;
			var yuv 	: Float3 	= [y, cbcr.x, cbcr.y];
			
			yuv 		-= srcBias;
			yuv 		*= srcXForm;
			out 		= [yuv.x,yuv.y,yuv.z,1.0];
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
	
	/*
	public function new (){
		super();
		version = "140";
	}
	*/
	
	/**
	 * This is the constant set, they are set / compiled for first draw and will enabled on all render thereafter
	 * 
	 */
	override function getConstants( vertex : Bool ) {
		var engine = h3d.Engine.getCurrent();
		
		var cst = [];
		if( vertex ) {
			if ( size != null ) cst.push("#define hasSize");
			if( uvScale != null ) cst.push("#define hasUVScale");
			if( uvPos != null ) cst.push("#define hasUVPos");
		} 
		
		return cst.join("\n");
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
		
		uniform vec2 texResolutionFS;
		
		uniform sampler2D 	texY;
		uniform sampler2D 	texUV;
		
		uniform vec3		srcBias;
		uniform mat3		srcXForm;
		
		void main(void) {
			vec2 tcoord = tuv;
			
			float y		= texture2D(texY,tcoord).r;
			vec2 cbcr 	= texture2D(texUV,tcoord).rg;
			vec3 yuv 	= vec3(y, cbcr.x, cbcr.y);
			
			yuv 		-= srcBias;
			yuv 		*= srcXForm;
			
			gl_FragColor = vec4(yuv.x, yuv.y, yuv.z, 1.0);
		}
	";
	
	#end
}

class YuvSurface extends h2d.Sprite {
	
	public static inline var HAS_SIZE = 1;
	public static inline var HAS_UV_SCALE = 2;
	public static inline var HAS_UV_POS = 4;
	public static inline var BASE_TILE_DONT_CARE = 8;

	public var shader : YuvShader;
	
	//public var alpha(get, set) : Float;
	
	public var filter(get, set) : Bool;
	public var blendMode(default, set) : BlendMode;
	public var tileWrap(get, set) : Bool;
	
	public var srcBias(get,set) : Vector;
	public var srcXForm(get,set) : h3d.Matrix;
	
	public static var DEFAULT_EMIT = false;
	public static var DEFAULT_FILTER = false;
		
	public var texY : h3d.mat.Texture;
	public var texUV : h3d.mat.Texture;
	
	var tileY : Tile;
	var tileUV : Tile;

	public function new(parent, ?sh:YuvShader) {
		super(parent);
		
		blendMode = Normal;
		
		shader = (sh == null) ? new YuvShader() : cast sh;
		shader.zValue = 0;
		filter = DEFAULT_FILTER;
		
		shader.texResolution 	= new h3d.Vector(0, 0, 0, 0);
		shader.texResolutionFS 	= new h3d.Vector(0, 0, 0, 0);
		
		texY = h2d.Tools.getWhiteTexture();
		texUV = h2d.Tools.getWhiteTexture();
		
		tileY = h2d.Tile.fromTexture(h2d.Tools.getWhiteTexture());
		tileUV = h2d.Tile.fromTexture(h2d.Tools.getWhiteTexture());
		
		srcXForm = new h3d.Matrix();
		srcBias = new h3d.Vector();
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

	function get_tileWrap() 	return shader.tileWrap;
	function set_tileWrap(v) 	return shader.tileWrap = v;
	
	function get_srcBias()		return shader.srcBias;
	function set_srcBias(v:Vector){
		shader.srcBias = v;
		return srcBias;
	}
	
	function get_srcXForm()		return shader.srcXForm;
	function set_srcXForm(v : h3d.Matrix){
		shader.srcXForm = v;
		return srcXForm;
	}
	
	static var tmpColor = h3d.Vector.ONE.clone();
	
	function drawTile( ctx:RenderContext ) {
		ctx.flush();
		setupShader(ctx.engine,  HAS_SIZE | HAS_UV_POS | HAS_UV_SCALE);
		ctx.engine.renderQuadBuffer(Tools.getCoreObjects().planBuffer);
	}
	
	function setupShader( engine : h3d.Engine, options : Int ) {
		var core = Tools.getCoreObjects();
		var shader = shader;
		var mat = core.tmpMaterial;
		
		if ( tileY == null ) 
			return;

		var texY : h3d.mat.Texture = tileY.getTexture();
		var oldFilter = texY.filter;
		if( texY!=null){
			texY.filter = (filter)? Linear:Nearest;
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
			tmp.x = tileY.width;
			tmp.y = tileY.height;
			tmp.z = 1;
			shader.size = tmp;
		}
		
		if( options & HAS_UV_POS != 0 ) {
			core.tmpUVPos.x = tileY.u;
			core.tmpUVPos.y = tileY.v;
			
			shader.uvPos = core.tmpUVPos;
		}
		
		if( options & HAS_UV_SCALE != 0 ) {
			core.tmpUVScale.x = tileY.u2 - tileY.u;
			core.tmpUVScale.y = tileY.v2 - tileY.v;
			
			shader.uvScale = core.tmpUVScale;
		}
		
		mat.colorMask = 7;
		
		var tmp = core.tmpMatA;
		tmp.x = matA;
		tmp.y = matC;
		
		if ( options & BASE_TILE_DONT_CARE!=0 ) tmp.z = absX;
		else tmp.z = absX + tileY.dx * matA + tileY.dy * matC;
		
		shader.matA = tmp;
		var tmp = core.tmpMatB;
		tmp.x = matB;
		tmp.y = matD;
		
		if ( options & BASE_TILE_DONT_CARE!=0 )	tmp.z = absY
		else 									tmp.z = absY + tileY.dx * matB + tileY.dy * matD;
		
		shader.texResolution.x = 1.0 / texY.width;
		shader.texResolution.y = 1.0 / texY.height;
		shader.texResolutionFS.load( shader.texResolution);
		
		shader.matB = tmp;
		shader.texY = tileY.getTexture();
		shader.texUV = tileUV.getTexture();
		
		mat.shader = shader;
		engine.selectMaterial(mat);
		
		texY.filter = oldFilter;
	}
	
	public override function set_width(w:Float):Float {
		scaleX = w / tileY.width;
		return w;
	}
	
	public override function set_height(h:Float):Float {
		scaleY = h / tileY.height;
		return h;
	}
	
	override function draw( ctx : RenderContext ) {		
		drawTile(ctx);	
	}
	
	public function canEmit() {
		return false;
	}
	
}
