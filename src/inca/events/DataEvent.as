package inca.events {
	
	import flash.events.Event;

	public class DataEvent extends Event {
		
		private var $__data:*;
		
		public function DataEvent(type:String, data:*){
			super(type);
			
			$__data = data;
		}
		
		public function get data():*{ return $__data; }
		
		override public function clone():Event{
			return new DataEvent(type, $__data);
		}
		
	}
	
}