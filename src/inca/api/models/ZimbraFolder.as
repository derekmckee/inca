package inca.api.models {
	
	import inca.api.Zimbra;
	import inca.api.events.ZimbraEvent;
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraFolder {
		
		public static const NONE:uint 	= 0;
		public static const BLUE:uint	= 1;
		public static const CYAN:uint	= 2;
		public static const GREEN:uint	= 3;
		public static const PURPLE:uint = 4;
		public static const RED:uint	= 5;
		public static const YELLOW:uint = 6;
		public static const PINK:uint	= 7;
		public static const GRAY:uint	= 8;
		public static const ORANGE:uint	= 9;
		
		private var $__id:int = -1;
		private var $__name:String;
		private var $__size:uint;
		private var $__count:uint;
		private var $__color:uint = NONE;
		private var $__unreadCount:uint = 0;
		private var $__parentFolder:ZimbraFolder;
		private var $__connector:Zimbra = new Zimbra();
		
		public function ZimbraFolder(){
		}
		
		public function get id():int{ return $__id; }
		public function get name():String{ return $__name; }
		public function get size():uint{ return $__size; }
		public function get count():uint{ return $__count; }
		public function get color():uint{ return $__color; }
		public function get unreadCount():uint{ return $__unreadCount; }
		public function get parentFolder():ZimbraFolder{ return $__parentFolder; }
		
		inca_internal function set __id(value:int):void{ $__id = value; }
		public function set name(value:String):void{ if($__id == -1) $__name = value; }
		public function set parentFolder(value:ZimbraFolder):void{ if($__id == -1) $__parentFolder = value; }
		public function set color(value:uint):void{ if($__id == -1) $__color = value; }
		inca_internal function set __size(value:uint):void{ $__size = value; }
		inca_internal function set __count(value:uint):void{ $__count = value; }
		inca_internal function set __unreadCount(value:uint):void{ $__unreadCount = value; }
		
		public function set connector(value:Zimbra):void{ $__connector = value; }
		public function get connector():Zimbra{ return $__connector; }
		
		public function create():void{
			if($__id != -1) throw new Error("Server Error. Folder is already on server.");
			if(!$__name || !$__name.length) throw new Error("Parameter Error. Need to specify all required fields");
			if(!$__parentFolder) throw new Error("Parameter Error. Need to specify all required fields");
			if($__connector.loggedIn){
				var body:Object = {CreateFolderRequest: 
							{
								_jsns: "urn:zimbraMail",
								folder: {
									l: $__parentFolder.id,
									name: $__name,
									view: "message"
								}
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_CREATED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function rename(value:String):void{
			if($__id == -1) throw new Error("Server Error. Folder is not on server.");
			if($__connector.loggedIn){
				var body:Object = {FolderActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "rename",
									id: $__id,
									name: value
								}
							}
						};
				$__name = value;
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_MODIFIED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function move(value:ZimbraFolder):void{
			if($__id == -1) throw new Error("Server Error. Folder is not on server.");
			if(value.id == -1) throw new Error("Server Error. Parent folder is not on server.");
			if($__connector.loggedIn){
				var body:Object = {FolderActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "move",
									id: $__id,
									l: value.id
								}
							}
						};
				$__parentFolder = value;
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_MOVED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function trash():void{
			if($__id == -1) throw new Error("Server Error. Folder is not on server.");
			if($__connector.loggedIn){
				var body:Object = {FolderActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "trash",
									id: $__id
								}
							}
						};
				
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_TRASHED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function changeColor(value:uint):void{
			if($__id == -1) throw new Error("Server Error. Folder is not on server.");
			if($__connector.loggedIn){
				var body:Object = {FolderActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "color",
									id: $__id,
									color: value
								}
							}
						};
				$__color = value;
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_MODIFIED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function markAsRead():void{
			if($__id == -1) throw new Error("Server Error. Folder is not on server.");
			if(!$__parentFolder) throw new Error("Parameter Error. Need to specify all required fields");
			if($__connector.loggedIn){
				var body:Object = {FolderActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "read",
									id: $__id,
									l: $__parentFolder.id
								}
							}
						};
				$__unreadCount = 0;
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_MODIFIED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function empty():void{
			if($__id == -1) throw new Error("Server Error. Folder is not on server.");
			if($__connector.loggedIn){
				var body:Object = {FolderActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "empty",
									id: $__id,
									recursive: true
								}
							}
						};
				$__unreadCount = 0;
				$__count = 0;
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_EMPTIED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function remove():void{
			if($__id == -1) throw new Error("Server Error. Folder is not on server.");
			if($__connector.loggedIn){
				var body:Object = {FolderActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "delete",
									id: $__id
								}
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.FOLDER_REMOVED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}

	}
	
}