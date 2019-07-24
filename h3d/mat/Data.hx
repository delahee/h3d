package h3d.mat;

enum Face {
	None;
	Back;
	Front;
	Both;
}

enum Blend {
	One;
	Zero;
	SrcAlpha;
	SrcColor;
	DstAlpha;
	DstColor;
	OneMinusSrcAlpha;
	OneMinusSrcColor;
	OneMinusDstAlpha;
	OneMinusDstColor;
	// only supported on WebGL
	ConstantColor;
	ConstantAlpha;
	OneMinusConstantColor;
	OneMinusConstantAlpha;
	SrcAlphaSaturate;
}

enum Compare {
	Always;
	Never;
	Equal;
	NotEqual;
	Greater;
	GreaterEqual;
	Less;
	LessEqual;
}

enum MipMap {
	None;
	Nearest;
	Linear;
}

enum Filter {
	Nearest;
	Linear;
	
	Invalid;
}

enum Wrap {
	Clamp;
	Repeat;
	//Mirrored;
}

enum Operation {
	Add;
	Sub;
	ReverseSub;
}

enum TextureFlags {
	/**
		Allocate a texture that will be used as render target.
	**/
	Target;
	/**
		Add depth buffer on target texture
	**/
	TargetDepth;
	/**
		Use depth depth buffer when rendering to target texture
	**/
	TargetUseDefaultDepth;
	/**
		Allocate a cubic texture. Might be restricted to power of two textures only.
	**/
	Cubic;
	/**
		Used to prevent culling inversion on target textures in GL.
	**/
	TargetNoFlipY;
	/**
		Activates Mip Mapping for this texture. Might not be available for target textures.
	**/
	MipMapped;
	/**
		This is a not power of two texture. Automatically set when having width or height being not power of two.
	**/
	IsRectangle;
	/**
		Don't initialy allocate the texture memory.
	**/
	NoAlloc;
	/**
		Inform that we will often perform upload operations on this texture
	**/
	TexDynamic;
	/**
		Assumes that the color value of the texture is premultiplied by the alpha component.
	**/
	AlphaPremultiplied;
	
	/**
	* This a compressed texture and should be handled as such
	**/
	Compressed;
	
	/**
	 * There is no alpha channel
	 */
	NoAlpha;
	
	/**
	 * This one should never be garbaged
	 */
	NoGC;
	
	/**
	 * generates mipmaps if possible
	 */
	GenerateMipMap; 
}
