package h2d;
import h3d.Vector;

class DrawableShader extends h3d.impl.Shader {
	#if flash
	static var SRC = {
		var input : {
			pos : Float2,
			uv : Float2,
			valpha : Float,
			vcolor : Float4,
		};
		var tuv : Float2;
		var tcolor : Float4;
		var talpha : Float;

		var hasVertexColor : Bool;
		var hasVertexAlpha : Bool;
		var uvScale : Float2;
		var uvPos : Float2;
		var zValue : Float;

		function vertex( size : Float3, matA : Float3, matB : Float3 ) {
			var tmp : Float4;
			var spos = input.pos.xyw;
			if( size != null ) spos *= size;
			tmp.x = spos.dp3(matA);
			tmp.y = spos.dp3(matB);
			tmp.z = zValue;
			tmp.w = 1;
			out = tmp;
			var t = input.uv;
			if( uvScale != null ) t *= uvScale;
			if( uvPos != null ) t += uvPos;
			tuv = t;
			if( hasVertexColor ) tcolor = input.vcolor;
			if( hasVertexAlpha ) talpha = input.valpha;
		}
		
		var hasAlpha : Bool;
		var killAlpha : Bool;
		
		var alpha : Float;
		var colorAdd : Float4;
		var colorMul : Float4;
		var colorMatrix : M44;

		var hasAlphaMap : Bool = false;
		
		var alphaMap : Texture;
		var alphaUV : Float4;
		var filter : Bool;
		
		var sinusDeform : Float3;
		var tileWrap : Bool;

		var hasMultMap : Bool;
		var multMapFactor : Float;
		var multMap : Texture;
		var multUV : Float4;
		var hasColorKey : Bool;
		var colorKey : Int;
		
		var isAlphaPremul:Bool;
		var hasHighPass:Bool;
		var recolorize:Bool;
		var hasBlur2x2:Bool;

		function fragment( tex : Texture ) {
			var sample = [0, 0, 0, 0];
			
			if ( hasBlur2x2) {
				var k = 0.0005;
				sample += tex.get(tuv + [k,k], filter = ! !filter, wrap = tileWrap) * 0.25;
				sample += tex.get(tuv + [k,-k], filter = ! !filter, wrap = tileWrap) * 0.25;
				sample += tex.get(tuv + [-k,k], filter = ! !filter, wrap = tileWrap) * 0.25;
				sample += tex.get(tuv + [-k,-k], filter = ! !filter, wrap = tileWrap) * 0.25;
			}
			else 
				sample = tex.get(sinusDeform != null ? [tuv.x + sin(tuv.y * sinusDeform.y + sinusDeform.x) * sinusDeform.z, tuv.y] : tuv, filter = ! !filter, wrap = tileWrap);
			
			var col = sample;
			
			if( hasColorKey ) {
				var cdiff = col.rgb - colorKey.rgb;
				kill(cdiff.dot(cdiff) - 0.001);
			}
			if ( killAlpha ) kill(col.a - 0.001);
			
			if ( isAlphaPremul ) 
				col.rgb /= col.a;
				
			if( hasVertexAlpha ) 		col.a *= talpha;
			if( hasVertexColor ) 		col *= tcolor;
			if( hasAlphaMap ) 			col.a *= alphaMap.get(tuv * alphaUV.zw + alphaUV.xy).r;
			if( hasMultMap ) 			col *= multMap.get(tuv * multUV.zw + multUV.xy) * multMapFactor;
			if( hasAlpha ) 				col.a *= alpha;
			if( colorMatrix != null ) 	col *= colorMatrix;
			if( colorMul != null ) 		col *= colorMul;
			if( colorAdd != null ) 		col += colorAdd;
			
			if (hasHighPass) {
				var middleGray = 0.18;
				var luminance = 0.081;
				var whiteCutoff = 0.8;
				var whiteCutoff2 = whiteCutoff*whiteCutoff;
				
				col.rgb *= middleGray / luminance;
				col.rgb *= 1.0 + (col.rgb / whiteCutoff2);
				col.rgb -= 5.0;
				
				col.rgb = max(col.rgb, 0.0);
				
				col.rgb /= 10.0 + col.rgb;
			}
			
			if ( recolorize ) {
				col.rgb = sample.rgb;
			}
			
			if( isAlphaPremul ) 
				col.rgb *= col.a;
			
			out = col;
		}


	}
	
