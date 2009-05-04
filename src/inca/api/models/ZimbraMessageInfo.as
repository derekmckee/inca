package inca.api.models {
	
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraMessageInfo {
			
		public static const TYPE_FROM:uint 		= 1;
		public static const TYPE_TO:uint 		= 2;
		public static const TYPE_CC:uint 		= 4;
		public static const TYPE_BCC:uint		= 8;
		public static const TYPE_REPLY_TO:uint 	= 16;
		public static const TYPE_SENDER:uint 	= 32;
		
		private var $__name:String;
		private var $__fullName:String;
		private var $__email:String;
		private var $__type:uint = 0;
		
		public function ZimbraMessageInfo(){
		}
		
		public function get name():String{ return $__name; }
		public function get fullName():String{ return $__fullName; }
		public function get email():String{ return $__email; }
		public function get type():uint{ return $__type; } 
		
		inca_internal function set __name(value:String):void{ $__name = value; }
		inca_internal function set __fullName(value:String):void{ $__fullName = value; }
		inca_internal function set __email(value:String):void{ $__email = value; }
		inca_internal function set __type(value:String):void{
			var res:uint = 0;
			if(value.indexOf("f") != -1) res = res | ZimbraMessageInfo.TYPE_FROM;
			if(value.indexOf("t") != -1) res = res | ZimbraMessageInfo.TYPE_TO;
			if(value.indexOf("c") != -1) res = res | ZimbraMessageInfo.TYPE_CC;
			if(value.indexOf("b") != -1) res = res | ZimbraMessageInfo.TYPE_BCC;
			if(value.indexOf("r") != -1) res = res | ZimbraMessageInfo.TYPE_REPLY_TO;
			if(value.indexOf("s") != -1) res = res | ZimbraMessageInfo.TYPE_SENDER;
			$__type = res;
		}
		inca_internal function decode(data:Object):void{
			$__name = data.d;
			$__fullName = data.p;
			$__email = data.a;
			__type = data.t || "";
		}

	}
	
}