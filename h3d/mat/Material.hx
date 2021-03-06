package h3d.mat;
import h2d.BlendMode;
import h3d.mat.Data;

class Material {
	
	var bits : Int;
	
	public var culling(default,set) : Face;
	public var depthWrite(default,set) : Bool;
	public var depthTest(default,set) : Compare;
	
	public var blendSrc(default,set) : Blend;
	public var blendDst(default, set) : Blend;

	public var blendMode(default,set) : h2d.BlendMode;
	
	public var colorMask(default,set) : Int;
	public var shader : h3d.impl.Shader;
	public var renderPass : Int;
	
	public var sampleAlphaToCoverage(default,set):Bool;
	
	public function new(shader) {
		bits = 0;
		renderPass = 0;
		this.shader = shader;
		this.culling = Face.Back;
		this.depthWrite = true;
		this.depthTest = Compare.Less;
		blendMode = None;
		this.colorMask = 15;
		this.sampleAlphaToCoverage = false;
		depth( depthWrite, depthTest);
	}
	
	public inline function getBits() return bits;
	
	public function setup( ctx : h3d.scene.RenderContext ) {
		#if debug
		for ( r in Reflect.fields(this))
			if ( Reflect.getProperty(this,r) == null )
				throw "shader property $r should not be left null";
		#end
	}
	
	public inline function blend(src, dst) {
		blendSrc = src;
		blendDst = dst;
	}
	
	@:noDebug
	public function clone( ?m : Material ) {
		if( m == null ) m = new Material(null);
		m.culling = culling;
		m.depthWrite = depthWrite;
		m.depthTest = depthTest;
		m.blendSrc = blendSrc;
		m.blendDst = blendDst;
		if(blendMode!=null) m.blendMode = blendMode;
		m.renderPass = renderPass;
		m.colorMask = colorMask;
		m.sampleAlphaToCoverage = sampleAlphaToCoverage;
		return m;
	}
	
	public inline function depth( write, test ) {
		this.depthWrite = write;
		this.depthTest = test;
	}
	
	public inline function setColorMask(r, g, b, a) {
		this.colorMask = (r?1:0) | (g?2:0) | (b?4:0) | (a?8:0);
	}

	static inline function bitSet( _v : Int , _i : Int) : Int 						return _v | _i;
	static inline function bitIs( _v : Int , _i : Int) : Bool						return  (_v & _i) == _i;
	static inline function bitClear( _v : Int, _i : Int) : Int 						return (_v & ~_i);
	
	/**
	 * 0:1 cull
	 * 2 depthWrite
	 * 3:5 depthTest
	 * 6:9 blendSrc
	 * 10:13 blendDst
	 * 14:18 colorMask
	 * 20:21 sampleAlphaToCoverage
	 */
	inline function set_culling(f) {
		culling = f;
		bits = (bits & ~(3 << 0)) | (Type.enumIndex(f) << 0);
		return f;
	}
	
	inline function set_depthWrite(b) {
		depthWrite = b;
		bits = (bits & ~(1 << 2)) | ((b ? 1 : 0) << 2);
		return b;
	}
	
	inline function set_depthTest(c) {
		depthTest = c;
		bits = (bits & ~(7 << 3)) | (Type.enumIndex(c) << 3);
		return c;
	}
	
	inline function set_blendSrc(b) {
		blendSrc = b;
		bits = (bits & ~(15 << 6)) | (Type.enumIndex(b) << 6);
		return b;
	}

	inline function set_blendDst(b) {
		blendDst = b;
		bits = (bits & ~(15 << 10)) | (Type.enumIndex(b) << 10);
		return b;
	}
	
	inline function set_colorMask(m) {
		m &= 15;
		colorMask = m;
		bits = (bits & ~(15 << 14)) | (m << 14);
		return m;
	}
	
	inline function set_sampleAlphaToCoverage(v) {
		bits = v ? bitSet( bits, 1 << 20 ) : bitClear( bits, 1 << 20 );
		return v;
	}

	public function toString() {
		return " depthTest:" + depthTest + " depthWrite:" + depthWrite+" cull:" + culling; 
	}
	
	public function set_blendMode(b:h2d.BlendMode) {
		blendMode = b;
		
		switch( b ) {
			case Normal:
				blend(SrcAlpha, OneMinusSrcAlpha);
			case None:
				blend(One, Zero);
			case Add:
				blend(SrcAlpha, One);
			case SoftAdd:
				blend(OneMinusDstColor, One);
			case Multiply:
				blend(DstColor, OneMinusSrcAlpha);
			case Erase:
				blend(Zero, OneMinusSrcAlpha);
			case SoftOverlay:
				blend(DstColor, One);
			case Screen:
				blend(One, OneMinusSrcColor);
		}
		
		return b;
	}
	
	public function ofData(mdata:hxd.fmt.h3d.Data.Material,texLoader:String->h3d.mat.Texture ) {
		culling = mdata.culling;
		blendSrc = mdata.blendSrc;
		blendDst = mdata.blendDest;
		depthTest = mdata.depthTest;
		depthWrite = mdata.depthWrite;
		colorMask = mdata.colorMask;
		renderPass = mdata.renderPass;
		
		if ( mdata.blendMode != null)
			blendMode = mdata.blendMode;
	}
}
