package inca.api.events {
	
	import flash.events.Event;
	
	import inca.api.models.ZimbraSearchResponse;

	public class ZimbraSearchEvent extends Event {
		
		public static const COMPLETE:String = "zimbra_search_complete";
		
		private var $__data:ZimbraSearchResponse;
		
		public function ZimbraSearchEvent(type:String, data:ZimbraSearchResponse){
			$__data = data;
			
			super(type);
		}
		
		public function get data():ZimbraSearchResponse{ return $__data; }
		
		override public function clone():Event{
			return new ZimbraSearchEvent(type, data);
		}
		
	}
	
}