
package hxd.fmt.vtf;

import haxe.EnumFlags;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hxd.Pixels;

enum ImageFormat
{
	RGBA8888 			;
	ABGR8888 			;
	RGB888 				;
	BGR888 				;
	RGB565 				;
	I8 		  			;
	IA88 				;
	P8  				;
	A8  				;
	RGB888_BLUESCREEN	;
	BGR888_BLUESCREEN	;
	ARGB8888			;
	BGRA8888			;
	DXT1				;
	DXT3				;
	DXT5				;
	BGRX8888 			;
	BGR565				;
	BGRX5551 			;
	BGRA4444 			;
	DXT1_ONEBITALPHA 	;
	BGRA5551 			;
	UV88 				;
	UVWQ8888 			;
	RGBA16161616F		;
	RGBA16161616 		;
	UVLX8888			;
}


enum TextureFlags
{
	// Flags from the *.txt config file
	POINTSAMPLE ;
	TRILINEAR ;
	CLAMPS ;
	CLAMPT ;
	ANISOTROPIC ;
	HINT_DXT5 ;
	PWL_CORRECTED ;
	NORMAL;
	NOMIP ;
	NOLOD ;
	ALL_MIPS ;
	PROCEDURAL ;
    
	// These are automatically generated by vtex from the texture data.
	TEXTUREFLAGS_ONEBITALPHA ;
	TEXTUREFLAGS_EIGHTBITALPHA ;
     
	// Newer flags from the *.txt config file
	TEXTUREFLAGS_ENVMAP ;
	TEXTUREFLAGS_RENDERTARGET ;
	TEXTUREFLAGS_DEPTHRENDERTARGET ;
	TEXTUREFLAGS_NODEBUGOVERRIDE ;
	TEXTUREFLAGS_SINGLECOPY;
	TEXTUREFLAGS_PRE_SRGB;
    
    TEXTUREFLAGS_H3D_FLIPPED;//TEXTUREFLAGS_UNUSED_00100000; 
	TEXTUREFLAGS_UNUSED_00200000;
	TEXTUREFLAGS_UNUSED_00400000;
    
	TEXTUREFLAGS_NODEPTHBUFFER;
    
	TEXTUREFLAGS_UNUSED_01000000;
    
	TEXTUREFLAGS_CLAMPU;
	TEXTUREFLAGS_VERTEXTEXTURE;
	TEXTUREFLAGS_SSBUMP;	
    
	TEXTUREFLAGS_UNUSED_10000000;
    
	TEXTUREFLAGS_BORDER;
    
	TEXTUREFLAGS_UNUSED_40000000;
	TEXTUREFLAGS_UNUSED_80000000;
	
}

/*
@:publicFields
class ImagePointer {
	var bytes : haxe.io.Bytes;
	var pos:Int;
	var len:Int;
	
	function new (b, p, l) {
		this.bytes = b;
		this.pos = p;
		this.len = l;
	}
	
	function toString() return 'bytes:$bytes pos:$pos len:$len';
}*/

enum VTFCubeMapFace
{
	CUBEMAP_FACE_RIGHT;			// +x
	CUBEMAP_FACE_LEFT;			// -x
	CUBEMAP_FACE_BACK;			// +y
	CUBEMAP_FACE_FRONT;			// -y
	CUBEMAP_FACE_UP;			// +z
	CUBEMAP_FACE_DOWN;			// -z
	CUBEMAP_FACE_SphereMap;		// fall back
	CUBEMAP_FACE_COUNT;
}

/**
 *@see https://github.com/delahee/VTFLib
 */
@:publicFields
class Data {
	var version : Int;						// version[0] << 8  | version[1] (currently 7.2).
	var headerSize : Int;					// Size of the header struct (16 byte aligned; currently 80 bytes).
	var width: Int;							// Width of the largest mipmap in pixels. Must be a power of 2.
	var height : Int;						// Height of the largest mipmap in pixels. Must be a power of 2.
	var flags : EnumFlags<TextureFlags>;	// VTF flags.
	var frames : Int;						// Number of frames, if animated (1 for no animation).
	var firstFrame: Int;					// First frame in animation (0 based).
	var reflectivity:Array<Float>;			// reflectivity vector.
	var bumpmapScale:Float;					
	var highResImageFormat:Null<ImageFormat>;				// High resolution image format.
	var mipmapCount:Int;					// Number of mipmaps.
	var lowResImageFormat:Null<ImageFormat>;				// Low resolution image format (always DXT1).
	var lowResImageWidth:Int;				// Low resolution image width.
	var lowResImageHeight:Int;				// Low resolution image height.
	var depth :Int;							// Depth of the largest mipmap in pixels.
											// Must be a power of 2. Can be 0 or 1 for a 2D texture (v7.2 only).

