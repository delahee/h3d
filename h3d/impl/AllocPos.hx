package h3d.impl;


#if debug
@:structInit
class DummyPos{
	public var __alloc : Int;
}
#end

typedef AllocPos = #if debug haxe.PosInfos #else DummyPos #end
