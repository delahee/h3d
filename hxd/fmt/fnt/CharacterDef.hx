package hxd.fmt.fnt;

/**
 * ...
 * @author Andreas Rønning
 */
class CharacterDef {
	public var id:UInt;
	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var halfWidth:Float;
	public var height:Float;
	public var halfHeight:Float;
	public var xOffset:Float;
	public var yOffset:Float;
	public var xAdvance:Float;
	public var page:Int;
	public var channel:Int;
	public var kerningPairs:Null<Map<Int,Int>>;
	public function new() {
		
	}
}