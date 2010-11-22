package view
{
	import com.greensock.TweenLite;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import utils.ObjectUtils;
	import utils.Properties;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	
	import org.libspark.flartoolkit.core.FLARCode;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.detector.FLARSingleMarkerDetector;
	import org.libspark.flartoolkit.pv3d.FLARBaseNode;
	import org.libspark.flartoolkit.pv3d.FLARCamera3D;
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.events.FileLoadEvent;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.BitmapMaterial;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cube;
	import org.papervision3d.objects.primitives.Plane;
	import org.papervision3d.objects.special.DAEMC2;
	import org.papervision3d.render.BasicRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	
	public class WebCamState extends UIComponent
	{	
		//WEBCAM
		private var video:Video;
		private var cam:Camera;
		public var videoBMD:BitmapData;
		
		//FLAR
		private var flarParams:FLARParam;
		private var mpattern:FLARCode;
		private var raster:FLARRgbRaster_BitmapData;
		private var detector:FLARSingleMarkerDetector;
		private var camera:FLARCamera3D;
		private var baseNode:FLARBaseNode;
		private var trans:FLARTransMatResult;
		
		//PV3D
		private var scene:Scene3D;
		private var viewport:Viewport3D;
		private var render:BasicRenderEngine;
		private var collada:DAEMC2;
		private var objColada:DisplayObject3D;
		
		private var modelObj:Object;

		private var timer:Timer = new Timer(2000);
		public var raposa:Sprite = new Sprite();
		private var ball:Ball = new Ball();
		private var tela:Sprite = new Sprite();
		
		
		public function WebCamState(_modelObj:Object):void 
		{
			modelObj = _modelObj
			setupFlar();
		}
		
		private function setupFlar():void
		{
			
			flarParams = new FLARParam
			var pattern:ByteArray = new utils.ObjectUtils() as ByteArray;
			
			
			flarParams.loadARParam(pattern);
			flarParams.changeScreenSize(Properties.SWF_WIDTH/4, Properties.SWF_HEIGHT/4);
			
			mpattern = new FLARCode(16, 16);
			mpattern.loadARPatt(ObjectUtils.PATTERN);
			setupVideo()

			raster = new FLARRgbRaster_BitmapData(videoBMD);
			
			detector = new FLARSingleMarkerDetector(flarParams, mpattern, 80);
			
			setupPv3d();
			
			addEventListener(Event.ENTER_FRAME, loop);
		}
		
		private function setupVideo():void
		{
			video = new Video(Properties.SWF_WIDTH/4, Properties.SWF_HEIGHT/4);
			
			cam = Camera.getCamera();
			cam.setMode(Properties.SWF_WIDTH/4, Properties.SWF_HEIGHT/4, Properties.SWF_FRAMERATE);
			video.attachCamera(cam);
			video.scaleX = -1;
			video.x = Properties.SWF_WIDTH/4;
			//video.x = Properties.SWF_WIDTH/2 - (video.width/2) + video.width;
			//video.y = Properties.SWF_HEIGHT/2 - (video.height/2);
			addChild(video);
			videoBMD = new BitmapData(Properties.SWF_WIDTH/4, Properties.SWF_HEIGHT/4);
		}

		
		private function setupPv3d():void
		{
			camera 		= new FLARCamera3D(flarParams);
			baseNode	= new FLARBaseNode();
			scene 		= new Scene3D();
			scene.addChild(baseNode);

			render 		= new BasicRenderEngine();
			trans		= new FLARTransMatResult();
			viewport 	= new Viewport3D(Properties.SWF_WIDTH, Properties.SWF_HEIGHT);
			addChild(viewport);
			viewport.alpha = 0;
			this.addEventListener(MouseEvent.CLICK, clickinit);
			
			tela.graphics.beginFill(0x000000, .2);
			tela.graphics.drawRect(50,50, Properties.SWF_WIDTH-100, Properties.SWF_HEIGHT);
			addChild(tela);
		}
		
		protected function clickinit(e:MouseEvent):void 
		{			
			if(baseNode)
			{
				baseNode.autoCalcScreenCoords = true;
			}
			
			raposa.graphics.beginFill(0xFF000);
			raposa.graphics.drawRect(0,0,100,20);
			raposa.graphics.endFill();
			addChild(raposa);
			
			addChild(ball);
			ball.start();
			ball.x = 200;
			ball.y = 200;
			
			raposa.y = Properties.SWF_HEIGHT -20;
			timer.addEventListener(TimerEvent.TIMER, viewTimer);
		}

		private function viewTimer(event:TimerEvent):void
		{
			TweenLite.to(viewport, 1, {alpha:0,visible:false});
		}
		
		private function loop(e:Event):void
		{
			videoBMD.draw(video, video.transform.matrix);
			try{
				if(detector.detectMarkerLite(raster, 80) && detector.getConfidence() > 0.5)
				{
					detector.getTransformMatrix(trans);
					baseNode.setTransformMatrix(trans);
					render.renderScene(scene, camera, viewport);
					viewport.visible = true
					raposa.x = (baseNode.screen.x + (Properties.SWF_WIDTH) * 0.4)
					TweenLite.to(viewport, 1, {alpha:1});
					timer.stop();
				}else{
					timer.start();
				}
			}catch(e:Error){}
			
		}
		
		public function end():void
		{
			removeEventListener(Event.ENTER_FRAME, loop);
			video.attachCamera(null);
			camera 		= null;
			baseNode	= null;
			scene 		= null;
			video		= null;
			cam			= null;
			videoBMD	= null;
			flarParams	= null;
			mpattern = null;
			raster = null;
			detector = null;
		}
	}
}