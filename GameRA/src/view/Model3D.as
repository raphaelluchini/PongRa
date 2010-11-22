package view
{
	import utils.ObjectUtils;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.core.FlexGlobals;
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.BitmapMaterial;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.parsers.Collada;
	import org.papervision3d.render.BasicRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	import org.papervision3d.objects.special.DAEMC2;
	import org.papervision3d.Papervision3D;
	import org.papervision3d.events.FileLoadEvent;
	
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class Model3D extends UIComponent
	{
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var renderer:BasicRenderEngine;
		private var viewport:Viewport3D;
		private var collada:DAEMC2;
		public var faceMaterial:MaterialObject3D;
		public var materials:MaterialsList = new MaterialsList();
		
		public var texture:Bitmap = new utils.ObjectUtils() as Bitmap;
		public var texture1:Bitmap = new utils.ObjectUtils() as Bitmap;
		protected var loading:TextField;
		
		
		public function Model3D()
		{
			this.addEventListener(FlexEvent.CREATION_COMPLETE, create);
		}
		private function create(event:FlexEvent):void
		{
			viewport = new Viewport3D(this.width, this.height, false, true);
			addChild(viewport);
			
			scene = new Scene3D();
			camera = new Camera3D();
			renderer = new BasicRenderEngine();
			
			var light:PointLight3D = new PointLight3D(true);
			light.x = 1000;
		    light.y = 1000;
		    light.z = -1000;

			materials.addMaterial(new BitmapMaterial(texture1.bitmapData), 'face');
			materials.addMaterial(new BitmapMaterial(texture.bitmapData), 'roupa');
			materials.addMaterial(new ColorMaterial(0xe9e4c8), 'mao');
			materials.addMaterial(new ColorMaterial(0xb80606), 'tie');
			
			collada = new DAEMC2(true, null, 0);
			collada.load(ObjectUtils.DAE, materials );
			collada.scale = 2;
			camera.z = -100
			collada.y = -25
			collada.addEventListener(FileLoadEvent.ANIMATIONS_COMPLETE, addIt2Stage);
			
			var tf:TextFormat = new TextFormat("Verdana", 10, 0);
			loading = new TextField();
			loading.defaultTextFormat = tf;
			loading.text = "Carregando Modelo";
			loading.width = 150
			loading.x = (this.width/2)-(loading.width/2)
			loading.y = (this.height/2)-(loading.height/2)
			addChild(loading);
			FlexGlobals.topLevelApplication.desactiveRadios()
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
		}
		protected function addIt2Stage(e:FileLoadEvent):void 
		{
			scene.addChild(collada);
			loading.text = "";
			FlexGlobals.topLevelApplication.activeRadios()
		}
		public function reloadDAE(objMaterial:Object):void
		{
			scene.removeChild(collada);
			materials = new MaterialsList();
			if(objMaterial.sexo == "M"){
				materials.addMaterial(new BitmapMaterial(objMaterial.face), "face");
				materials.addMaterial(new BitmapMaterial(objMaterial.roupa), 'roupa');
				materials.addMaterial(new ColorMaterial(objMaterial.mao), 'mao');
				materials.addMaterial(new ColorMaterial(objMaterial.tie), 'tie');
			}else{
				materials.addMaterial(new ColorMaterial(objMaterial.Cabelo), "Cabelo");
				materials.addMaterial(new BitmapMaterial(objMaterial.Vestido), 'Vestido');
				materials.addMaterial(new BitmapMaterial(objMaterial.Corpo), 'Corpo');
				materials.addMaterial(new BitmapMaterial(objMaterial.Rosto), 'Rosto');
			}
			collada.load(ObjectUtils.DAE, materials );
			collada.addEventListener(FileLoadEvent.ANIMATIONS_COMPLETE, addIt2Stage);
			FlexGlobals.topLevelApplication.desactiveRadios()
			loading.text = "Carregando Modelo";
			collada.scale = 2;
			camera.z = -100
			collada.y = -25
		}
		private function onEnterFrame(e:Event):void
		{
			collada.rotationY += 2;
			renderer.renderScene(scene, camera, viewport);
		}
	}
}