	var numResources : Int;
	var lowRes : hxd.BytesView;
	var imageSet : Array < //mipmap
		Array <//frames
			Array <//faces
				Array <//z-slices
					hxd.BytesView
				>
			>
		>
	>;
	
	var resources : Array<{?type:Int,?data:Int, ?ptr:hxd.BytesView}>;
	var bytes : haxe.io.Bytes; 
	
	public function new() {
		
	}
	
	public static inline var VTF_MINOR_VERSION_MIN_SPHERE_MAP    = 1;
    public static inline var VTF_MINOR_VERSION_MIN_VOLUME        = 2;
    public static inline var VTF_MINOR_VERSION_MIN_RESOURCE      = 3;
	public static inline var VTF_MINOR_VERSION_MIN_NO_SPHERE_MAP = 5;
	
	public static inline var RSRCF_HAS_NO_DATA_CHUNK = 0x02;
	
	static inline function makeId(a, b=0, c=0, d=0) return a | (b << 8)  | (c << 16) | (d <<24);
	
	public static inline function VTF_LEGACY_RSRC_LOW_RES_IMAGE() 	return makeId(0x01);
	public static inline function VTF_LEGACY_RSRC_IMAGE() 			return makeId(0x30);
	
	public static inline function VTF_RSRC_SHEET()	 				return makeId(0x10);
	public static inline function VTF_RSRC_CRC() 					return makeId('C'.code,'R'.code,'C'.code,RSRCF_HAS_NO_DATA_CHUNK);
	public static inline function VTF_RSRC_TEXTURE_LOD_SETTINGS () 	return makeId('L'.code,'O'.code,'D'.code,RSRCF_HAS_NO_DATA_CHUNK);
	public static inline function VTF_RSRC_TEXTURE_SETTINGS_EX  () 	return makeId('T'.code,'S'.code,'O'.code,RSRCF_HAS_NO_DATA_CHUNK);
	public static inline function VTF_RSRC_KEY_VALUE_DATA() 		return makeId('K'.code,'V'.code,'D'.code);
	
	public inline function getFaceCount() {
		var v = 1;
		if ( !flags.has( TEXTUREFLAGS_ENVMAP )) {
			return 1;
		}
		else if ( minor() >= VTF_MINOR_VERSION_MIN_NO_SPHERE_MAP) {
			return Type.enumIndex(CUBEMAP_FACE_COUNT);
		}
		else return Type.enumIndex(CUBEMAP_FACE_COUNT)-1;
	}
	
	public inline function minor() return version & 0xFF;
	public inline function major() return version >> 0xFF;
	
	
	static inline function posMod( i :Int,m:Int )
	{
		var mod = i % m;
		return (mod >= 0)
		? mod
		: mod + m;
	}

	
	public inline function getMipWidth(mipLevel : Int){
		var ml = posMod(mipmapCount + mipLevel, mipmapCount);
		var l =  (width >> (mipmapCount-ml-1) );
		if ( l <= 0) l = 1;
		return l;
	}
	
	public inline function getMipHeight(mipLevel : Int){
		var ml = posMod(mipmapCount + mipLevel, mipmapCount);
		var l = height  >> (mipmapCount-ml-1);
		if ( l <= 0) l = 1;
		return l;
	}
	
	public inline function hasResource() return minor() >= VTF_MINOR_VERSION_MIN_RESOURCE;
	
