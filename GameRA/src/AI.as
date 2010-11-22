package
{
	import flash.events.Event;
	
	import mx.core.UIComponent;
	
	public class AI extends UIComponent
	{
		
		public function AI() : void
		{
			//addEventListener( Event.ENTER_FRAME, followBall );
		}
		
		private function followBall( _e : Event ) : void
		{
			var ball : UIComponent = UIComponent( parent.parent ).ball;
			if ( ball.xspeed || ball.yspeed )
			{
				var newy : Number = ball.x - width;
				if ( newy > 345 ) newy = 345;
				
				if ( x <= newy ) x += 9;
				else x -= 9;
			}
		}
	}
	
}