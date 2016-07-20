package h2d;

class Checkbox extends h2d.Sprite {

	var inter : h2d.Interactive;
	public var checked(default, set) : Bool;
	var gfx:h2d.Graphics;
	
	public function new(checked:Bool,?p:h2d.Sprite) {
		super(p);
		
		gfx = new h2d.Graphics(this);
		inter = new h2d.Interactive(20,20,this);
		this.checked = checked;
		
		inter.onClick = function(e:hxd.Event) {
			checked = !checked;
			set_checked(checked);
		};
	}
	
	function set_checked(v) {
		gfx.clear();
		gfx.lineStyle(2);
		var w = 10;
		gfx.beginFill(0xffffffff);
		gfx.drawRect( 0, -w, w * 2, w * 2);
		gfx.endFill();
		if ( v ) {
			gfx.drawLine( 1,-w+1, 	w*2-1, w-1);
			gfx.drawLine( 1,w-1,	w*2-1,-w+1);
			//gfx.drawLine( 0,w,w,-w);
		}
		
		
		inter.x = 0;
		inter.y = -w;
		inter.height = inter.width = w * 2;
		onChange(v);
		return checked=v;
	}
	
	public dynamic function onChange(onOff) {}
	
	
}