package hxd.res;

import hxd.fmt.fnt.CharacterDef;
import hxd.fmt.fnt.FontDef;

class BMFont{
	public var font : FontDef;
	public var nativeFont : h2d.Font;
	public var pageTextures:Array<h2d.Tile> = [];
	public var nbChars = 0;
	
	var loadTexture : String->h2d.Tile;
	public function new(font: FontDef, loadTexture: String->h2d.Tile ){
		this.font = font;
		this.loadTexture = loadTexture;
		nativeFont = new h2d.Font( font.name, font.size);
		nativeFont.sharedTex = false;
		loadPageTextures();
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
		//@:privateAccess nativeFont.lineHeight = Math.round(font.lineHeight);
		
		for ( c in font.charMap){
			var tex = pageTextures[c.page];
			var tile = new h2d.Tile( tex.getTexture(), 
				Math.round(c.x),
				Math.round(c.y),
				Math.round(c.width),
				Math.round(c.height),
				Math.round(c.xOffset),
				Math.round(c.yOffset)
			);
				
			var char = new h2d.Font.FontChar( tile,  Math.round( c.xAdvance));
			if( c.kerningPairs!=null)
			for ( k in c.kerningPairs.keys() )
				char.addKerning( k, c.kerningPairs.get(k));
			
			@:privateAccess nativeFont.glyphs.set( c.id, char );
			
			if ( c.height > @:privateAccess nativeFont.lineHeight )
				@:privateAccess nativeFont.lineHeight = Math.round(c.height);
			
			i++;
		}
		nbChars = i;
	}
}