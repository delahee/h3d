/*
 * format - haXe File Formats
 *
 * Copyright (c) 2008-2020, The Haxe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package hxd.fmt.pvr;
import haxe.io.Bytes;

using haxe.Int64;

@:publicFields
class Pointer {
	var bytes : haxe.io.Bytes;
	var pos:Int;
	var len:Int;
	
	function new (b, p, l) {
		this.bytes = b;
		this.pos = p;
		this.len = l;
	}
	
	function toString() return 'pos:$pos len:$len bytes:${bytes.get(0)} ${bytes.get(1)} ${bytes.get(2)} ${bytes.get(bytes.length-1)}';
}

//Compressed pixel formats
enum PixelFormat{
	PVRTCI_2bpp_RGB;
	PVRTCI_2bpp_RGBA;
	PVRTCI_4bpp_RGB;
	PVRTCI_4bpp_RGBA;
	PVRTCII_2bpp;
	PVRTCII_4bpp;
	ETC1;
	DXT1;
	DXT2;
	DXT3;
	DXT4;
	DXT5;


	//These formats are identical to some DXT formats.
	//BC1 = ePVRTPF_DXT1,
	//BC2 = ePVRTPF_DXT3,
	//BC3 = ePVRTPF_DXT5,

	//These are currently unsupported:
	BC4;
	BC5;
	BC6;
	BC7;

	//These are supported
	UYVY;
	YUY2;
	BW1bpp;
	SharedExponentR9G9B9E5;
	RGBG8888;
	GRGB8888;
	
	ETC2_RGB;
	ETC2_RGBA;
	ETC2_RGB_A1;
	EAC_R11;
	EAC_RG11;
}


@:publicFields
class Header {
	var version : Int;
	var flags :Int;
	var pixelFormat:haxe.Int64;
	var colourSpace: Int;
	
	var channelType : Int;
	var height : Int;
	var width:Int;
	var depth:Int;
	
	var numSurfaces:Int;
	var numFaces:Int;
	
	var mipmapCount:Int;
	var metadataSize:Int;
	
	inline function new() {}
	function getFormat() {
		return pixelFormat.getHigh() != 0 ? null : Type.createEnumIndex( PixelFormat, pixelFormat.getLow() );
	}
	
	static inline var PVRTEX3_PREMULTIPLIED = (1<<1);
}

@:publicFields
class Metadata {
	var fourcc : Int;
	var key:Int;
	var size:Int;
	var data: Pointer;
	inline function new(){}
}

/**
 */
@:publicFields
class Data {
	var header:Header;
	var meta:Array<Metadata>;
	var bytes:haxe.io.Bytes;
	var dataStart:Int;
	
	var mipmapCount(get, null) : Int;
	
	/**
	 * Texture chunks ordered by mip frame face depth
	 */
	var images : Array<Array<Array<Array<hxd.BytesView>>>>;
	
	inline function new(){}
	inline function get_mipmapCount():Int{
		return header.mipmapCount;
	}

	#if sys
	function getGlFormat() {
		var GL = h3d.impl.GlDriver;
		
		return switch(header.getFormat()) {
			case DXT1: GL.COMPRESSED_RGBA_S3TC_DXT1_EXT;
			case DXT3: GL.COMPRESSED_RGBA_S3TC_DXT3_EXT;
			case DXT5: GL.COMPRESSED_RGBA_S3TC_DXT5_EXT;
			
			case PVRTCI_2bpp_RGB: 	GL.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
			case PVRTCI_2bpp_RGBA:	GL.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
			
			case PVRTCI_4bpp_RGB: 	GL.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
			case PVRTCI_4bpp_RGBA: 	GL.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
			
			case PVRTCII_2bpp:		GL.COMPRESSED_RGBA_PVRTC_2BPPV2_IMG;
			case PVRTCII_4bpp:		GL.COMPRESSED_RGBA_PVRTC_4BPPV2_IMG;
			
			case ETC1:				GL.ETC1_RGB8_OES;
				
			//usually add render systems as one deploys them...
			default: throw "todo !"+header.getFormat();
		}
	}
	#end
	
	
	function getPixelFormat() : hxd.PixelFormat {
		if( isCompressed())
			#if sys 
				return Compressed( getGlFormat() );
			#else
				return null;
			#end
		else {
			var lo = haxe.Int64.getLow( header.pixelFormat );
			var hi = haxe.Int64.getHigh( header.pixelFormat );
			
			var str = "";
			
			str += String.fromCharCode((lo >> 0) & 255);
			str += String.fromCharCode((lo >> 8) & 255);
			str += String.fromCharCode((lo >> 16) & 255);
			str += String.fromCharCode((lo >> 24) & 255);
			
			str = str.toUpperCase();
			
			var fmt = switch(str) {
				case "RGBA": hxd.PixelFormat.RGBA;
				case "ARGB": hxd.PixelFormat.ARGB;
				case "BGRA": hxd.PixelFormat.BGRA;
				default: throw "unsupported pixel format "+str; 
			}
			
			return fmt;
		}
	}
	