	#elseif (js || cpp)
	
	// not supported
	public var sinusDeform : h3d.Vector;
	public var hasColorKey(default,set) : Bool;			public function set_hasColorKey(v)		{ if( hasColorKey != v ) 	invalidate();  return hasColorKey = v; }
		
	public var filter : Bool;				
	
	//not supported
	public var tileWrap : Bool;	        
	
	//
	public var killAlpha(default, set) : Bool;	        public function set_killAlpha(v) 		{ if( killAlpha != v )		invalidate();  	return killAlpha = v; }
	
	public var hasAlpha(default,set) : Bool;	        public function set_hasAlpha(v)			{ if( hasAlpha != v ) 		invalidate();  	return hasAlpha = v; }
	public var hasVertexAlpha(default,set) : Bool;	    public function set_hasVertexAlpha(v)	{ if( hasVertexAlpha != v ) invalidate();  	return hasVertexAlpha = v; }
	public var hasVertexColor(default,set) : Bool;	    public function set_hasVertexColor(v)	{ if( hasVertexColor != v ) invalidate();  	return hasVertexColor = v; }
	public var hasAlphaMap(default,set) : Bool;	        public function set_hasAlphaMap(v)		{ if( hasAlphaMap != v ) 	invalidate();  	return hasAlphaMap = v; }
	public var hasMultMap(default,set) : Bool;	        public function set_hasMultMap(v)		{ if( hasMultMap != v ) 	invalidate();  	return hasMultMap = v; }
	public var isAlphaPremul(default,set) : Bool;       public function set_isAlphaPremul(v)	{ if( isAlphaPremul != v ) 	invalidate();  	return isAlphaPremul = v; }
		
	/**
	 * This is the constant set, they are set / compiled for first draw and will enabled on all render thereafter
	 * 
	 */
	override function getConstants( vertex : Bool ) {
		var cst = [];
		if( vertex ) {
			if( size != null ) cst.push("#define hasSize");
			if( uvScale != null ) cst.push("#define hasUVScale");
			if( uvPos != null ) cst.push("#define hasUVPos");
		} else {
			if( killAlpha ) cst.push("#define killAlpha");
			if( hasColorKey ) cst.push("#define hasColorKey");
			if( hasAlpha ) cst.push("#define hasAlpha");
			if( colorMatrix != null ) cst.push("#define hasColorMatrix");
			if( colorMul != null ) cst.push("#define hasColorMul");
			if( colorAdd != null ) cst.push("#define hasColorAdd");
		}
		if( hasVertexAlpha ) cst.push("#define hasVertexAlpha");
		if( hasVertexColor ) cst.push("#define hasVertexColor");
		if( hasAlphaMap ) cst.push("#define hasAlphaMap");
		if( hasMultMap ) cst.push("#define hasMultMap");
		if( isAlphaPremul ) cst.push("#define isAlphaPremul");
		return cst.join("\n");
	}
	
	static var VERTEX = "
	
		attribute vec2 pos;
		attribute vec2 uv;
		#if hasVertexAlpha
		attribute float valpha;
		varying lowp float talpha;
		#end
		#if hasVertexColor
		attribute vec4 vcolor;
		varying lowp vec4 tcolor;
		#end

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
		
