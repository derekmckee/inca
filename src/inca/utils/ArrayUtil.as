package inca.utils {
	
	public class ArrayUtil	{
			
		public static function toObject(list:Array):Object{
			var res:Object = new Object();
			for(var i:uint=0;i<list.length;i++){
				if(list[i] != "") res[list[i]] = true;
			}
			return res;
		}

	}
	
}