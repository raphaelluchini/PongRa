package utils
{
	
	
	public  class ObjectUtils
	{
		//PATTERN FILE PAT
		[Embed(source="assets/marker16Home.pat", mimeType="application/octet-stream")]
		protected static var embed0:Class;
		public static var PATTERN:String = new embed0();
		
		//CAMERA FILE PAT
		[Embed(source="assets/camera_para.dat", mimeType="application/octet-stream")]
		public static var embed1:Class;		
	}
}