		varying vec2 tuv;

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
			#if hasVertexAlpha
				talpha = valpha;
			#end
			#if hasVertexColor
				tcolor = vcolor;
			#end
		}

	";
	
	static var FRAGMENT = "
	
		varying vec2 tuv;
		uniform sampler2D tex;
		
		#if hasVertexAlpha
		varying float talpha;
		#end
		
		#if hasVertexColor
		varying vec4 tcolor;
		#end
		
		#if hasAlphaMap
			uniform vec4 alphaUV;
			uniform sampler2D alphaMap;
		#end
		
		#if hasMultMap
			uniform float multMapFactor;
			uniform vec4 multUV;
			uniform sampler2D multMap;
		#end
		
		uniform float alpha;
		uniform vec3 colorKey/*byte4*/;
	
		uniform vec4 colorAdd;
		uniform vec4 colorMul;
		uniform mat4 colorMatrix;

		void main(void) {
			vec4 col = texture2D(tex, tuv).rgba;
			
			#if killAlpha
				if( col.a - 0.001 <= 0.0 ) discard;
			#end
			
			#if hasColorKey
				vec3 dc = col.rgb - colorKey;
				if( dot(dc, dc) < 0.001 ) discard;
			#end
			
			#if isAlphaPremul
				col.rgb /= col.a;
			#end 
			
			#if hasVertexAlpha
				col.a *= talpha;
			#end 
			
			#if hasVertexColor
				col *= tcolor;
			#end
			
			
			#if hasAlphaMap
				col.a *= texture2D( alphaMap, tuv * alphaUV.zw + alphaUV.xy ).r;
			#end
			
			
			#if hasMultMap
				col *= multMapFactor * texture2D(multMap,tuv * multUV.zw + multUV.xy);
			#end
			
			#if hasAlpha
				col.a *= alpha;
			#end
			#if hasColorMatrix
				col *= colorMatrix;
			#end
			#if hasColorMul
				col *= colorMul;
			#end
			#if hasColorAdd
				col += colorAdd;
			#end
			
			#if isAlphaPremul
				col.rgb *= col.a;
			#end 
			
			gl_FragColor = col;
		}
			
	";
	
	#end
}

class Drawable extends Sprite {
	
	public static inline var HAS_SIZE = 1;
	public static inline var HAS_UV_SCALE = 2;
	public static inline var HAS_UV_POS = 4;
	public static inline var BASE_TILE_DONT_CARE = 8;

	public var shader(default,null) : DrawableShader;
	
	//public var alpha(get, set) : Float;
	
	public var filter(get, set) : Bool;
	public var color(get, set) : h3d.Vector;
	public var colorAdd(get, set) : h3d.Vector;
	
	/*
	 * rr gr br ar
	 * rg gg bg ag
	 * rb gb bb ab
	 * ra ga ba aa
	 * for offsets ( the fifth vector of flash matrix 45 transform use the colorAdd )
	*/
	public var colorMatrix(get, set) : h3d.Matrix;
	
	public var blendMode(default, set) : BlendMode;
	
	public var sinusDeform(get, set) : h3d.Vector;
	
	/**
	 * Sets the uv of the alphamap point to sample, beware format is u,v,u2-u, v2-v
	 * ...i think...
	 */
	public var alphaUV(default,set) : h3d.Vector;
	
	public var tileWrap(get, set) : Bool;
	public var killAlpha(get, set) : Bool;
	
	public var alphaMap(default, set) : h2d.Tile;

	public var multiplyMap(default, set) : h2d.Tile;
	public var multiplyFactor(get, set) : Float;
	
	public var colorKey(get, set) : Int;
	
	public var writeAlpha : Bool;
	
	/**
	 * Passing in a similar shader will vastly improve performances
	 */
	function new(parent, ?sh:DrawableShader) {
		super(parent);
		
		writeAlpha = true;
		blendMode = Normal;
		
		shader = (sh==null)?new DrawableShader():sh;
		shader.alpha = 1;
		shader.multMapFactor = 1.0;
		shader.zValue = 0;
		
	}
		
	public var alpha(get, set) : Float;
	public var hasAlpha(get, set):Bool;				
	
	function get_hasAlpha() return shader.hasAlpha; 
	function set_hasAlpha(v) return shader.hasAlpha = v;
	
	function get_alpha() return shader.alpha;
	function set_alpha( v : Float ) {
		shader.alpha = v;
		
		var oha = shader.hasAlpha;
		shader.hasAlpha = v < 1;
		
		return v;
	}
	
	function set_blendMode(b) {
		blendMode = b;
		return b;
	}
	
	
	inline function get_multiplyFactor() {
		return shader.multMapFactor;
	}

	inline function set_multiplyFactor(v) {
		return shader.multMapFactor = v;
	}
	
	function set_multiplyMap(t:h2d.Tile) {
		multiplyMap = t;
		shader.hasMultMap = t != null;
		return t;
	}
	
