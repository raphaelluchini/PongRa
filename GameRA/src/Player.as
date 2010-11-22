package
{
	import flash.events.MouseEvent;
	
	import flashx.textLayout.elements.GlobalSettings;
	
	import mx.core.UIComponent;
	
	public class Player extends UIComponent
	{
		public function Player() : void
		{
			stage.addEventListener( MouseEvent.MOUSE_MOVE, moveAlong );
		}
		
		private function moveAlong( _e : MouseEvent ) : void
		{
			var mousePos : Number = FlexGlobals.topLevelApplication.stage.mouseX - parent.x;
			if ( mousePos < 100 )
				x = 110;
			else if ( mousePos > 500 )
				x = 490;
			else
				x = mousePos;
		}
	}
}