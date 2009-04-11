package inca.api.events {
	
	import flash.events.Event;

	public class ZimbraEvent extends Event {
		
		public static const LOGGED_IN:String = "zimbra_logged_in";
		public static const TAG_CREATED:String = "zimbra_tag_created";
		public static const TAG_MODIFIED:String = "zimbra_tag_modified";
		public static const TAG_REMOVED:String = "zimbra_tag_removed";
		public static const FOLDER_CREATED:String = "zimbra_folder_created";
		public static const FOLDER_MODIFIED:String = "zimbra_folder_modified";
		public static const FOLDER_MOVED:String = "zimbra_folder_moved";
		public static const FOLDER_TRASHED:String = "zimbra_folder_trashed";
		public static const FOLDER_REMOVED:String = "zimbra_folder_removed";
		public static const FOLDER_EMPTIED:String = "zimbra_folder_emptied";
		public static const MESSAGE_LOADED:String = "zimbra_message_loaded";
		

		public static const CONVERSATION_LOADED:String = "conversation_loaded";
		public static const CONVERSATION_MESSAGES_LOADED:String = "conversation_messages_loaded";
		public static const MESSAGE_CREATED:String = "message_created";
		public static const MESSAGE_MODIFIED:String = "message_modified";
		public static const MESSAGE_REMOVED:String = "messages_removed";
		
		public function ZimbraEvent(type:String){
			super(type);
		}
		
		override public function clone():Event{
			return new ZimbraEvent(type);
		}
		
	}
	
}