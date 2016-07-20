package h2d;

class ValueBarRange extends h2d.Sprite {
	var font : h2d.Font;
	
	var bar : h2d.Graphics;
	var inter : h2d.Interactive;
	var num : h2d.Text;
	var barWidth = 100;
	var range : Array<Int>;
	var value : Float = 0.0;
	
	public dynamic function onValueChanged(f:Float) { }
	public dynamic function onTextChanged(d:Float):String	 return Std.string(d);	
	inline function f2pc(f:Float) return Math.round(f * 100.0);
	
	public function new(name:String, f:h2d.Font, range:Array<Int>, val:Float, barWidth:Int, ?p:h2d.Sprite) {
		super(p);
		this.range = range;
		this.value = val;
		this.barWidth = barWidth;
		if ( f == null ) f = hxd.res.FontBuilder.getFont("console", 12);
		this.font = f;
		var txt = new h2d.Text(font,this );
		txt.text = name.toUpperCase();
		num = new h2d.Number( font,this);
		num.y = 24;
		num.text = onTextChanged(value);
		
		bar=new h2d.Graphics(this);
		bar.x = Math.max(20+ num.textWidth, 100);
		bar.y = txt.textHeight;
		
		renderBarForRatio((value - range[0])/(range[1]-range[0]));
		
		var barMargin = 8;
		inter = new h2d.Interactive( barWidth+barMargin*2, 20, bar);
		inter.name = "inter";
		inter.x -= barMargin;
		
		inter.onClick = function(e:hxd.Event) {
			bar.clear();
			var ratio = (e.relX-barMargin) / barWidth;
			if ( ratio > 1.0 ) ratio = 1.0;
			if ( ratio < 0.0 )ratio = 0.0;
			
			renderBarForRatio( ratio );
			var v = ratio * (range[1] - range[0]) + range[0];
			onValueChanged( value = v );
			num.text = onTextChanged(v);
		}
	}
	
	function renderBarForRatio(ratio:Float) {
		//do the outline
		bar.clear();
		bar.lineStyle(2);
		bar.beginFill(0,0.0);
		bar.drawRect( 0, 0, barWidth+hxd.Math.EPSILON, 20);
		
		bar.lineStyle();
		bar.beginFill(0xffffff);
		var w = barWidth * ratio - 2;
		if ( w <= 0.1 ) w = 0.1; //fix for crap
		
		bar.drawRect( 1, 1, w, 20-2);
		bar.endFill();
	}
	
	public function setValue(v:Float) {
		renderBarForRatio((v - range[0]) / (range[1] - range[0]));
		v = Math.fround(v);
		onValueChanged( v );
		num.text = onTextChanged(value = v);
	}
	
}