	/**
	 * 
	 * sends back a raw pointer, do what you want with it
	 * miplevel -1 will send the full detailed tex
	 * 0 is smallest
	 */
	public inline function get( ?mipLevel : Int = -1, ?frame = 0, ?face = 0, ?depth = 0) : Null<hxd.BytesView> {
		if ( mipLevel < 0 )
			mipLevel =  mipmapCount + mipLevel;
		return imageSet[mipLevel][frame][face][depth];
	}
	
	
	function typeToString(t:Int) {
		if ( t == VTF_LEGACY_RSRC_LOW_RES_IMAGE() )		return "VTF_LEGACY_RSRC_LOW_RES_IMAGE";
		if ( t == VTF_LEGACY_RSRC_IMAGE() 		)   	return "VTF_LEGACY_RSRC_IMAGE";
		if ( t == VTF_RSRC_SHEET()	 				)   return "VTF_RSRC_SHEET";
		if ( t == VTF_RSRC_CRC() 					 )  return "VTF_RSRC_CRC";
		if ( t == VTF_RSRC_TEXTURE_LOD_SETTINGS () 	 )  return "VTF_RSRC_TEXTURE_LOD_SETTINGS";
		if ( t == VTF_RSRC_TEXTURE_SETTINGS_EX() 	)	return "VTF_RSRC_KEY_VALUE_DATA";
		if ( t == VTF_RSRC_KEY_VALUE_DATA() )  			return "VTF_RSRC_KEY_VALUE_DATA";
		
		return "VTF_RSC_UNKNOWN";
	}
	/**
	 * returns a string describing the format and some useful infos about it
	 */
	public inline function dump() {
		var s = "";
		
		s += "version:" + major() + "." + minor()+"\n";
		s += "format:" + Std.string( highResImageFormat )+"\n";
		s += "width:" + width+"\n";
		s += "height:" + height + "\n";
		
		s += "headerSize:" + headerSize+"\n";
		
		s += "lowResImageFormat:" + lowResImageFormat + "\n";
		s += "lowResImageWidth:" + lowResImageWidth+"\n";
		s += "lowResImageHeight:" + lowResImageHeight+"\n";
		
		s += "depth:" + depth + "\n";
		s += "mipmapCount:" + mipmapCount + "\n";
		s += "flags:{";
		for ( f in Type.allEnums(TextureFlags)) {
			if ( flags.has(f)) {
				s += Std.string(f);
			}
		}
		s += "}\n";
		
		if ( hasResource()) {
			s += "res:{";
			for ( r in resources ) {
				s += 'type:${typeToString(r.type)} data:${r.data}, ptr:${r.ptr}\n';
			}
			s += "}\n";
		}
		
		if ( imageSet != null ) {
			s += "image:{";
			for ( x in 0...4)
				for ( y in 0...4)
					s += 'col($x,$y)=' + col(getPixel(x, y)) + "\n";
					
			for ( x in 0...4)
				for ( y in 0...4) {
					var ly = height - 4 + y - 1;
					s += 'col($x,$ly)=' + col(getPixel(x, ly)) + "\n";
				}
				
			s += "}\n";
		}
		else 
			s += "image:{}\n";
		
		return s;
	}
	
	function col(c:{r:Int,g:Int,b:Int,a:Int}) {
		return '{ r:${c.r}  g:${c.g} b:${c.b} a:${c.a} }';
	}
	
	
	/**
	 * @param 	pos is the base pointer of the texture in the bytes
	 * @param	stride is the texel stride in bytes
	 */
	inline function flipLine(dest : haxe.io.Bytes,src : haxe.io.Bytes, pos:Int, w:Int, h :Int, y:Int, stride: Int){
		if ( stride <= 0 ) {
			var msg = "can't flip compressed tex";
			#if debug 
				throw msg;
			#else
				trace(msg);
			#end
		}
		dest.blit(pos + (h - y - 1) * (stride*width), src, pos + y * width * stride, stride * width );
	}

	/**
	 * 
	 * @param	?flipThumb=false because flipThumb is usually impossible because its compressed
	 */
	public function flipY( ?flipThumb=false) {
		var d = clone();
		
		//won't flip ressources as they might not be actual images
		if(flipThumb && lowResImageFormat!=null)
			for ( y in 0...lowResImageHeight) 
				flipLine( d.bytes, bytes, lowRes.position, lowResImageWidth, lowResImageHeight, y, getBitStride(lowResImageFormat) >> 3);
			
		for ( mips_i in 0...imageSet.length) {
			var mip = imageSet[mips_i];
			for ( frame_i in 0...mip.length) {
				var frame = mip[frame_i];
				for ( face_i in 0...frame.length) {
					var face = frame[face_i];
					for ( depth_i in 0...face.length) {
						var depth = face[depth_i];
						
						var lwidth = getMipWidth( mips_i );
						var lheight = getMipHeight( mips_i );
						
						for( y in 0...lheight)
							flipLine( d.bytes, bytes, depth.position, lwidth, lheight, y, getBitStride(highResImageFormat) >> 3);
					}
				}
			}
		}
		
		if( d.flags.has(TEXTUREFLAGS_H3D_FLIPPED))
			d.flags.unset(TEXTUREFLAGS_H3D_FLIPPED);
		else 
			d.flags.set( TEXTUREFLAGS_H3D_FLIPPED );
		
		return d;
	}
	
	
	public function clone() : Data {
		var d = new Data();
		
		var b = haxe.io.Bytes.alloc( bytes.length); 
		b.blit( 0, bytes, 0, bytes.length);
		d.bytes = b;
		
		for ( f in Type.getInstanceFields(Data))
			switch(f) {
				case "bytes":
				case "lowRes": 
				if ( lowRes != null)
					d.lowRes = new hxd.BytesView( bytes, lowRes.position, lowRes.length);
				case "imageSet": 
				{
					d.imageSet = imageSet.map(
					function(mips) return mips.map( 
					function(frames) return frames.map( 
					function(faces) return faces.map( 
					function(depthes) return 
					{
						return new hxd.BytesView( bytes, depthes.position, depthes.length);
					}))));
				}	
				case "resources":
					d.resources = [];
					for ( i in 0...resources.length) {
						var r = resources[i];
						d.resources[i] = Reflect.copy( r );
						if( d.resources[i]!=null && r.ptr != null)
							d.resources[i].ptr = new hxd.BytesView( bytes, r.ptr.position, r.ptr.length);
					}
				default:
					if( !Reflect.isFunction( Reflect.getProperty(this,f)) )
						Reflect.setProperty( d, f, Reflect.getProperty(this,f) );
			}
		return d;
	}
	
