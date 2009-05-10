package inca.api.errors {
	
	public class ZimbraError extends Error {
		
		public static const e10001:String = "Server format error. Protocol should not be included.";
		public static const e10002:String = "Request error. Tag id not found on server.";
		public static const e10003:String = "Request error. Folder id not found on server.";
		public static const e10004:String = "Connection Error. You are not logged in.";
		public static const e10005:String = "Request error. Message id not found on this conversation.";
		public static const e10006:String = "Request Error. Conversation id not found on server.";
		public static const e10007:String = "Request Error. Message id not found on server.";
		public static const e10008:String = "Parameter Error. Need to specify all required fields.";
		public static const e10009:String = "Server Error. Folder is already on server.";
		public static const e10010:String = "Server Error. Parent folder is not on server.";
		public static const e10011:String = "Server Error. Tag is already on server.";
		
		public function ZimbraError(errorMsg:String = "", id:uint = 0){
			super(errorMsg, id);
		}

	}
	
}