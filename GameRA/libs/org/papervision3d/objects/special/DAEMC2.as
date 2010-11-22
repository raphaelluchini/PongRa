package org.papervision3d.objects.special 
{
	import flash.events.Event;
	import flash.utils.getTimer;
	import org.papervision3d.core.animation.channel.AbstractChannel3D;
	import org.papervision3d.core.controller.IObjectController;
	import org.papervision3d.core.render.data.RenderSessionData;
	import org.papervision3d.events.FileLoadEvent;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;
	
	/**
	 *	 _____          ______ __  __  _____ ___  
	 *	|  __ \   /\   |  ____|  \/  |/ ____|__ \ 
	 *	| |  | | /  \  | |__  | \  / | |       ) |
	 *	| |  | |/ /\ \ |  __| | |\/| | |      / / 
	 *	| |__| / ____ \| |____| |  | | |____ / /_ 
	 *	|_____/_/    \_\______|_|  |_|\_____|____|
	 * 
	 * What change?
	 * 	-gotoAndStop equivalent now is:   a call to set the currentFrameNumber + a call to stop()
	 *  -gotoAndPlay equivalent now is:   same as above but a call to play().
	 *   example:   gotoAndPlay(3) now is model.currentFrameNumber = 3; model.play()
	 * 
	 * 	-addFrameScript remains the same.
	 *  -to set a frame use model.currentFrameNumber = X  i made it like this so you can use Tween engines to create effects...
	 *  -addFrameLabel removed, if you want it ask me and i'll add it but i got lazy.
	 * 
	 * @author Pablo Bandin (p48l0.84nd1n@gmail.com)
	 * @version 2.0
	 * @date 28-abr-2009
	 * @thanks to roman s. for sugesting this feature.
	 */
	public class DAEMC2 extends DAE
	{
		/** 
		 * this is how many frames you ADD between the original dae keyframes.
		 * @example you want to slow down some model animation by half, so this numbe will be 1 (the original keyframe+1 = 2)
		 */
		protected var _animXframes:uint;
		
		/** current frame is a float */
		protected var _currentframeNumber:Number;
		
		protected var _isStopped:Boolean;
		
		protected var _frameActionCalled:uint;
		
		protected var frameActions:Object;
		
		/** make the animation to play backwards... */
		protected var _inReverse:Boolean;
		
		/**
		 * 
		 * @param	autoPlay  start playing when is loaded?
		 * @param	name	  same as with DAE
		 * @param	Xframes	  how many frames to add between original keyframes?
		 */
		public function DAEMC2(autoPlay:Boolean = true, name:String = null, Xframes:uint = 0) 
		{
			_animXframes = Xframes;
			_currentframeNumber = 0;
			_isStopped = true;
			_frameActionCalled = 0;
			frameActions = new Object();
			_inReverse = false;
			
			// i made loop = true always so is the same as a MovieClip. You put actions to avoid looping.
			super(autoPlay, name, true);
		}
		
		public function get Xframes():uint {
			return _animXframes;
		}
		
		/** set the frames that you want to add in between the original keyframes, these frames are added by interpolating the frames */
		public function set Xframes(newXframes:uint):void {
			_animXframes = newXframes;
			_currentframeNumber = Math.floor(_currentframeNumber);
		}
		
		public override function play(clip:String = null):void 
		{
			super.play(clip);
			_isStopped = false;
		}
		
		public override function stop():void 
		{
			super.stop();
			_isStopped = true;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function project(parent:DisplayObject3D, renderSessionData:RenderSessionData):Number
		{
			// update animation
			if(_isPlaying && _channels)
			{
				var frameIncrement:Number = 1 / (1 + _animXframes);
				
				
				if (_inReverse)
				_currentframeNumber -= frameIncrement;
				else
				_currentframeNumber += frameIncrement;
				
				if (_currentframeNumber < 0)
					_currentframeNumber = _totalFrames - 1; //i'm not sure if i shoudl delete the -1...
				
				if (_currentframeNumber > _totalFrames)
					_currentframeNumber = 0;
					
				callFrameEvent();
				
					for each(var channel:AbstractChannel3D in _channels)
						channel.updateSmoothlyToTime(_currentframeNumber, _animXframes);
			}
			
			// this is to avoid entering in the if(_isPlaying && _channels) of DAE's project method.
			var isP:Boolean = _isPlaying; _isPlaying = false;
			var rtrn:Number = super.project(parent, renderSessionData);
			_isPlaying = isP;
			
			return 	rtrn;
		}
		
		public function addFrameScript(frame:uint, callback:Function= null):void {
			
			frame--;
			
			if (frame > totalFrames)
				return;
				
			if (frameActions[frame] != null)
			{
				frameActions[frame] = null;
			}
			
			frameActions[frame] = callback;
		}
		
		/**
		 * I made this a SET property so you can use a twen engine to create your own crazy animations effects xD
		 */
		public function set currentFrameNumber(frame:Number):void {
			
			if(frame--<0)frame = 0;
			
			if (!(_isAnimated && _channels && _channels.length))
				return;
				
				if (frame > _totalFrames)
					frame = _totalFrames - 1; //i dont remember if is -1 or just totalFrames... too lazy to check
					
				_currentframeNumber = frame;
				
				for each(var channel:AbstractChannel3D in _channels)
					channel.updateSmoothlyToTime(_currentframeNumber, _animXframes, true);
					
			callFrameEvent()
		}
		
		public function get currentFrame():uint { return uint(Math.floor(_currentframeNumber))+1;  }
		public function get currentFrameNumber():Number { return _currentframeNumber + 1;  }
		public function get totalFrames():uint { return _totalFrames;  }
		
		public function get isPlaying():Boolean { return !_isStopped;  }
		
		public function get inReverse():Boolean { return _inReverse; }
		
		public function set inReverse(value:Boolean):void 
		{
			_inReverse = value;
		}
		
		
		protected function callFrameEvent():void {
			
				if (_frameActionCalled!=currentFrame) {
					if (frameActions[currentFrame]!=null) {
						frameActions[currentFrame]();
						_frameActionCalled = currentFrame;
					}
				}
		}
		
		
	}
	
}