	/**
	 * we are in Little endian but buffer is in big endian(like gpu...) so rgba reads abgr in memory
	 * this is aboslutely not to be used in production and IS slow
	 */
	public function getPixel(x:Int,y:Int,?mipLevel=-1) {
		var i = get(mipLevel);
		
		var stride = getBitStride();
		var ofs = ((y * width + x) * stride) >> 3;
		
		if ( stride < 8 ) {
			trace("unable to decode");
			return {r:0,g:0,b:0,a:0};
		}
		
		switch( highResImageFormat) {
			default:
				trace("unable to decode");
				return {r:0,g:0,b:0,a:0};
				
			case ARGB8888: 
				
				var g = i.get(ofs);
				var b = i.get(ofs+1);
				var a = i.get(ofs+2);
				var r = i.get(ofs+3);
				return { r:r, g:g, b:b, a:a };
		}
	}
	
	/**
	 * @return bits size
	 */
	public function getBitStride(?format:ImageFormat) {
		if (format == null)
			format = highResImageFormat;
		
		return
		if ( format == null ) 
			0;
		else 
		switch(format)  {
			case RGBA8888 : 			32;
			case ABGR8888 : 			32;
			case RGB888 : 				24;
			case BGR888 : 				24;
			case RGB565 : 				16;
			case I8 : 					8;
			case IA88 : 				16;
			case P8 :					8;
			case A8 : 					8;
			case RGB888_BLUESCREEN :	24;
			case BGR888_BLUESCREEN :	24;
			case ARGB8888 : 			32;
			case BGRA8888 : 			32;
			case DXT1 : 				4;
			case DXT3 : 				8;
			case DXT5 : 				8;
			case BGRX8888 : 			32;
			case BGR565 : 				16;
			case BGRX5551 : 			16;
			case BGRA4444 : 			16;
			case DXT1_ONEBITALPHA : 	4;
			case BGRA5551 : 			16;
			case UV88 : 				16;
			case UVWQ8888 : 			32;
			case RGBA16161616F : 		64;
			case RGBA16161616 : 		64;
			case UVLX8888 : 			32;
		}
	}
	
	#if h3d
	public function getH3dPixelFormat() : hxd.PixelFormat {
		return 
		switch(highResImageFormat) {
			case RGBA8888: 	hxd.PixelFormat.RGBA; 
			case BGRA8888: 	hxd.PixelFormat.BGRA;
			case ARGB8888:	hxd.PixelFormat.ARGB;
			default:
				throw "Unconvertible h3d.PixelFormat";
		}
	}
	
	var pixels : hxd.Pixels;
	public function toPixels( ?mipLevel : Int = -1, ?frame = 0, ?face = 0, ?depth = 0 ) : hxd.Pixels {
		if( pixels==null){
			var ptr  = get(mipLevel, frame, face, depth); hxd.Assert.notNull( ptr );
			
			var lwidth = getMipWidth(mipLevel);
			var lheight = getMipHeight(mipLevel);
			var pix = new hxd.Pixels(lwidth, lheight, ptr, getH3dPixelFormat());
			
			switch(highResImageFormat) {
				default: pix.flags.set(ReadOnly);
				case ARGB8888, RGBA8888, BGRA8888: //convertible by h3d
			}
			
			pixels = pix;
		}
		return pixels;
	}
	#end
}
