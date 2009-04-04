package inca.api.models {
	
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraMessageInfo {
		
		private var $__name:String;
		private var $__fullName:String;
		private var $__email:String;
		
		public function ZimbraMessageInfo(){
		}
		
		public function get name():String{ return $__name; }
		public function get fullName():String{ return $__fullName; }
		public function get email():String{ return $__email; }
		
		inca_internal function set __name(value:String):void{ $__name = value; }
		inca_internal function set __fullName(value:String):void{ $__fullName = value; }
		inca_internal function set __email(value:String):void{ $__email = value; }

	}
	
}