package inca.utils {
	
	public class StringUtil {
		
		public static function leftTrim(str:String):String{
			return str.replace(/^\s+/, '');
		}
		
		public static function rightTrim(str:String):String{
			return str.replace(/\s+$/, '');
		}
		
		public static function trim(str:String):String{
			return str.replace(/^\s+|\s+$/g, '');
		}
		
		public static function beginsWith(str:String, str2:String, removeWhite:Boolean=false):Boolean{
			if(removeWhite) str = StringUtil.leftTrim(str);
			return str.indexOf(str2) == 0;
		}
		
		public static function endsWith(str:String, str2:String, removeWhite:Boolean=false):Boolean{
			if(removeWhite) str = StringUtil.rightTrim(str);
			return str.indexOf(str2) == (str.length - str2.length);
		}

	}
	
}