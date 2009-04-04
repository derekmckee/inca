package inca.events {
	
	import flash.events.Event;

	public class CronEvent extends Event {
		
		public static const TASK:String = "task";
		private var id:String = "";
		
		public function CronEvent(type:String, id:String=""){
			this.id = id;
			super(type);
		}
		
		override public function clone():Event{
			return new CronEvent(type, id);
		}
		
	}
	
}