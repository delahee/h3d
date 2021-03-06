package hxd;
import haxe.Utf8;

class Charset {

	/**
		Contains Hiragana, Katanaga, japanese punctuaction and full width space (0x3000) full width numbers (0-9) and some full width ascii punctuation (!:?%&()-). Does not include full width A-Za-z.
	**/
	public static var JP_KANA = "　あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽゃゅょアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポヴャぇっッュョァィゥェォ・ー「」、。『』“”！：？％＆（）－０１２３４５６７８９";
	
	/**
		Contains the whole ASCII charset.
	**/
	public static var ASCII = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
	
	/**
		The Latin1 (ISO 8859-1) charset (only the extra chars, no the ASCII part)
	**/
	public static var LATIN1 = "¡¢£¤¥¦§¨©ª«¬-®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿёÞßÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ÷ØÙÚÛÜÝÞŸЁ";
	
	/**
		Russian support
	**/
	public static var CYRILLIC = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя—";
	
	/**
		Polish support
	**/
	public static var POLISH = "ĄĆĘŁŃÓŚŹŻąćęłńóśźż";
	
	
	
	/**
		HANGUL_SYL support for korean
	**/
	public static function HANGUL_SYL(){
		var s = new haxe.Utf8();
		for ( i in 0xAC00...0xD7A3+1){
			s.addChar( i );
		}
		return s.toString();
	};
	
	public static function HANGUL_JAMMO(){
		var s = new haxe.Utf8();
		for ( i in 0x1100...0x11FF){
			s.addChar( i );
		}
		return s.toString();
	};
	
	public static var DEFAULT_CHARS = ASCII + LATIN1;
	public static var KEEP_ACCENTS = false;
	
	var map : Map<Int,Int>;

	macro static public function code(str:String):ExprOf<Int> {
		var u8 = Utf8.charCodeAt(str,0);
		return macro $v{u8};
    }
	
	function new() {
		map = new Map();
		inline function m(dst, src) {
			map.set(dst, src);
		}
		
		// fullwidth unicode to ASCII (if missing)
		for( i in 1...0x5E )
			m(0xFF01 + i, 0x21 + i);
			
		if( !KEEP_ACCENTS ){
			// Latin1 accents
			for( i in code("À")...code("Æ") + 1 )
				m(i, code("A"));
			for( i in code("à")...code("æ") + 1 )
				m(i, code("a"));
			for( i in code("È")...code("Ë") + 1 )
				m(i, code("E"));
			for( i in code("è")...code("ë") + 1 )
				m(i, code("e"));
			for( i in code("Ì")...code("Ï") + 1 )
				m(i, code("I"));
			for( i in code("ì")...code("ï") + 1 )
				m(i, code("i"));
			for( i in code("Ò")...code("Ö") + 1 )
				m(i, code("O"));
			for( i in code("ò")...code("ö") + 1 )
				m(i, code("o"));
			for( i in code("Ù")...code("Ü") + 1 )
				m(i, code("U"));
			for( i in code("ù")...code("ü") + 1 )
				m(i, code("u"));
				
			m(code("Ç"), code("C"));
			m(code("ç"), code("C"));
			m(code("Ð"), code("D"));
			m(code("Þ"), code("d"));
			m(code("Ñ"), code("N"));
			m(code("ñ"), code("n"));
			m(code("Ý"), code("Y"));
			m(code("ý"), code("y"));
			m(code("ÿ"), code("y"));
		}
		
		// unicode spaces
		m(0x3000, 0x20); // full width space
		m(0xA0, 0x20); // nbsp
		// unicode quotes
		m(code("«"), code('"'));
		m(code("»"), code('"'));
		m(code("“"), code('"'));
		m(code("”"), code('"'));
		m(code("‘"), code("'"));
		m(code("’"), code("'"));
		m(code("´"), code("'"));
		m(code("‘"), code("'"));
		m(code("‹"), code("<"));
		m(code("›"), code(">"));
		
		#if cpp
		m( 7838, 0xDF); //esset resolution
		#end
	}
	
	@:generic
	public function resolveChar<T>( cc : Int, glyphs : Map<Int,T> ) : Null<T> {
		var c : Null<Int> = cc;
		while( c != null ) {
			var g = glyphs.get(c);
			if ( g != null ) return g;
			c = map.get(c);
		}
		return null;
	}
	
	public function getAlias(code:Int ):Int{
		return map.get(code);
	}
	
	public inline function isSpace(cc : Int) {
		return cc == code(' ') || cc == 0x3000;
	}
	
	public function isBreakChar(cc : Int) {
		//indo europeean
		if ( cc == code('!') || cc == code('?') || cc ==code('.') || cc ==code(',') || cc == code(':') )
			return true;
		//japanese separators
		if ( cc == code("？")|| cc == code("！") || cc ==code('、') || cc ==code('。') || cc == code('を') )
			return true;
			
		//chinese separators
		if ( cc == code("？")|| cc == code("！") || cc ==code("，") || cc ==code("。")  )
			return true;
		
		//korean separators
		if ( cc == code("!")|| cc == code(".") || cc ==code("?") )
			return true;
			
		return isSpace(cc);
	}
	
	//dest = source
	//all chars requesting dest will become src
	function alias(strDest:String,strSource:String){
		map.set( haxe.Utf8.charCodeAt(strDest,0), haxe.Utf8.charCodeAt(strSource,0));
	}

	static var inst : Charset;
	public static function getDefault() {
		if( inst == null ) inst = new Charset();
		return inst;
	}
	
}