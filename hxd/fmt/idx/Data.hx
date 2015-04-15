
package hxd.fmt.idx;

class Entry {
	public var idx 	: Int;
	public var rgba 	: Int;
	public inline function new(i,c){
		idx=i;
		rgba=c;
	}
}

class Data {
	public var index			: haxe.ds.Vector<Int>;
	
	public var paletteByIndex 	: Array<Int>;
	
	//will not be filled by reader
	public var paletteByRgba 	: Map<Int,Entry> = null;
	
	public var nbBits 			= -1;
	
	public var width = -1;
	public var height = -1;
	
	public var reduceR = 2;
	public var reduceG = 2;
	public var reduceB = 2; 
	public var reduceA = 0;
	
	public function new(){
		
	}
	
	public function toBitmapData() : flash.display.BitmapData {
		var bmp = new flash.display.BitmapData(width,height,true);
		for( y in 0...height){
			var ypos = y*width;
			for( x in 0...width )
				bmp.setPixel32(x,y, paletteByIndex[index[ypos+x]]);
		}
		return bmp;
	}
}
