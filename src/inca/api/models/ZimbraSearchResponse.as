package inca.api.models {
	
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraSearchResponse {
		
		private var $__type:String = "";
		private var $__more:Boolean = false;
		private var $__offset:uint = 0;
		private var $__collection:Array = [];
		
		public function ZimbraSearchResponse(){
		}
		
		public function get type():String{ return $__type; }
		public function get more():Boolean{ return $__more; }
		public function get offset():uint{ return $__offset; }
		public function get collection():Array{ return $__collection; }
		
		inca_internal function set __type(value:String):void{ $__type = value; }
		inca_internal function set __more(value:Boolean):void{ $__more = value; }
		inca_internal function set __offset(value:uint):void{ $__offset = value; }
		inca_internal function set __collection(value:Array):void{ $__collection = value; }

	}
	
}