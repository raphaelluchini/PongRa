package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	
	public class Game extends UIComponent
	{
		private var ball:Ball = new Ball();
		
		public function Game() : void
		{
			ball.start();
			addChild(ball)
		}
	}
}