	function set_alphaMap(t:h2d.Tile) {
		if( t != null && alphaMap == null 
		||	t == null && alphaMap != null )
			shader.invalidate();
		
		alphaMap = t;
		shader.hasAlphaMap = t != null;
		
		if ( t == null) { //clean a bit
			alphaUV = null;
			shader.alphaUV = null;
		}
		
		return t;
	}

	inline function set_alphaUV(v) {
		alphaUV=v;
		return v;
	}
	
	inline function get_sinusDeform() {
		return shader.sinusDeform;
	}

	inline function set_sinusDeform(v) {
		return shader.sinusDeform = v;
	}
	
	function get_colorMatrix() {
		return shader.colorMatrix;
	}
	
	function set_colorMatrix(m) {
		
		if ( 	shader.colorMatrix == null && m != null 
		||		shader.colorMatrix != null && m == null )
			shader.invalidate();
			
		return shader.colorMatrix = m;
	}
	
	function set_color(m) {
		
		if ( 	shader.colorMul == null && m != null 
		||		shader.colorMul != null && m == null )
			shader.invalidate();
			
		return shader.colorMul = m;
	}

	function set_colorAdd(m) {
		
		if ( 	shader.colorAdd == null && m != null 
		||		shader.colorAdd != null && m == null )
			shader.invalidate();
			
		return shader.colorAdd = m;
	}

	function get_colorAdd() {
		return shader.colorAdd;
	}
	
	function get_color() {
		return shader.colorMul;
	}	

	function get_filter() {
		return shader.filter;
	}
	
	function set_filter(v) {
		return shader.filter = v;
	}

	function get_tileWrap() {
		return shader.tileWrap;
	}
	
	function set_tileWrap(v) {
		return shader.tileWrap = v;
	}

	function get_killAlpha() {
		return shader.killAlpha;
	}
	
	function set_killAlpha(v) {
		return shader.killAlpha = v;
	}

	function get_colorKey() {
		return shader.colorKey;
	}
	
	function set_colorKey(v) {
		shader.hasColorKey = true;
		return shader.colorKey = v;
	}
	
	static var tmpColor = h3d.Vector.ONE.clone();
	
	function emitTile( ctx : h2d.RenderContext, tile : Tile ) {
		hxd.Profiler.begin("emitTile");
		var tile = tile == null ? h2d.Tools.getEmptyTile() : tile;
		
		tmpColor.load(this.color == null ? h3d.Vector.ONE : this.color);
		var color = tmpColor;
		color.a *= alpha;
		var texSlot = ctx.beginDraw(this, tile.getTexture() );
		
		var ax = absX + tile.dx * matA + tile.dy * matC;
		var ay = absY + tile.dx * matB + tile.dy * matD;
		
		#if flash 
		ax -= 0.5 * ctx.engine.width;
		ay -= 0.5 * ctx.engine.height;
		#end
		
		var u = tile.u;
		var v = tile.v;
		var u2 = tile.u2;
		var v2 = tile.v2;
		var tw = tile.width;
		var th = tile.height;
		var dx1 = tw * matA;
		var dy1 = tw * matB;
		var dx2 = th * matC;
		var dy2 = th * matD;

		ctx.emitVertex( 
			ax, ay, u, v,
			color, texSlot);
		
		ctx.emitVertex( 
			ax + dx1,
			ay + dy1,
			u2, v,
			color,
			texSlot);

		ctx.emitVertex( 
			ax + dx2,
			ay + dy2,
			u, v2,
			color,
			texSlot);

		ctx.emitVertex( 
			ax + dx1 + dx2,
			ay + dy1 + dy2,
			u2, v2,
			color, texSlot);
			
		hxd.Profiler.end("emitTile");
	}
	
	function drawTile( ctx:RenderContext, tile ) {
		ctx.flush();
		shader.hasVertexColor = false;
		setupShader(ctx.engine, tile, HAS_SIZE | HAS_UV_POS | HAS_UV_SCALE);
		ctx.engine.renderQuadBuffer(Tools.getCoreObjects().planBuffer);
	}
	
