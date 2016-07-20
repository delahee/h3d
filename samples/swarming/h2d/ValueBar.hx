package h2d;

class ValueBar extends h2d.Sprite {
	var font : h2d.Font;
	
	var bar : h2d.Graphics;
	var inter : h2d.Interactive;
	var num : h2d.Number;
	var barWidth = 100;
	
	public dynamic function onValueChanged(f:Float) {}
	inline function f2pc(f:Float) return Math.round(f * 100.0);
		
	public function new(name:String, ?f:h2d.Font, ?p:h2d.Sprite) {
		super(p);
		if ( f == null ) f = hxd.res.FontBuilder.getFont("console", 12);
		this.font = f;
		var txt = new h2d.Text(font,this );
		txt.text = name.toUpperCase();
		var baseRatio = 0.95;
		num = new h2d.Number( font,this);
		num.y = 24;
		num.trailingPercent = true;
		num.nb = f2pc(baseRatio);
		
		bar=new h2d.Graphics(this);
		bar.x = Math.max(20+ num.textWidth, 60);
		bar.y = txt.textHeight;
		
		renderBarForRatio(baseRatio);
		
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
			
			num.nb = f2pc(ratio);
			onValueChanged( ratio );
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
	
	public function setValueF(v:Float) {
		num.nb = f2pc(v);
		renderBarForRatio(v);
	}
	
	public function setValuePc(v:Float) {
		setValueF( v/100 );
	}
}