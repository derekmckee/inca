package inca.api.models {
	
	import inca.api.Zimbra;
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class SearchResponse {
		
		private var $__type:String = Zimbra.LIST_TYPE_MESSAGE;
		private var $__messages:Array = new Array();
		private var $__more:int = -1;
		private var $__offset:uint = 0;
		
		public function SearchResponse(){
		}
		
		public function get type():String{ return $__type; }
		public function get messages():Array{ return $__messages; }
		public function get more():int{ return $__more; }
		public function get offset():uint{ return $__offset; }
		
		inca_internal function set __type(value:String):void{ $__type = value; }
		inca_internal function set __more(value:int):void{ $__more = value; }
		inca_internal function set __offset(value:uint):void{ $__offset = value; }
		
		inca_internal function addMessage(value:ZimbraMessage):void{ $__messages.push(value); }

	}
	
}