	function setupShader( engine : h3d.Engine, tile : h2d.Tile, options : Int ) {
		var core = Tools.getCoreObjects();
		var shader = shader;
		var mat = core.tmpMaterial;
		
		if ( tile == null ) {
			#if debug
			hxd.System.trace2("using default empty texture...");
			#end
			tile = new Tile(core.getEmptyTexture(), 0, 0, 4, 4);
		}

		var tex : h3d.mat.Texture = tile.getTexture();
		var isTexPremul = false;
		if( tex!=null){
			tex.filter = (filter)? Linear:Nearest;
			isTexPremul = tex.flags.has(AlphaPremultiplied);
		}
		
		switch( blendMode ) {
			case Normal:
				mat.blend(isTexPremul ? One : SrcAlpha, OneMinusSrcAlpha);
				
			case None:
				mat.blend(One, Zero);
				mat.sampleAlphaToCoverage = false;
				if( killAlpha ){
					if ( engine.driver.hasFeature( SampleAlphaToCoverage )) {
						shader.killAlpha = false;
						mat.sampleAlphaToCoverage = true;
					}
				}
				
			case Add:
				mat.blend(isTexPremul ? One : SrcAlpha, One);
			case SoftAdd:
				mat.blend(OneMinusDstColor, One);
			case Multiply:
				mat.blend(DstColor, OneMinusSrcAlpha);
			case Erase:
				mat.blend(Zero, OneMinusSrcAlpha);
			case SoftOverlay:
				mat.blend(DstColor, One);
		}
		
		#if sys
		switch( blendMode ) {
			default:			shader.leavePremultipliedColors = false;
			case SoftOverlay:	shader.leavePremultipliedColors = true;
		}
		#end

		if( options & HAS_SIZE != 0 ) {
			var tmp = core.tmpSize;
			// adds 1/10 pixel size to prevent precision loss after scaling
			tmp.x = tile.width + 0.1;
			tmp.y = tile.height + 0.1;
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
		
		if( shader.hasAlphaMap ) {
			shader.alphaMap = alphaMap.getTexture();
			
			if ( alphaUV == null ) {
				if ( shader.alphaUV == null ) shader.alphaUV = new Vector(0, 0, 1, 1);
				shader.alphaUV.set(alphaMap.u, alphaMap.v, (alphaMap.u2 - alphaMap.u) / tile.u2, (alphaMap.v2 - alphaMap.v) / tile.v2);
			}
			else {
				if ( shader.alphaUV == null ) shader.alphaUV = new Vector(0, 0, 1, 1);
				shader.alphaUV.load(alphaUV);
			}
		}

		if( shader.hasMultMap ) {
			shader.multMap = multiplyMap.getTexture();
			shader.multUV = new h3d.Vector(multiplyMap.u, multiplyMap.v, (multiplyMap.u2 - multiplyMap.u) / tile.u2, (multiplyMap.v2 - multiplyMap.v) / tile.v2);
		}
		
		var cm = writeAlpha ? 15 : 7;
		if( mat.colorMask != cm ) mat.colorMask = cm;
		
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
		
		shader.matB = tmp;
		shader.tex = tile.getTexture();
		
		shader.isAlphaPremul = tex.flags.has(AlphaPremultiplied)
		&& (shader.hasAlphaMap || shader.hasAlpha || shader.hasMultMap 
		|| shader.hasVertexAlpha || shader.hasVertexColor 
		|| shader.colorMatrix != null || shader.colorAdd != null
		|| shader.colorMul != null );
		
		mat.shader = shader;
		engine.selectMaterial(mat);
	}
	
	/**
	 * isExoticShader means shader it too complex and we haven't made the work to make either shader parameter flushing or inlined the parameter in the vertex buffers
	 */
	public function isExoticShader() {
		return shader.hasMultMap 
		|| shader.hasAlphaMap 
		|| shader.hasColorKey 
		|| shader.colorMatrix != null 
		|| shader.colorAdd != null 
		|| shader.hasMultMap;
	}

	inline function hasSampleAlphaToCoverage() return h3d.Engine.getCurrent().driver.hasFeature( SampleAlphaToCoverage );
	
	public inline function canEmit() {
		#if (flash||noEmit)
			return false;
		#else
		if ( isExoticShader() || ! emit)	return false;
		else  								return true;
		#end
	}
	
}
