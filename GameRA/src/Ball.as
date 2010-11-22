package
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import flashx.textLayout.elements.GlobalSettings;
	
	import utils.Properties;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	
	import view.WebCamState;
	
	public class Ball extends UIComponent
	{
		public var xspeed : Number = 20;
		public var yspeed : Number = 20;
		
		public function Ball() : void
		{
			graphics.beginFill(0xFF0000);
			graphics.drawRect(0,0,20,20);
			graphics.endFill();
		}
		
		public function start() : void
		{
			xspeed = 15;
			yspeed = 8;
			addEventListener( Event.ENTER_FRAME, moveBall );
		}
		
		private function moveBall( _e : Event ) : void
		{
			//depth();
			collision();
			x += xspeed;
			y += yspeed;
		}
		
		private function collision() : void
		{
			if ( x >= Properties.SWF_WIDTH - 75 || x < 50 )
			{
				xspeed *= -1;	
				x += xspeed;
			}
			var raposa:Sprite = Sprite(WebCamState(this.parent).raposa);
			
			if(this.hitTestObject(raposa))
			{
				yspeed *= -1;
				y += yspeed;
			}

			if( y < 50 )
			{
				yspeed *= -1;
				y += yspeed;
			}
			/*
			if ( x < 10 )
			{
				/*if ( x < FlexGlobals.topLevelApplication.stage )
					MovieClip(parent).bg.scoreRight.text = Number(MovieClip(parent).bg.scoreRight.text) + 1;
				else
					MovieClip(parent).bg.scoreLeft.text = Number(MovieClip(parent).bg.scoreLeft.text) + 1;
					
				xspeed = yspeed = 0;
				removeEventListener( Event.ENTER_FRAME, moveBall );	
				y = -height;
				x = stage.stageWidth / 2;
				var scale : Number = (0.5 * 0.6) + 0.6;
				this.y = stage.stageHeight / 2;
				this.scaleX = scale;
				this.scaleY = scale;
				start();*/
				//new TweenLite( this, 1.5, { y: stage.stageHeight / 2, scaleX: scale, scaleY: scale, onComplete: start } );
				/*y = stage.stageHeight / 2;
				x = stage.stageWidth / 2;
				
			}*/
		}
	}
	
}