	function getBpp() {
		if ( haxe.Int64.getHigh(header.pixelFormat) != 0) {
			var sum = 0, hi = haxe.Int64.getHigh(header.pixelFormat);
			
			sum += (hi >> 24)	& 0xFF;
			sum += (hi >> 16)	& 0xFF;
			sum += (hi >> 8)	& 0xFF;
			sum += (hi >> 0)	& 0xFF;
			
			return sum;
		}
		else 
			return switch(header.getFormat()) {
				case PVRTCI_2bpp_RGB	: 2;
				case PVRTCI_2bpp_RGBA	: 2;
				case PVRTCI_4bpp_RGB 	: 4;
				case PVRTCI_4bpp_RGBA	: 4;
				case PVRTCII_2bpp 		: 2;
				case PVRTCII_4bpp		: 4;
				case ETC1				: 4;		
				
				default: 0; 
				case RGBG8888,GRGB8888:32;
				
				//begin unchecked
				case ETC2_RGB : 4;
				case ETC2_RGBA : 4;
				case ETC2_RGB_A1 : 4;
				
				case EAC_R11:4; 
				case EAC_RG11:4;
				//end unchecked
				
				case DXT1: 4;
				case DXT3: 8;
				case DXT5: 8;
			}
	}
	
	inline function isCompressed() {
		var fmt = header.getFormat();
		if ( fmt == null ) return false;
		
		return switch( fmt) {
			case 
				PVRTCI_2bpp_RGB, PVRTCI_2bpp_RGBA, PVRTCI_4bpp_RGB, PVRTCI_4bpp_RGBA, PVRTCII_2bpp, PVRTCII_4bpp, 
				DXT1, DXT2, DXT3, DXT4, DXT5, 
				ETC1, ETC2_RGB, ETC2_RGBA, ETC2_RGB_A1, ETC1, EAC_R11, EAC_RG11: true;
			default:false;
		};
	}
	
	function get(mip = -1, surface = 0, face = 0, depth = 0) {
		var mip = ( mip < 0 ) ? (mip =  mipmapCount + mip) : mip;
		return images[mip][surface][face][depth];
	}
	
	public function getMipWidth(ml : Int) {
		var ml = ( ml < 0 ) ? mipmapCount + ml : ml;
		var l =  header.width >> ml;
		if ( l <= 0) l = 1;
		return l;
	}
	
	public function getMipHeight(ml : Int) {
		var ml = ( ml < 0 ) ? mipmapCount + ml : ml;
		var l =  header.height >> ml;
		if ( l <= 0) l = 1;
		return l;
	}
	
	#if h3d
	public function toPixels( ?mipLevel : Int = 0, ?frame = 0, ?face = 0, ?depth = 0 ) : hxd.Pixels {
		var ml 		= mipLevel;
		
		if ( mipLevel > mipmapCount ) throw "no such mipmap level" ;
		var ptr 	= get(ml, frame, face, depth); hxd.Assert.notNull( ptr );
		
		var lwidth 	= getMipWidth(ml);
		var lheight = getMipHeight(ml);
		
		var pix 	= new hxd.Pixels(lwidth, lheight,ptr, getPixelFormat() );
		
		pix.flags.set(ReadOnly);
		if ( isCompressed() )
			pix.flags.set(Compressed);
			
		return pix;
	}
	#end
}