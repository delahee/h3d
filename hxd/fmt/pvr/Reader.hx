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

import h3d.mat.Texture;
import haxe.EnumFlags;
import haxe.io.Bytes;
import hxd.fmt.pvr.Data;

class Reader {
	var input : haxe.io.BytesInput;
	var bytes : haxe.io.Bytes; 
	
	public function new(bytes : haxe.io.Bytes ) {
		this.bytes = bytes;
		input = new haxe.io.BytesInput(bytes);
		input.bigEndian = false;
	}
	
	@:noDebug
	public function read() : Data {
		var i = input;
		var h = readHeader(i);
		var m = readMeta(i, h);
		
		var d = new Data();
		d.header = h;
		d.meta = m;
		d.bytes = bytes;
		d.dataStart = i.position;
		
		readImages(d);
		return d;
	}
	
	@:noDebug
	function readImages(d:Data) {
		var ptr = 0;
		var bpp = d.getBpp();
		var h = d.header;
		
		d.images = [];
		for( ml in 0...h.mipmapCount ){
			var mip0w = d.getMipWidth(ml);
			var mip0h = d.getMipHeight(ml);
			var size = (mip0w * mip0h * bpp) >> 3;//go to bytes
			
			d.images[ml] = [];
			for ( s in 0...h.numSurfaces) {
				d.images[ml][s] = [];
				for ( f in 0...h.numFaces) {
					d.images[ml][s][f] = [];
					for ( dp in 0...h.depth ) { 		//who the hell had the idea to come up with non aligned texture position....
						var pt = d.dataStart + ptr;
						var sz = size;
						var nbytes = haxe.io.Bytes.alloc(sz);
						nbytes.blit( 0, bytes, pt, sz);
						d.images[ml][s][f][dp] = new hxd.BytesView(nbytes,0, sz);//cant get rid of it, it is necessary to align buffer pointer...
						ptr += size;
					}
				}
			}
		}
	}
	
	@:noDebug
	function readMeta(i:haxe.io.BytesInput, h:Header) {
		var a = [];
		var meta = h.metadataSize;
		
		while ( meta > 0 ) {
			var m = new hxd.fmt.pvr.Data.Metadata();
			m.fourcc = i.readInt32();	meta -= 4;
			m.key = i.readInt32();		meta -= 4;
			m.size = i.readInt32(); 	meta -= 4;
			m.data = new hxd.fmt.pvr.Data.Pointer(bytes, i.position, m.size);
			i.position += m.size;
			meta -= m.size;
			
			m.validate();
			a.push(m);
		}
		if ( meta < 0 ) throw "invalid file meta:"+meta;
		return a;
	}
	
	@:noDebug
	function readHeader(i:haxe.io.BytesInput) : Data.Header {
		var h = new Header();
		h.version = i.readInt32();
		h.flags = i.readInt32();
		
		var lo = h.version = i.readInt32();
		var hi = h.version = i.readInt32();
		
		h.pixelFormat = haxe.Int64.make(hi, lo);
		
		h.colourSpace 	= i.readInt32();
		h.channelType 	= i.readInt32();
		h.height 		= i.readInt32();
		h.width 		= i.readInt32();
		h.depth 		= i.readInt32();
		
		h.numSurfaces 	= i.readInt32();
		h.numFaces 		= i.readInt32();
		
		h.mipmapCount 	= i.readInt32();
		h.metadataSize 	= i.readInt32();
		
		//Comeonnnnnnn
		if (h.mipmapCount == 0) h.mipmapCount = 1;
		
		return h;
	}

	#if openfl
	public static function fromAssets( path:String ) : h3d.mat.Texture {
		var b = hxd.ByteConversions.byteArrayToBytes(openfl.Assets.getBytes(path));
		var t = new hxd.fmt.pvr.Reader(b);
		var d : hxd.fmt.pvr.Data = t.read();
		return d.toTexture();
	}
	
	@:noDebug
	public static function fromCompressedAssets( path:String ) : h3d.mat.Texture {
		var fileBytes = sys.io.File.getBytes(path);
		var bytes = haxe.zip.Uncompress.run( fileBytes );
		var t : h3d.mat.Texture = fromBytes(bytes);
		/*
		t.realloc = function(){
			
		};
		*/
		return t;
	}
	
	@:noDebug
	public static function fromBytes( b:haxe.io.Bytes){
		var t = new hxd.fmt.pvr.Reader(b);
		var d : hxd.fmt.pvr.Data = t.read();
		return d.toTexture();
	}
	#end
	
}

