package inca.api.models {
	
	public class ZimbraFlag {
		
		public static const UNREAD:uint				= 1;
		public static const FLAGGED:uint			= 2;
		public static const HAS_ATTACHMENT:uint		= 4;
		public static const SENT_BY_ME:uint			= 8;
		public static const REPLIED:uint			= 16;
		public static const FORWARDED:uint			= 32;
		public static const DRAFT:uint				= 64;
		public static const DELETED:uint			= 128;
		public static const NOTIFICATION_SENT:uint	= 256;
		public static const PRIORITY_HIGH:uint		= 512;
		public static const PRIORITY_NORMAL:uint	= 1024;
		public static const PRIORITY_LOW:uint		= 2048;

	}
	
}