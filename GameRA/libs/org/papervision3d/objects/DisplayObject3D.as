﻿/**
 * gotoTransform() added by Pablo Bandin.
 */
package org.papervision3d.objects
{
	import flash.display.BlendMode;
	
	import org.papervision3d.Papervision3D;
	import org.papervision3d.core.culling.FrustumTestMethod;
	import org.papervision3d.core.data.UserData;
	import org.papervision3d.core.geom.renderables.Triangle3D;
	import org.papervision3d.core.log.PaperLogger;
	import org.papervision3d.core.material.AbstractLightShadeMaterial;
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.core.math.Quaternion;
	import org.papervision3d.core.proto.CameraObject3D;
	import org.papervision3d.core.proto.DisplayObjectContainer3D;
	import org.papervision3d.core.proto.GeometryObject3D;
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.core.proto.SceneObject3D;
	import org.papervision3d.core.render.data.RenderSessionData;
	import org.papervision3d.materials.shaders.ShadedMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.view.Viewport3D;
	import org.papervision3d.view.layer.ViewportLayer;

	/**
	 * The DisplayObject class represents instances of 3D objects that are contained in the scene.
	* <p/>
	* That includes all objects in the scene, not only those that can be rendered, but also the camera and its target.
	* <p/>
	* The DisplayObject3D class supports basic functionality like the x, y and z position of an object, as well as rotationX, rotationY, rotationZ, scaleX, scaleY and scaleZ and visible. It also supports more advanced properties of the object such as its transform Matrix3D.
	* <p/>
	* <p/>
	* DisplayObject3D is not an abstract base class; therefore, you can call DisplayObject3D directly. Invoking new DisplayObject() creates a new empty object in 3D space, like when you used createEmptyMovieClip().
	*
	*/
	public class DisplayObject3D extends DisplayObjectContainer3D
	{
	   /**
		* tells Mesh3D's render() method to sort by measuring from the center of a triangle
		*/
		public static const MESH_SORT_CENTER:uint = 1;
		
		/**
		* tells Mesh3D's render() method to sort by measuring from the farthest point of a triangle
		*/
		public static const MESH_SORT_FAR:uint = 2;
		
		/**
		* tells Mesh3D's render() method to sort by measuring from the closest point of a triangle
		*/
		public static const MESH_SORT_CLOSE:uint = 3;
		
/**
		* A Matrix3D object containing values that affect the scaling, rotation, and translation of the display object.
		*/
		public var transform :Matrix3D;
	
		/**
		* [internal-use] A camera transformed Matrix3D object.
		*/
		public var view      :Matrix3D;
	
		/**
		* World transformation.
		*/
		public var world     :Matrix3D;
	
		/**
		* [internal-use]
		*/
		public var faces     :Array = new Array();
	
		/**
		 * This allows objects faces to have their own containers.
		 */
		public static var faceLevelMode  :Boolean;
		
		public static var sortedArray:Array = new Array();
		
		/**
		* The GeometryObject3D object that contains the 3D definition of this instance.
		* <p/>
		* When different objects share the same geometry, they become instances. They are the same object, displayed multiple times. Changing the shape of this object changes the shape of all of its instances.
		* <p/>
		* Instancing an object saves system memory, and is useful to display an object multiple times while maintaining its shape.
		* <p/>
		* For example, you could create armies and forests full of duplicate objects without needing the memory to handle that much actual geometry. Each instance has its own transform node so it can have its own position, rotation, and scaling.
		*/
		public var geometry :GeometryObject3D;
	
		/**
		* [internal-use] The average depth of the object faces center. Used internally for z-sorting.
		*/
		public var screenZ :Number;
	
		/**
		* [internal use] Is this object culled by camera frustum?
		*/
		public var culled:Boolean;
		
		/**
		* The list of materials for this instance.
		*/
		public var materials   :MaterialsList;
		
		/**
		* tells Mesh3D's render() method to compare the measurement choice of the user for a triangle's sorting
		*/
		public var meshSort:uint = MESH_SORT_CENTER;
		
		public var container			:ViewportLayer;	
		public var alpha				:Number = 1;
		public var blendMode			:String = BlendMode.NORMAL;
		public var filters				:Array = [];
		public var parentContainer		:DisplayObject3D;
		public var flipLightDirection	:Boolean = false;
		public var frustumTestMethod	:int = FrustumTestMethod.BOUNDING_SPHERE;
		
		/**
		* [read-only] Indicates the DisplayObjectContainer3D object that contains this display object.
		*/
		public var parent :DisplayObjectContainer3D;
		
		/**
		* [read-only] The coordinate of the object on screen.
		*/
		public var screen :Number3D = new Number3D();
	
		/**
		* Whether or not the display object is visible.
		* <p/>
		* A Boolean value that indicates whether the object is projected, transformed and rendered. A value of false will effectively ignore the object. The default value is true.
		*/
		public var visible :Boolean;
	
		/**
		* An optional object name.
		*/
		public var name :String;
	
		/**
		* [read-only] Unique id of this instance.
		*/
		public var id :int;

		/**
		* An object that contains user defined properties.
		* <p/>
		* All properties of the extra field are copied into the new instance. The properties specified with extra are publicly available.
		*/
		public var extra :Object; // = {}; TBD
		
		
		public var cullTest:Number = 0;
		public var useClipping:Boolean = true;
		
		public var testQuad:Boolean = true;
				
		/**
		* Relative directions.
		*/
		static private const FORWARD  	:Number3D = new Number3D(  0,  0,  1 );
		static private const BACKWARD 	:Number3D = new Number3D(  0,  0, -1 );
		static private const LEFT     	:Number3D = new Number3D( -1,  0,  0 );
		static private const RIGHT    	:Number3D = new Number3D(  1,  0,  0 );
		static private const UP       	:Number3D = new Number3D(  0,  1,  0 );
		static private const DOWN     	:Number3D = new Number3D(  0, -1,  0 );
		
		private static var _tempMatrix	:Matrix3D = Matrix3D.IDENTITY; 
		private static var _tempQuat	:Quaternion = new Quaternion(); 
		private static var _newID		:int = 0;
		private static var toDEGREES 	:Number = 180/Math.PI;
		private static var toRADIANS 	:Number = Math.PI/180;
		private static var entry_count	:uint = 0;
		
		/**
		* [internal-use]
		*/
		protected var _transformDirty 	:Boolean = false;
		protected var _sorted       	:Array;
		protected var _useOwnContainer	:Boolean = false;
		protected var _userData			:UserData;
		
		/**
		* The scene where the object belongs.
		*/
		protected var _scene 			:SceneObject3D = null;
			
		/**
		 * pre-made Number3Ds and Matrix3Ds for use in the lookAt function
		 * and others
		 * 
		 */
		private	var _position 			:Number3D = Number3D.ZERO;
		private	var _lookatTarget   	:Number3D = Number3D.ZERO;
		private	var _zAxis 				:Number3D = Number3D.ZERO;
		private	var _xAxis 				:Number3D = Number3D.ZERO;
		private	var _yAxis 				:Number3D = Number3D.ZERO;
		private var _rotation			:Number3D  = Number3D.ZERO; 
		private var _rotationDirty  	:Boolean = false;
		private var _rotationX      	:Number;
		private var _rotationY     	 	:Number;
		private var _rotationZ      	:Number;
		private var _scaleX         	:Number;
		private var _scaleY         	:Number;
		private var _scaleZ         	:Number;
		private var _scaleDirty     	:Boolean = false;
		private var _tempScale			:Number3D;
		private var _numClones			:uint	= 0;
		private var _material			:MaterialObject3D;
		private var _rot				:Quaternion = new Quaternion();
		
		private var _qPitch		:Quaternion = new Quaternion();
		private var _qYaw		:Quaternion = new Quaternion();
		private var _qRoll		:Quaternion = new Quaternion();
		
		private var _localRotationX	:Number = 0;
		private var _localRotationY	:Number = 0;
		private var _localRotationZ	:Number = 0;
		
		private var _autoCalcScreenCoords:Boolean = false;
		/**
		* Returns an empty DiplayObject3D object positioned in the center of the 3D coordinate system (0, 0 ,0).
		*/
		static public function get ZERO():DisplayObject3D
		{
			return new DisplayObject3D();
		}
		
		public function set useOwnContainer(value:Boolean):void
		{
			_useOwnContainer = value;
			setParentContainer(this, true);
		}
		
		public function get useOwnContainer():Boolean
		{
			return _useOwnContainer;
		}
		
		public function set userData(userData:UserData):void
		{
			_userData = userData;
		}
		
		public function get userData():UserData
		{
			return _userData;	
		}
		
		/**
		* An Number that sets the X coordinate of a object relative to the origin of its parent.
		*/
		public function get x():Number
		{
			return this.transform.n14;
		}
	
		public function set x( value:Number ):void
		{
			this.transform.n14 = value;
		}
		
		/**
		* An Number that sets the Y coordinate of a object relative to the origin of its parent.
		*/
		public function get y():Number
		{
			return this.transform.n24;
		}
	
		public function set y( value:Number ):void
		{
			this.transform.n24 = value;
		}
	
		/**
		* An Number that sets the Z coordinate of a object relative to the origin of its parent.
		*/
		public function get z():Number
		{
			return this.transform.n34;
		}
	
		public function set z( value:Number ):void
		{
			this.transform.n34 = value;
		}
		
		/**
		 * A Number3D containing the current x, y, and z of the DisplayObject3D
		 */
		 
		 public function get position():Number3D
		 {
		 	_position.reset(this.x, this.y, this.z);
		 	return _position;
		}

		public function set position(n:Number3D):void
		 {
		 	this.x = n.x;
		 	this.y = n.y;
		 	this.z = n.z;
		 }
		 
		/**
		* Specifies the rotation around the X axis from its original orientation.
		*/
		public function get rotationX():Number
		{
			if( this._rotationDirty ) updateRotation();
	
			return Papervision3D.useDEGREES ? this._rotationX * toDEGREES : this._rotationX;
		}
	
		public function set rotationX( rot:Number ):void
		{
			this._rotationX = Papervision3D.useDEGREES ? rot * toRADIANS : rot;

			this._transformDirty = true;
		}
	
		/**
		* Specifies the rotation around the Y axis from its original orientation.
		*/
		public function get rotationY():Number
		{
			if( this._rotationDirty ) updateRotation();
	
			return Papervision3D.useDEGREES ? this._rotationY * toDEGREES : this._rotationY;
		}
	
		public function set rotationY( rot:Number ):void
		{
			this._rotationY = Papervision3D.useDEGREES ? rot * toRADIANS : rot;
		
			this._transformDirty = true;
		}
	
		/**
		* Specifies the rotation around the Z axis from its original orientation.
		*/
		public function get rotationZ():Number
		{
			if( this._rotationDirty ) updateRotation();
	
			return Papervision3D.useDEGREES ? this._rotationZ * toDEGREES : this._rotationZ;
		}
	
		public function set rotationZ( rot:Number ):void
		{
			this._rotationZ = Papervision3D.useDEGREES ? rot * toRADIANS : rot;
			
			this._transformDirty = true;
		}

		// ___________________________________________________________________ S C A L E
	
		/**
		* Sets the 3D scale as applied from the registration point of the object.
		*/
		public function get scale():Number
		{
			if( this._scaleX == this._scaleY && this._scaleX == this._scaleZ )
				if( Papervision3D.usePERCENT ) return this._scaleX * 100;
				else return this._scaleX;
			else return NaN;
		}
	
		public function set scale( scale:Number ):void
		{
			if( this._rotationDirty ) updateRotation();
			
			
			if( Papervision3D.usePERCENT ) scale /= 100;
	
			this._scaleX = this._scaleY = this._scaleZ = scale;
	
			this._transformDirty = true;
		}
	
	
		/**
		* Sets the scale along the local X axis as applied from the registration point of the object.
		*/
		public function get scaleX():Number
		{
			if( Papervision3D.usePERCENT ) return this._scaleX * 100;
			else return this._scaleX;
		}
	
		public function set scaleX( scale:Number ):void
		{
			if( this._rotationDirty ) updateRotation();
			
			if( Papervision3D.usePERCENT ) this._scaleX = scale / 100;
			else this._scaleX = scale;
	
			this._transformDirty = true;
		}
	
		/**
		* Sets the scale along the local Y axis as applied from the registration point of the object.
		*/
		public function get scaleY():Number
		{
			if( Papervision3D.usePERCENT ) return this._scaleY * 100;
			else return this._scaleY;
		}
	
		public function set scaleY( scale:Number ):void
		{
			if( this._rotationDirty ) updateRotation();
			
			if( Papervision3D.usePERCENT ) this._scaleY = scale / 100;
			else this._scaleY = scale;
	
			this._transformDirty = true;
		}
	
		/**
		* Sets the scale along the local Z axis as applied from the registration point of the object.
		*/
		public function get scaleZ():Number
		{
			if( Papervision3D.usePERCENT ) return this._scaleZ * 100;
			else return this._scaleZ;
		}
	
		public function set scaleZ( scale:Number ):void
		{
			if( this._rotationDirty ) updateRotation();
			
			if( Papervision3D.usePERCENT ) this._scaleZ = scale / 100;
			else this._scaleZ = scale;
	
			this._transformDirty = true;
		}
	
		
		
	
		/**
		* The X coordinate of a object relative to the scene coordinate system.
		*/
		public function get sceneX():Number
		{
			return this.world.n14;
		}
	
		/**
		* The Y coordinate of a object relative to the scene coordinate system.
		*/
		public function get sceneY():Number
		{
			return this.world.n24;
		}
	
		/**
		* The Z coordinate of a object relative to the scene coordinate system.
		*/
		public function get sceneZ():Number
		{
			return this.world.n34;
		}

		/**
		* The default material for the object instance. Materials collect data about how objects appear when rendered.
		*/
		public function set material(material:MaterialObject3D):void
		{
			if(_material){
				_material.unregisterObject(this);
			}
			_material = material;
			if (_material){
				_material.registerObject(this);
			}
		}
		
		public function get material():MaterialObject3D
		{
			return _material;
		}
		
		public function set scene(p_scene:SceneObject3D):void
		{
			// set scene property
			_scene = p_scene;
			
			for each( var child:DisplayObject3D in this._childrenByName )
			{
				if(child.scene == null) child.scene = _scene;
			}
		}
		
		public function get scene():SceneObject3D
		{
			return _scene;
		}
		
		public function set autoCalcScreenCoords(autoCalculateScreenCoords:Boolean):void
		{
			_autoCalcScreenCoords = autoCalculateScreenCoords;
		}
		
		public function get autoCalcScreenCoords():Boolean
		{
			return _autoCalcScreenCoords ;
		}
	
		/**
		* Creates a new DisplayObject3D instance. After creating the instance, call the addChild() method of a DisplayObjectContainer3D.
		*
		* @param	name		[optional] - The name of the newly created object.
		* @param	geometry	[optional] - The geometry of the newly created object.
		*
		* <ul>
		* <li><b>x</b></b>: An Number that sets the X coordinate of a object relative to the scene coordinate system.</li>
		* <p/>
		* <li><b>y</b>: An Number that sets the Y coordinate of a object relative to the scene coordinate system.</li>
		* <p/>
		* <li><b>z</b>: An Number that sets the Z coordinate of a object relative to the scene coordinate system.</li>
		* <p/>
		* <li><b>rotationX</b>: Specifies the rotation around the X axis from its original orientation.</li>
		* <p/>
		* <li><b>rotationY</b>: Specifies the rotation around the Y axis from its original orientation.</li>
		* <p/>
		* <li><b>rotationZ</b>: Specifies the rotation around the Z axis from its original orientation.</li>
		* <p/>
		* <li><b>scaleX</b>: Sets the scale along the local X axis as applied from the registration point of the object.</li>
		* <p/>
		* <li><b>scaleY</b>: Sets the scale along the local Y axis as applied from the registration point of the object.</li>
		* <p/>
		* <li><b>scaleZ</b>: Sets the scale along the local Z axis as applied from the registration point of the object.</li>
		* <p/>
		* <li><b>visible</b>: Whether or not the display object is visible.
		* <p/>
		* A Boolean value that indicates whether the object is projected, transformed and rendered. A value of false will effectively ignore the object. The default value is true.</li>
		* <p/>
		* <li><b>container</b>: The MovieClip that you draw into when rendering. Use only when the object is rendered in its own unique MovieClip.
		* <p/>
		* It's Boolean value determines whether the container MovieClip should be cleared before rendering.</li>
		* <p/>
		* <li><b>extra</b>: An object that contains user defined properties.
		* <p/>
		* All properties of the extra field are copied into the new instance. The properties specified with extra are publicly available.</li>
		* </ul>
		*/
		public function DisplayObject3D( name:String=null, geometry:GeometryObject3D=null ):void
		{
			super();
			
			if(name!=null){
				PaperLogger.info( "DisplayObject3D: " + name );
			}
			this.culled    = false;
			
			this.transform = Matrix3D.IDENTITY;
			this.world     = Matrix3D.IDENTITY;
			this.view      = Matrix3D.IDENTITY;
	
			this.x =  0;
			this.y =  0;
			this.z =  0;
			
			rotationX = 0;
			rotationY = 0;
			rotationZ = 0;
	
			_localRotationX = _localRotationY = _localRotationZ = 0;
			
			var scaleDefault:Number = Papervision3D.usePERCENT? 100 : 1;
			scaleX = scaleDefault;
			scaleY = scaleDefault;
			scaleZ = scaleDefault;
			_tempScale = new Number3D();
			
			this.visible = true;
	
			this.id = _newID++;
			this.name = name || String( this.id );
	
			_numClones = 0;
			
			if( geometry ) addGeometry( geometry );
		}
	
		
		/**
		* Adds a child DisplayObject3D instance to this DisplayObjectContainer instance.
		*
		* [TODO: If you add a child object that already has a different display object container as a parent, the object is removed from the child list of the other display object container.]
		*
		* @param	child	The DisplayObject3D instance to add as a child of this DisplayObjectContainer3D instance.
		* @param	name	An optional name of the child to add or create. If no name is provided, the child name will be used.
		* @return	The DisplayObject3D instance that you have added or created.
		*/
		public override function addChild( child :DisplayObject3D, name:String=null ):DisplayObject3D
		{
			child = super.addChild( child, name );
			
			if( child.scene == null ) child.scene = scene;
			if( this.useOwnContainer){
					child.parentContainer = this;
			}
			return child;
		}
		
		/**
		* Adds a geometry definition to the instance.
		*
		* A geometry describes the visual shape and appearance of an object in a scene.
		*
		* @param	geometry	A geometry definition.
		*/
		public function addGeometry( geometry:GeometryObject3D=null ):void
		{
			if( geometry )
				this.geometry = geometry;	
		}
		
		/**
		 * Clones this object.
		 * 
		 * @return	The cloned DisplayObject3D.
		 */ 
		public function clone():DisplayObject3D
		{
			var name:String = this.name + "_" + (_numClones++);
			var object:DisplayObject3D = new DisplayObject3D(name);

			if(this.material)
				object.material = this.material;
			
			if(this.materials)
				object.materials = this.materials.clone();
				
			if(this.geometry)
			{
				object.geometry = this.geometry.clone(object);
				object.geometry.ready = true;
			}
			
			object.copyTransform(this);
			
			for each(var child:DisplayObject3D in this.children)
				object.addChild(child.clone());
				
			return object;
		}
		

		/**
		* Gets the distance to the position of the given object.
		*
		* @param	obj		The display object to measure the distance to.
		* @return	The distance to the registration point of the given object.
		*/
		public function distanceTo( obj:DisplayObject3D ):Number
		{
			var x :Number = this.x - obj.x;
			var y :Number = this.y - obj.y;
			var z :Number = this.z - obj.z;
	
			return Math.sqrt( x*x + y*y + z*z );
		}
	
	
		/**
		* Evaluates the display object to see if it overlaps or intersects with the point specified by the x, y and z parameters.
		* <p/>
		* The x, y and z parameters specify a point in the coordinate space of the instance parent object, not the scene (unless that parent object is the scene).
		*
		* @param	x	The x coordinate to test against this object.
		* @param	y	The y coordinate to test against this object.
		* @param	z	The z coordinate to test against this object.
		* @return	true if the display object overlaps or intersects with the specified point; false otherwise.
		*/
		public function hitTestPoint( x:Number, y:Number, z:Number ):Boolean
		{
			var dx :Number = this.x - x;
			var dy :Number = this.y - y;
			var dz :Number = this.z - z;
	
			var d2 :Number = dx*dx + dy*dy + dz*dz;
	
			var sA :Number = this.geometry? this.geometry.boundingSphere.maxDistance : 0;
	
			return sA > d2;
		}
	
	
		/**
		* Evaluates the display object to see if it overlaps or intersects with the obj display object.
		*
		* @param	obj	 The display object to test against.
		* @return	true if the display objects intersect; false if not.
		*/
		// TODO: Use group boundingSphere
		public function hitTestObject( obj:DisplayObject3D, multiplier:Number=1 ):Boolean
		{
			var dx :Number = this.x - obj.x;
			var dy :Number = this.y - obj.y;
			var dz :Number = this.z - obj.z;
	
			var d2 :Number = dx*dx + dy*dy + dz*dz;
	
			var sA :Number = this.geometry? this.geometry.boundingSphere.maxDistance : 0;
			var sB :Number = obj.geometry?  obj.geometry.boundingSphere.maxDistance  : 0;
			
			sA = sA * multiplier;
	
			return sA + sB > d2;
		}
	
		// ___________________________________________________________________________________________________
		//                                                                                   M A T E R I A L S
	
		/**
		* Returns the material that exists with the specified name in the materials list.
		* </p>
		* If more that one material object has the specified name, the method returns the first material object in the materials list.
		* </p>
		* @param	name	The name of the material to return.
		* @return	The material object with the specified name.
		*/
		// TODO: Recursive
		public function getMaterialByName( name:String ):MaterialObject3D
		{
			var material:MaterialObject3D = this.materials ? this.materials.getMaterialByName( name ) : null;
			if( material )
			{
				return material;
			}
			else
			{
				for each( var child :DisplayObject3D in this._childrenByName )
				{
					material = child.getMaterialByName( name );
					if( material ) return material;
				}
			}
			return null;
		}
	
		/**
		* Returns a string value with the list of material names of the materials list.
		*
		* @return	A string.
		*/
		// TODO: Recursive
		public function materialsList():String
		{
			var list:String = "";
	
			for( var name:String in this.materials )
				list += name + "\n";
	
			for each( var child :DisplayObject3D in this._childrenByName )
			{
				for( name in child.materials.materialsByName )
					list += "+ " + name + "\n";
			}
	
			return list;
		}
		
		
		/**
		 * Replaces a material by its name.
		 * 
		 * @param	material
		 * @param	name
		 * @return
		 */
		public function replaceMaterialByName(material:MaterialObject3D, name:String):void
		{
			if(!this.materials)
				return;
			
			var existingMaterial:MaterialObject3D = this.materials.getMaterialByName(name);
			if(!existingMaterial)
				return;
				
			if(this.material === existingMaterial)
				this.material = material;
			existingMaterial = this.materials.removeMaterial(existingMaterial);
	
			material = this.materials.addMaterial(material, name);
				
			updateMaterials(this, existingMaterial, material);
		}
		
		/**
		 * Sets the material for a child DisplayObject3D.
		 * 
		 * @param child		A child DisplayObject3D of this DAE.
		 * @param material	The new material for the child.
		 * @param existingMaterial Optional existing material to be replaced.
		 */
		public function setChildMaterial(child:DisplayObject3D, material:MaterialObject3D, existingMaterial:MaterialObject3D=null):void 
		{	
			if(!child) 
				return;	
			
			if(!existingMaterial || child.material === existingMaterial)
				child.material = material;
				
			if(child.geometry && child.geometry.faces)
			{
				for each( var triangle:Triangle3D in child.geometry.faces )
				{
					if(!existingMaterial || triangle.material === existingMaterial)
						triangle.material = material;
				}
			}
		}
		
		/**
		 * Sets the material for a child DisplayObject3D by the child's name.
		 * 
		 * @param childName The name of the DisplayObject3D.
		 * @param material	The new material for the child.
		 */
		public function setChildMaterialByName(childName:String, material:MaterialObject3D):void 
		{
			setChildMaterial(getChildByName(childName, true), material);
		}
		
		
		
		/**
		 * 
		 * @param	do3d
		 * @param	existingMaterial
		 * @param	newMaterial
		 */
		private function updateMaterials(do3d:DisplayObject3D, existingMaterial:MaterialObject3D, newMaterial:MaterialObject3D):void
		{
			existingMaterial.unregisterObject(do3d);
			
			// register shaded materials with its object
			if(newMaterial is AbstractLightShadeMaterial || newMaterial is ShadedMaterial)
			{
				newMaterial.registerObject(do3d);
			}
					
			if( do3d.material === existingMaterial )
				do3d.material = newMaterial;
					
			if( do3d.geometry && do3d.geometry.faces && do3d.geometry.faces.length )
			{
				for each( var triangle:Triangle3D in do3d.geometry.faces )
				{
					if( triangle.material === existingMaterial )
						triangle.material = newMaterial;
				}
			}
			
			for each(var child:DisplayObject3D in do3d.children)
				updateMaterials(child, existingMaterial, newMaterial);
		}
		
		
		
	
		/**
		* [internal-use] Projects three dimensional coordinates onto a two dimensional plane to simulate the relationship of the camera to subject.
		* <p/>
		* This is the first step in the process of representing three dimensional shapes two dimensionally.
		*
	 	* @param	parent	The DisplayObject3D object that contains this display object.
		* @param	renderSessionData Data for the current render.
		*/
		public function project( parent :DisplayObject3D, renderSessionData:RenderSessionData):Number
		{
			if( this._transformDirty ) updateTransform();
	
			this.world.calculateMultiply( parent.world, this.transform );
			
			if( renderSessionData.camera.culler )
			{
				if( this === renderSessionData.camera )
					this.culled = true;
				else
					this.culled = (renderSessionData.camera.culler.testObject(this) < 0);
				if( this.culled ){
					renderSessionData.renderStatistics.culledObjects ++ ;
					return 0;
				} 			
			}
			else
			{
				this.culled = false;
			}
			
			if( parent !== renderSessionData.camera )
			{
				if(renderSessionData.camera.useProjectionMatrix)
					this.view.calculateMultiply4x4( parent.view, this.transform );
				else
					this.view.calculateMultiply( parent.view, this.transform );
			}
			else
			{
				if(renderSessionData.camera.useProjectionMatrix)
					this.view.calculateMultiply4x4( renderSessionData.camera.eye, this.transform );
				else
					this.view.calculateMultiply( renderSessionData.camera.eye, this.transform );
			}
			
			if(_autoCalcScreenCoords){
				calculateScreenCoords(renderSessionData.camera);
			}
			
			var screenZs :Number = 0;
			var children :Number = 0;
					
			for each( var child:DisplayObject3D in this._childrenByName )
			{
				if( child.visible )
				{
					screenZs += child.project( this, renderSessionData );
					children++;
				}
			}
	
			return this.screenZ = screenZs / children;
		}
		
		
		
		/**
		 * 
		 */
		public function calculateScreenCoords( camera :CameraObject3D ):void
		{
			if(camera.useProjectionMatrix)
			{
				var vx	:Number = 0;
				var vy	:Number = 0;
				var vz	:Number = 0;
				var w	:Number = vx * view.n41 + vy * view.n42 + vz * view.n43 + view.n44;
				var vpw	:Number = camera.viewport.width / 2;
				var vph	:Number = camera.viewport.height / 2;
				
				screen.x = (vx * view.n11 + vy * view.n12 + vz * view.n13 + view.n14) / w;
				screen.y = (vx * view.n21 + vy * view.n22 + vz * view.n23 + view.n24) / w;
				screen.z = vx * view.n31 + vy * view.n32 + vz * view.n33 + view.n34;
				
				screen.x *= vpw;
				screen.y *= vph;
			}
			else
			{
				var persp:Number = (camera.focus * camera.zoom) / (camera.focus + view.n34);
				screen.x = view.n14 * persp;
				screen.y = view.n24 * persp;
				screen.z = view.n34;
			}
		}
	
		/**
		* Translate the display object in the direction it is facing, i.e. it's positive Z axis.
		*
		* @param	distance	The distance that the object should move forward.
		*/
		public function moveForward  ( distance:Number ):void { translate( distance, FORWARD  ); }
	
		/**
		* Translate the display object in the opposite direction it is facing, i.e. it's negative Z axis.
		*
		* @param	distance	The distance that the object should move backward.
		*/
		public function moveBackward ( distance:Number ):void { translate( distance, BACKWARD ); }
	
		/**
		* Translate the display object lateraly, to the left of the direction it is facing, i.e. it's negative X axis.
		*
		* @param	distance	The distance that the object should move left.
		*/
		public function moveLeft     ( distance:Number ):void { translate( distance, LEFT     ); }
	
		/**
		* Translate the display object lateraly, to the right of the direction it is facing, i.e. it's positive X axis.
		*
		* @param	distance	The distance that the object should move right.
		*/
		public function moveRight    ( distance:Number ):void { translate( distance, RIGHT    ); }
	
		/**
		* Translate the display object upwards, with respect to the direction it is facing, i.e. it's positive Y axis.
		*
		* @param	distance	The distance that the object should move up.
		*/
		public function moveUp       ( distance:Number ):void { translate( distance, UP       ); }
	
		/**
		* Translate the display object downwards, with respect to the direction it is facing, i.e. it's negative Y axis.
		*
		* @param	distance	The distance that the object should move down.
		*/
		public function moveDown     ( distance:Number ):void { translate( distance, DOWN     ); }
	
		// ___________________________________________________________________________________________________
		//                                                                   L O C A L   T R A N S L A T I O N
	
		/**
		* Move the object along a given direction.
		*
		* @param	distance	The distance that the object should travel.
		* @param	axis		The direction that the object should move towards.
		*/
		public function translate( distance:Number, axis:Number3D ):void
		{
			var vector:Number3D = axis.clone();
	
			if( this._transformDirty ) updateTransform();
	
			Matrix3D.rotateAxis( transform, vector );
	
			this.x += distance * vector.x;
			this.y += distance * vector.y;
			this.z += distance * vector.z;
		}
	
		// ___________________________________________________________________________________________________
		//                                                                         L O C A L   R O T A T I O N
		
		/**
		* Rotate the display object around its lateral or transverse axis —an axis running from the pilot's left to right in piloted aircraft, and parallel to the wings of a winged aircraft; thus the nose pitches up and the tail down, or vice-versa.
		*
		* @param	angle	The angle to rotate.
		*/
		public function set localRotationX( angle:Number ):void
		{
			angle = Papervision3D.useDEGREES? angle * toRADIANS : angle;

			if( this._transformDirty ) updateTransform();

			_qPitch.setFromAxisAngle(transform.n11, transform.n21, transform.n31, _localRotationX-angle );
			
			this.transform.calculateMultiply3x3( _qPitch.matrix , transform );
			
			_localRotationX = angle;
			
			_rotationDirty = true;
		}
		
		public function get localRotationX():Number
		{
			return Papervision3D.useDEGREES ? _localRotationX * toDEGREES : _localRotationX;
		}
		
		/**
		* Rotate the display object around about the vertical axis —an axis drawn from top to bottom.
		*
		* @param	angle	The angle to rotate.
		*/
		public function set localRotationY( angle:Number ):void
		{
			angle = Papervision3D.useDEGREES? angle * toRADIANS : angle;

			if( _transformDirty ) updateTransform();

			_qYaw.setFromAxisAngle( transform.n12, transform.n22, transform.n32, _localRotationY-angle );

			transform.calculateMultiply3x3( _qYaw.matrix, transform );
			
			_localRotationY = angle;
			
			_rotationDirty = true;
		}
		
		public function get localRotationY():Number
		{
			return Papervision3D.useDEGREES ? _localRotationY * toDEGREES : _localRotationY;
		}
		
		/**
		* Rotate the display object around the longitudinal axis —an axis drawn through the body of the vehicle from tail to nose in the normal direction of flight, or the direction the object is facing.
		*
		* @param	angle
		*/
		public function set localRotationZ( angle:Number ):void
		{
			angle = Papervision3D.useDEGREES? angle * toRADIANS : angle;
	
			if( _transformDirty ) updateTransform();

			_qRoll.setFromAxisAngle( transform.n13, transform.n23, transform.n33, _localRotationZ-angle );
			
			transform.calculateMultiply3x3( _qRoll.matrix, transform );
			
			_localRotationZ = angle;
			
			_rotationDirty = true;
		}
		
		public function get localRotationZ():Number
		{
			return Papervision3D.useDEGREES ? _localRotationZ * toDEGREES : _localRotationZ;
		}
		
		/**
		* Rotate the display object around its lateral or transverse axis —an axis running from the pilot's left to right in piloted aircraft, and parallel to the wings of a winged aircraft; thus the nose pitches up and the tail down, or vice-versa.
		*
		* @param	angle	The angle to rotate.
		*/
		public function pitch( angle:Number ):void
		{
			angle = Papervision3D.useDEGREES? angle * toRADIANS : angle;

			if( this._transformDirty ) updateTransform();

			_qPitch.setFromAxisAngle(transform.n11, transform.n21, transform.n31, angle );
			
			this.transform.calculateMultiply3x3( _qPitch.matrix , transform );

			_localRotationX += angle;
			
			_rotationDirty = true;
		}
	
		/**
		* Rotate the display object around about the vertical axis —an axis drawn from top to bottom.
		*
		* @param	angle	The angle to rotate.
		*/
		public function yaw( angle:Number ):void
		{
			angle = Papervision3D.useDEGREES? angle * toRADIANS : angle;

			if( _transformDirty ) updateTransform();

			_qYaw.setFromAxisAngle( transform.n12, transform.n22, transform.n32, angle );

			transform.calculateMultiply3x3( _qYaw.matrix, transform );
			
			_localRotationY += angle;
			
			_rotationDirty = true;
		}
		
		/**
		* Rotate the display object around the longitudinal axis —an axis drawn through the body of the vehicle from tail to nose in the normal direction of flight, or the direction the object is facing.
		*
		* @param	angle
		*/
		public function roll( angle:Number ):void
		{
			angle = Papervision3D.useDEGREES? angle * toRADIANS : angle;
	
			if( _transformDirty ) updateTransform();

			_qRoll.setFromAxisAngle( transform.n13, transform.n23, transform.n33, angle );
			
			transform.calculateMultiply3x3( _qRoll.matrix, transform );
			
			_localRotationZ += angle;
			
			_rotationDirty = true;
		}
	
		/**
		* Make the object look at a specific position.
		*
		* @param	targetObject	Object to look at.
		* @param	upAxis			The vertical axis of the universe. Normally the positive Y axis.
		*/
		public function lookAt( targetObject:DisplayObject3D, upAxis:Number3D=null ):void
		{	
			var parent:DisplayObject3D;
			
			// TODO:
			// For lookAt() to work *before* any render we need to calc #world, as
			// #world maybe not set (ie: project() wasn't called yet).
			// We need a better 'dirty' system.
			//
			// Also camera's are now handled differently due to current code.
			// Camera's should act as default DO3D's
			
			if(this is CameraObject3D)
			{
				_position.reset( this.x, this.y, this.z );
			}
			else
			{
				parent = this.parent as DisplayObject3D;
				if(parent)
					world.calculateMultiply(parent.world, transform);
				else
					world.copy(transform);
				_position.reset( world.n14, world.n24, world.n34 );
			}
			
			if(targetObject is CameraObject3D)
			{
				_lookatTarget.reset( targetObject.x, targetObject.y, targetObject.z );
			}
			else
			{
				parent = targetObject.parent as DisplayObject3D;
				if(parent)
					targetObject.world.calculateMultiply(parent.world, targetObject.transform);
				else
					targetObject.world.copy(targetObject.transform);
				_lookatTarget.reset( targetObject.world.n14, targetObject.world.n24, targetObject.world.n34 );
			}
				
			_zAxis.copyFrom(_lookatTarget); 
			_zAxis.minusEq(_position); 
			_zAxis.normalize();
	
			if( _zAxis.modulo > 0.1 )
			{
				_xAxis = Number3D.cross( _zAxis, upAxis || UP, _xAxis );
				_xAxis.normalize();
	
				_yAxis = Number3D.cross( _zAxis, _xAxis, _yAxis );
				_yAxis.normalize();
	
				var look  :Matrix3D = this.transform;
				// scale fix for lookAt()
				look.n11 =  _xAxis.x * _scaleX;
				look.n21 =  _xAxis.y * _scaleX;
				look.n31 =  _xAxis.z * _scaleX;
				
				look.n12 = -_yAxis.x * _scaleY;
				look.n22 = -_yAxis.y * _scaleY;
				look.n32 = -_yAxis.z * _scaleY;
				
				look.n13 =  _zAxis.x * _scaleZ;
				look.n23 =  _zAxis.y * _scaleZ;
				look.n33 =  _zAxis.z * _scaleZ;

				_localRotationX = _localRotationY = _localRotationZ = 0;
				
				this._transformDirty = false;
				this._rotationDirty = true;
			}
			else
			{
				PaperLogger.error("lookAt error");
			}
		}
	

		/**
		* Copies the position information (x, y and z coordinates) from another object or Matrix3D.
		*
		* @param	reference	A DisplayObject3D or Matrix3D object to copy the position from.
		*/
		public function copyPosition( reference:* ):void
		{
			var trans  :Matrix3D = this.transform;
			var matrix :Matrix3D = (reference is DisplayObject3D)? reference.transform : reference;
	
			trans.n14 = matrix.n14;
			trans.n24 = matrix.n24;
			trans.n34 = matrix.n34;
		}
	
		/**
		* Copies the transformation information (position, rotation and scale) from another object or Matrix3D.
		*
		* @param	reference	A DisplayObject3D or Matrix3D object to copy the position from.
		*/
		public function copyTransform( reference:* ):void
		{
			if(reference is DisplayObject3D)
			{
				var do3d:DisplayObject3D = DisplayObject3D(reference);
				if(do3d._transformDirty){
					do3d.updateTransform();
				}
			}
			
			var trans  :Matrix3D = this.transform;
			var matrix :Matrix3D = (reference is DisplayObject3D)? reference.transform : reference;
	
			trans.n11 = matrix.n11;		trans.n12 = matrix.n12;
			trans.n13 = matrix.n13;		trans.n14 = matrix.n14;
	
			trans.n21 = matrix.n21;		trans.n22 = matrix.n22;
			trans.n23 = matrix.n23;		trans.n24 = matrix.n24;
	
			trans.n31 = matrix.n31;		trans.n32 = matrix.n32;
			trans.n33 = matrix.n33;		trans.n34 = matrix.n34;
	
			this._transformDirty = false;
			this._rotationDirty  = true;
		}
	
		// ___________________________________________________________________________________________________
	
		/**
		* Returns a string value representing the three-dimensional position values of the display object instance.
		*
		* @return	A string.
		*/
		public override function toString(): String
		{
			return this.name + ': x:' + Math.round(this.x) + ' y:' + Math.round(this.y) + ' z:' + Math.round(this.z);
		}

		public function createViewportLayer(viewport:Viewport3D, recurse:Boolean = true):ViewportLayer
		{
			//Register it here under the correct viewport.
			var layer:ViewportLayer = viewport.getChildLayer(this, true);
		
			if(recurse)
				addChildrenToLayer(this, layer);
				
			return layer;		
			
		}
		
		public function addChildrenToLayer(do3d:DisplayObject3D, layer:ViewportLayer):void{
			for each(var obj:DisplayObject3D in do3d.children){
				layer.addDisplayObject3D(obj);
				obj.addChildrenToLayer(obj, layer);
			}
		}
		
		protected function setParentContainer(parent:DisplayObject3D, assign:Boolean = true):void{
			
			if(assign && parent != this)
				parentContainer = parent;
				
			for each(var do3d:DisplayObject3D in children){
				
				do3d.setParentContainer(parent, assign);
			}
		}	
		
		/**
		* [internal-use] Updates the transform Matrix3D with the current rotation and scale values.
		*/
		// TODO OPTIMIZE (HIGH)
		public function updateTransform():void
		{	
			_rot.setFromEuler(_rotationY, _rotationZ, _rotationX);

			// Rotation
			this.transform.copy3x3( _rot.matrix );
	
			// Scale
			_tempMatrix.reset(); 
			_tempMatrix.n11 = this._scaleX;
			_tempMatrix.n22 = this._scaleY;
			_tempMatrix.n33 = this._scaleZ;
			this.transform.calculateMultiply( this.transform, _tempMatrix );
			
			_transformDirty = false;
		}
		
		// Update rotation values
		private function updateRotation():void
		{			
			_tempScale.x = Papervision3D.usePERCENT ? _scaleX * 100 : _scaleX;
			_tempScale.y = Papervision3D.usePERCENT ? _scaleY * 100 : _scaleY;
			_tempScale.z = Papervision3D.usePERCENT ? _scaleZ * 100 : _scaleZ;
			
			_rotation = Matrix3D.matrix2euler(this.transform, _rotation, _tempScale);
			
			this._rotationX = _rotation.x * toRADIANS;
			this._rotationY = _rotation.y * toRADIANS;
			this._rotationZ = _rotation.z * toRADIANS;
	
			this._rotationDirty = false;
		}
		
		public function gotoTransform( reference:*, nextref:*, time:Number ):void
		{
			if(reference is DisplayObject3D)
			{
				var do3d:DisplayObject3D = DisplayObject3D(reference);
				if(do3d._transformDirty){
					do3d.updateTransform();
				}
			}
			
			var trans  :Matrix3D = this.transform;
			var matrix :Matrix3D = (reference is DisplayObject3D)? reference.transform : reference;
			var matrix2 :Matrix3D = (nextref is DisplayObject3D)? nextref.transform : nextref;
	
			/** NOT OPTIMIZED (lol) */
			
			trans.n11 = matrix.n11 + (matrix2.n11-matrix.n11)*time;		
			trans.n12 = matrix.n12 + (matrix2.n12-matrix.n12)*time;
			trans.n13 = matrix.n13 + (matrix2.n13-matrix.n13)*time;		
			trans.n14 = matrix.n14 + (matrix2.n14-matrix.n14)*time;
	
			trans.n21 = matrix.n21 + (matrix2.n21-matrix.n21)*time;		
			trans.n22 = matrix.n22 + (matrix2.n22-matrix.n22)*time;
			trans.n23 = matrix.n23 + (matrix2.n23-matrix.n23)*time;	
			trans.n24 = matrix.n24 + (matrix2.n24-matrix.n24)*time;
	
			trans.n31 = matrix.n31 + (matrix2.n31-matrix.n31)*time;		
			trans.n32 = matrix.n32 + (matrix2.n32-matrix.n32)*time;
			trans.n33 = matrix.n33 + (matrix2.n33-matrix.n33)*time;		
			trans.n34 = matrix.n34 + (matrix2.n34-matrix.n34)*time;
	
			this._transformDirty = false;
			this._rotationDirty  = true;
		}

	}
}