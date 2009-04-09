package inca.api.events {
	
	import flash.events.Event;

	public class ZimbraNotifyEvent extends Event {
		
		public static const NOTIFY:String = "zimbra_notify_notify";
		
		private var $__created:Array = new Array();
		private var $__modified:Array = new Array();
		private var $__deleted:Array = new Array();
		
		public function ZimbraNotifyEvent(type:String, created:Array, modified:Array, deleted:Array){
			$__created = created;
			$__modified = modified;
			$__deleted = deleted;
			super(type);
		}
		
		public function get created():Array{ return $__created; }
		public function get modified():Array{ return $__modified; }
		public function get deleted():Array{ return $__deleted; }
		
		override public function clone():Event{
			return new ZimbraNotifyEvent(type, $__created, $__modified, $__deleted);
		}
		
	}
	
}