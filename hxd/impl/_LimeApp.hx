package hxd.impl;

#if (lime >= "7.1.1" )
class LimeApp extends lime.app.Application {

	public static var me : LimeApp = null;
	
	public var renderFunc:Void->Void = function(){
		
	};
	
	public function new() {
		trace("starting app");
		super();
		me = this;
	}
	
	public override function render(c:lime.graphics.RenderContext):Void{
		super.render(c);
		trace("rendering");
		renderFunc();
	}
	
}
#end