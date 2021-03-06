package inca.api.models {
	
	import flash.events.EventDispatcher;
	
	import inca.api.Zimbra;
	import inca.api.errors.*;
	import inca.api.events.ZimbraEvent;
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraFolder extends EventDispatcher {
		
		private var $__id:int = -1;
		private var $__name:String;
		private var $__size:uint;
		private var $__count:uint;
		private var $__color:uint = ZimbraColor.NONE;
		private var $__unreadCount:uint = 0;
		private var $__parentFolder:ZimbraFolder;
		private var $__url:String = "";
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
		public function get url():String{ return $__url; }
		
		public function set name(value:String):void{ if($__id == -1) $__name = value; }
		public function set parentFolder(value:ZimbraFolder):void{ if($__id == -1) $__parentFolder = value; }
		public function set color(value:uint):void{ if($__id == -1) $__color = value; }
		public function set url(value:String):void{ if($__id == -1) $__url = value; }
		
		public function set connector(value:Zimbra):void{ $__connector = value; }
		public function get connector():Zimbra{ return $__connector; }
		
		inca_internal function set __id(value:uint):void{ $__id = value; }
		inca_internal function set __size(value:uint):void{ $__size = value; }
		inca_internal function set __count(value:uint):void{ $__count = value; }
		inca_internal function set __unreadCount(value:uint):void{ $__unreadCount = value; }
		
		inca_internal function decode(data:Object, folderHashmap:Object):void{
			name = data.name;
			if(data.color != null) color = data.color;
			
			url = data.url || "";
			$__count = data.n || data.count;
			$__size = data.s || data.size;
			$__unreadCount = data.u || data.unreadCount || 0;
			
			parentFolder = (data.parentFolder != null && data.parentFolder.id != null) ? folderHashmap[data.parentFolder.id]: new ZimbraFolder();
			$__id = data.id;
		}
		
		public function create():void{
			if($__id != -1) throw new ZimbraError(ZimbraError.e10009, 10009);
			if(!$__name || !$__name.length) throw new ZimbraError(ZimbraError.e10008, 10008);
			if(!$__parentFolder) throw new ZimbraError(ZimbraError.e10008, 10008);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function rename(value:String):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function move(value:ZimbraFolder):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
			if(value.id == -1) throw new ZimbraError(ZimbraError.e10010, 10010);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function trash():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function changeColor(value:uint):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function markAsRead():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
			if(!$__parentFolder) throw new ZimbraError(ZimbraError.e10008, 10008);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function empty():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function remove():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}

	}
	
}