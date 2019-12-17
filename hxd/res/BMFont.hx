package hxd.res;

import hxd.fmt.fnt.CharacterDef;
import hxd.fmt.fnt.FontDef;
import hxd.fmt.fnt.FontCharHack;

class BMFont{
	public var font : FontDef;
	public var nativeFont : h2d.Font;
	public var pageTextures:Array<h2d.Tile> = [];
	public var nbChars = 0;
	
	var hacks : Map<Int,FontCharHack> = new Map();
	var loadTexture : String->h2d.Tile;
	
	public function new(font: FontDef, loadTexture: String->h2d.Tile, ?hacks:Map<Int,FontCharHack> ){
		this.font = font;
		this.loadTexture = loadTexture;
		nativeFont = new h2d.Font( font.name, font.size);
		nativeFont.sharedTex = false;
		loadPageTextures();
		if( hacks!=null) this.hacks = hacks;
		loadChars();
		
		hxd.res.FontBuilder.addFont( font.name, nativeFont );
	}
	
	public function loadPageTextures(){
		var i = 0;
		for( i in 0...font.pageCount )
			pageTextures[i] = loadTexture(font.pageFileNames[i]);
	}
	
	public function loadChars(){
		var i = 0;
		@:privateAccess nativeFont.charset = new hxd.Charset();
		for ( c in font.charMap)
			@:privateAccess nativeFont.charset.map.set( c.id, c.id);
		
		@:privateAccess nativeFont.tile = pageTextures[0];
		
		var nnc : CharacterDef = null;
		for ( nc in font.charMap){
			nnc = nc;
			
			var xOffsetDelta = 0;
			var yOffsetDelta = 0;
			var xAdvanceDelta = 0;
			if ( hacks.exists( nc.id ) ) {
				var v = hacks.get(nc.id );
				xOffsetDelta += v.xOffsetDelta;
				yOffsetDelta += v.yOffsetDelta;
				xAdvanceDelta += v.xAdvanceDelta;
			}
			
			var tex = pageTextures[nc.page];
			var tile = new h2d.Tile( tex.getTexture(), 
				Math.round(nc.x),
				Math.round(nc.y),
				Math.round(nc.width),
				Math.round(nc.height),
				Math.round(nc.xOffset+xOffsetDelta),
				Math.round(nc.yOffset+yOffsetDelta)
			);
			
			var char = new h2d.Font.FontChar( tile,  Math.round( nc.xAdvance+xAdvanceDelta));
			if( nc.kerningPairs!=null)
			for ( k in nc.kerningPairs.keys() )
				char.addKerning( k, nc.kerningPairs.get(k));
			
			@:privateAccess nativeFont.glyphs.set( nc.id, char );
			
			var logicalHeight = nc.height;
			if ( logicalHeight > @:privateAccess nativeFont.lineHeight )
				@:privateAccess nativeFont.lineHeight = Math.round(logicalHeight);
			
			i++;
		}
		if ( font.lineHeight > @:privateAccess nativeFont.lineHeight )
			@:privateAccess nativeFont.lineHeight = Math.round(font.lineHeight);
			
		@:privateAccess nativeFont.baseLine = font.base;
		nbChars = i;
	}
}