package inca.api {
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;
	
	import inca.api.events.*;
	import inca.api.models.*;
	import inca.api.errors.*;
	import inca.core.inca_internal;
	import inca.net.DynamicURLLoader;
	import inca.serialization.json.JSON;
	import inca.utils.ObjectUtil;
	import inca.utils.StringUtil;
	
	use namespace inca_internal;

	public class Zimbra extends EventDispatcher	{
		
		// -->> Constants
		public static const LIST_TYPE_MESSAGE:String = "message";
		public static const LIST_TYPE_CONVERSATION:String = "conversation";
		public static const MESSAGE_FORMAT_HTML:String = "format_html";
		public static const MESSAGE_FORMAT_TEXT:String = "format_text";
		private const NoOpRequestTime:uint = 3 * 60 * 1000; // 3 minutes
		
		// -->> Vars
		private var $__connectionType:String = "http://";
		private var $__server:String = "";
		private var $__username:String = "";
		private var $__password:String = "";
		private var $__mailbox:Object = {folders: [], size: 0, tags: []};
		private var $__request:Object = {Header: {context: {_jsns: "urn:zimbra"}}};
		private var $__changeID:uint = 0;
		private var $__notificationID:uint = 0;
		private var $__folderHashmap:Object = new Object();
		private var $__tagHashmap:Object = new Object();
		private var $__loggedIn:Boolean = false;
		private var $__idle:Boolean = true;
		private var $__idleTimer:Timer;
		private var $__messageHashmap:Object = new Object();
		
		// -->> Constructor
		public function Zimbra():void{		
		}
		
		// -->> Getter/Setter
		public function set secureConnection(value:Boolean):void{ $__connectionType = (value) ? "https://": "http://"; }
		
		public function get secureConnection():Boolean{ return ($__connectionType == "https://"); }
		
		public function set username(value:String):void{ $__username = value; }
		
		public function get username():String{ return $__username; }
		
		public function set password(value:String):void{ $__password = value; }
		
		public function get password():String{ return $__password; }
		
		public function set server(value:String):void{
			if(StringUtil.beginsWith(value, "http://", true) || StringUtil.beginsWith(value, "https://", true)){
				throw new ZimbraError(ZimbraError.e10001, 10001);
			}
			if(StringUtil.endsWith(value, "/", true)) value = value.substring(0, value.length - 2);
			$__server = StringUtil.trim(value);
		}
		
		public function get server():String{ return $__server; }
		
		public function get folders():Array{ return $__mailbox.folders; }
		
		public function get tags():Array{ return $__mailbox.tags; }
		
		public function get size():uint{ return $__mailbox.size; }
		
		public function get loggedIn():Boolean{ return $__loggedIn; }
		
		public function get idle():Boolean{ return $__idle; }
		
		// -->> Public Methods
		public function getTag(id:uint):ZimbraTag{
			if($__tagHashmap[id] != null) return $__tagHashmap[id];
			throw new ZimbraError(ZimbraError.e10002, 10002);
		}
		
		public function getFolder(id:uint):ZimbraFolder{
			if($__folderHashmap[id] != null) return $__folderHashmap[id];
			throw new ZimbraError(ZimbraError.e10003, 10003);
		}
		
		public function login():void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = {AuthRequest: 
							{
								_jsns: "urn:zimbraAccount", 
								account: {by: "name", _content: $__username}, 
								password: $__password, 
								virtualHost: $__server
							 }
						};
			
			sendRequest(req, ZimbraEvent.LOGGED_IN);
		}
		
		public function search(query:String, returnType:String = Zimbra.LIST_TYPE_MESSAGE, limit:uint = 25, offset:uint = 0):void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = {SearchRequest: 
							{
								_jsns: "urn:zimbraMail", 
								sortBy: "dateDesc", 
								offset: offset, 
								limit: limit, 
								query: query, 
								types: returnType
							}
						};
						
			sendRequest(req, ZimbraSearchEvent.COMPLETE);
		}
		
		public function getMessage(id:uint, html:Boolean = false, markAsRead:Boolean = false):ZimbraMessage{
			var msg:ZimbraMessage = new ZimbraMessage();
			msg.inca_internal::__id = id;
			var body:Object = {GetMsgRequest:
							{
								_jsns: "urn:zimbraMail",
								m: {
									id: id,
									read: (markAsRead) ? 1: 0,
									html: (html) ? 1: 0
								}
							}
					};
			sendProxiedRequest(body, ZimbraEvent.MESSAGE_LOADED, msg);					
					
			return msg;
		}
		
		public function getConversation(id:int, html:Boolean = false):ZimbraConversation{
			var conv:ZimbraConversation = new ZimbraConversation();
			conv.inca_internal::__id = id;
			var body:Object = {GetConvRequest: {c:
							{
								id: id,
								html: (html) ? 1: 0
							},
							_jsns: "urn:zimbraMail"
						}
					};
			sendProxiedRequest(body, ZimbraEvent.CONVERSATION_LOADED, conv);
			
			return conv;
		}
		
		// -->> Private Methods
		private function noOpRequest():void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = {NoOpRequest: 
							{
								_jsns: "urn:zimbraMail"
							}
						};
			
			sendRequest(req, "zimbra_nooprequest");
		}
		
		private function $__noOpRequest(event:TimerEvent):void{
			noOpRequest();
			$__idle = true;
		}
		
		private function sendRequest(data:Object, callType:String, ref:* = null):void{
			if(!$__loggedIn && data.Body.AuthRequest == null) throw new ZimbraError(ZimbraError.e10004, 10004);

			if($__changeID) data.Header.context.change = {type: "new", token: $__changeID};
			if($__notificationID) data.Header.context.notify = {seq: $__notificationID};
			
			var uri:URLRequest = new URLRequest($__connectionType + $__server + "/service/soap/");
			uri.method = URLRequestMethod.POST;
			uri.data = JSON.encode(data);	
			var loader:DynamicURLLoader = new DynamicURLLoader();
			loader.callType = callType;
			if(ref) loader.ref = ref;
			loader.addEventListener(Event.COMPLETE, $__onRequestDone, false, 0, true);
			loader.load(uri);
			
			if(callType != "zimbra_nooprequest" && $__loggedIn){
				$__idle = false;
				$__idleTimer.reset();
				$__idleTimer.start();
			}
		}
		
		private function setFolders(container:Array, origFolders:Array):void{
			var fs:Array = origFolders;
			var folder:ZimbraFolder;
			for(var i:uint=0;i<fs.length;i++){
				if(fs[i].view != "message") continue;
				
				folder = new ZimbraFolder();
				folder.inca_internal::decode(fs[i], $__folderHashmap);
				
				container.push(folder);
				$__folderHashmap[folder.id] = folder;
				
				if(fs[i].folder) arguments.callee.apply(null, [container, fs[i].folder]);
			}
		}
		
		private function setParentFolders():void{
			for(var i:uint=0;i<$__mailbox.folders.length;i++){
				($__mailbox.folders[i] as ZimbraFolder).parentFolder = $__folderHashmap[($__mailbox.folders[i] as ZimbraFolder).parentFolder.id];
			}
		}
		
		private function setMailboxProps(props:Object):void{
			$__mailbox.size = props.mbx[0].s;
			
			setFolders($__mailbox.folders, props.folder);
			setParentFolders();
			
			if(props.tags.tag){
				var t:Array = new Array();
				var ts:Array = props.tags.tag;
				var tag:ZimbraTag;
				for(var i:uint=0;i<ts.length;i++){
					tag = new ZimbraTag();
					tag.connector = this;
					tag.inca_internal::decode(ts[i]);
					
					t.push(tag);
					$__tagHashmap[ts[i].id] = tag;
				}
				$__mailbox.tags = t;
			}
		}
		
		private function buildSearchResponse(sResponse:Object):ZimbraSearchResponse{
			var response:ZimbraSearchResponse = new ZimbraSearchResponse();
			response.inca_internal::__type = (sResponse.m) ? Zimbra.LIST_TYPE_MESSAGE: Zimbra.LIST_TYPE_CONVERSATION;
			if(sResponse.more) response.inca_internal::__more = sResponse.more;
			if(sResponse.offset) response.inca_internal::__offset = sResponse.offset;
			
			var msgs:Array = sResponse.m || sResponse.c || [];
			var collection:Array = [];
			var obj:Object;
			for(var i:uint=0;i<msgs.length;i++){
				obj = new Object();
				obj.id = msgs[i].id;
				if(msgs[i].cid) obj.cid = msgs[i].cid;
				obj.subject = msgs[i].su;
				obj.excerpt = msgs[i].fr;
				obj.flags = msgs[i].f || "";
				obj.date = new Date(msgs[i].d);
				obj.folder_id = $__folderHashmap[msgs[i].l];
				obj.size = msgs[i].s;
				obj.info = [];
				
				for(var ii:uint=0;ii<msgs[i].e.length;ii++){
					obj.info.push({name: msgs[i].e[ii].d, fullName: msgs[i].e[ii].p, email: msgs[i].e[ii].a});
				}
				
				collection.push(obj);
			}
			response.inca_internal::__collection = collection;
			return response;
		}
		
		private function $__parseNotification(base:Object, ret:Array, type:String):void{
			var l:uint;
			var i:uint;
			if(base.tag){
				l = base.tag.length;
				var tag:ZimbraTag;
				var tag_m:ZimbraTag;
				for(i=0;i<l;i++){
					tag = new ZimbraTag();
					tag_m = (type == "modified") ? $__tagHashmap[base.tag[i].id]: null;
					if(base.tag[i].color){
						tag.color = base.tag[i].color;
						if(tag_m) tag_m.color = tag.color;
					}
					if(base.tag[i].name){
						tag.name = base.tag[i].name;
						if(tag_m) tag_m.name = tag.name;
					}
					tag.inca_internal::__id = base.tag[i].id;
					if(base.tag[i].u){
						tag.inca_internal::__unreadCount = base.tag[i].u;
						if(tag_m) tag_m.inca_internal::__unreadCount = tag.unreadCount;
					}
					
					if(type == "created") $__tagHashmap[tag.id] = tag;
					ret.push(tag);
				}
			}
			if(base.folder){
				l = base.folder.length;
				var folder:ZimbraFolder;
				var folder_m:ZimbraFolder;
				for(i=0;i<l;i++){
					folder = new ZimbraFolder();
					folder_m = (type == "modified") ? $__folderHashmap[base.folder[i].id]: null;
					if(base.folder[i].name){
						folder.name = base.folder[i].name;
						if(folder_m) folder_m.name = folder.name;
					}
					if(base.folder[i].color){
						folder.color = base.folder[i].color;
						if(folder_m) folder_m.color = folder.color;
					}
					folder.inca_internal::__id = base.folder[i].id;
					if(base.folder[i].size){
						folder.inca_internal::__size = base.folder[i].size;
						if(folder_m) folder_m.inca_internal::__size = folder.size;
					}
					if(base.folder[i].n){
						folder.inca_internal::__count = base.folder[i].n;
						if(folder_m) folder_m.inca_internal::__count = folder.count;
					}
					if(base.folder[i].u){
						folder.inca_internal::__unreadCount = base.folder[i].u;
						if(folder_m) folder_m.inca_internal::__unreadCount = folder.unreadCount;
					}
					if(base.folder[i].l){
						folder.parentFolder = $__folderHashmap[base.folder[i].l];
						if(folder_m) folder_m.parentFolder = folder.parentFolder;
					}
					
					if(type == "created") $__folderHashmap[folder.id] = folder;
					ret.push(folder);
				}
			}
			if(base.m){
				l = base.m.length;
				var message:ZimbraMessage;
				var messageInfo:ZimbraMessageInfo;
				for(i=0;i<l;i++){
					message = new ZimbraMessage();
					message.inca_internal::__id = base.m[i].id;
					if(base.m[i].c) message.inca_internal::__conversation_id = base.m[i].c;
					if(base.m[i].su) message.inca_internal::__subject = base.m[i].su;
					if(base.m[i].fr) message.inca_internal::__excerpt = base.m[i].fr;
					if(base.m[i].d) message.inca_internal::__date = new Date(base.m[i].d);
					if(base.m[i].f) message.inca_internal::__flags = base.m[i].f || "";
					if(base.m[i].content) message.inca_internal::__content = base.m[i].content;
					if(base.m[i].ct) message.inca_internal::__contentType = base.m[i].ct;
					if(base.m[i].s) message.inca_internal::__size = base.m[i].s;
					
					if(base.m[i].e){
						for(var ii:uint=0;ii<base.m[i].e.length;ii++){
							messageInfo = new ZimbraMessageInfo();
							if(base.m[i].e[ii].d) messageInfo.inca_internal::__name = base.m[i].e[ii].d;
							if(base.m[i].e[ii].p) messageInfo.inca_internal::__fullName = base.m[i].e[ii].p;
							if(base.m[i].e[ii].a) messageInfo.inca_internal::__email = base.m[i].e[ii].a;
							
							message.inca_internal::addMessageInfo(messageInfo);
						}
					}
					
					if(type == "created") $__messageHashmap[message.id] = message;
					ret.push(message);
				}
			}
		}
		
		private function parseNotification(notification:Object):void{
			$__notificationID = Math.max($__notificationID, notification.seq);
			
			var created:Array = [];
			var modified:Array = [];
			var deleted:Array = [];			
			
			if(notification.deleted) deleted = notification.deleted.id.split(",");
			if(notification.modified) $__parseNotification(notification.modified, modified, "modified");
			if(notification.created) $__parseNotification(notification.created, created, "created");

        	dispatchEvent(new ZimbraNotifyEvent(ZimbraNotifyEvent.NOTIFY, created, modified, deleted));	
		}
		
		// -->> Namespaced		
		inca_internal function sendProxiedRequest(body:Object, eventType:String, ref:*):void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = body;
			
			trace ("==>", JSON.encode(req));

			sendRequest(req, eventType, ref);
		}
		
		// -->> Events
		private function $__onRequestDone(event:Event):void{
			var req:DynamicURLLoader = (event.target as DynamicURLLoader);
			req.removeEventListener(Event.COMPLETE, arguments.callee);
			
			var d:Object = JSON.decode(req.data);
			$__changeID = Math.max($__changeID, d.Header.context.change.token);
			if(d.Header.context.refresh != null) setMailboxProps(d.Header.context.refresh);
			if(d.Header.context.notify != null) parseNotification(d.Header.context.notify[0]);
			
			trace (req.data);
			
			var i:uint;			
			switch(req.callType){
				case ZimbraEvent.LOGGED_IN:
					$__request.Header.context.authToken = d.Body.AuthResponse.authToken;
					$__request.Header.context.sessionId = d.Body.AuthResponse.sessionId;
					$__loggedIn = true;
					if(!$__idleTimer){
						$__idleTimer = new Timer(NoOpRequestTime);
						$__idleTimer.addEventListener(TimerEvent.TIMER, $__noOpRequest, false, 0, true);
						$__idleTimer.start();
					}
					dispatchEvent(new ZimbraEvent(req.callType));
					break;
				case "zimbra_nooprequest":
					break;
				case ZimbraSearchEvent.COMPLETE:
					dispatchEvent(new ZimbraSearchEvent(ZimbraSearchEvent.COMPLETE, buildSearchResponse(d.Body.SearchResponse)));
					break;
				case ZimbraEvent.TAG_CREATED:
					(req.ref as ZimbraTag).inca_internal::decode($__tagHashmap[d.Body.CreateTagResponse.tag[0].id]);
					(req.ref as ZimbraTag).dispatchEvent(new ZimbraEvent(ZimbraEvent.TAG_CREATED));
					break;
				case ZimbraEvent.TAG_MODIFIED:
					(req.ref as ZimbraTag).inca_internal::__id = -1;
					(req.ref as ZimbraTag).inca_internal::decode($__tagHashmap[d.Body.TagActionResponse.action.id]);
					(req.ref as ZimbraTag).dispatchEvent(new ZimbraEvent(ZimbraEvent.TAG_MODIFIED));
					break;
				case ZimbraEvent.TAG_REMOVED:
					(req.ref as ZimbraTag).inca_internal::__id = -1;
					(req.ref as ZimbraTag).dispatchEvent(new ZimbraEvent(ZimbraEvent.TAG_REMOVED));
					break;
				case ZimbraEvent.FOLDER_CREATED:
					(req.ref as ZimbraFolder).inca_internal::decode($__folderHashmap[d.Body.CreateFolderResponse.folder[0].id], $__folderHashmap);
					setParentFolders();
					(req.ref as ZimbraFolder).dispatchEvent(new ZimbraEvent(ZimbraEvent.FOLDER_CREATED));
					break;
				case ZimbraEvent.FOLDER_TRASHED:
				case ZimbraEvent.FOLDER_EMPTIED:
				case ZimbraEvent.FOLDER_MOVED:
				case ZimbraEvent.FOLDER_MODIFIED:
					(req.ref as ZimbraFolder).inca_internal::__id = -1;
					(req.ref as ZimbraFolder).inca_internal::decode($__folderHashmap[d.Body.FolderActionResponse.action.id], $__folderHashmap);
					setParentFolders();
					(req.ref as ZimbraFolder).dispatchEvent(new ZimbraEvent(req.callType));
					break;
				case ZimbraEvent.FOLDER_REMOVED:
					(req.ref as ZimbraFolder).inca_internal::__id = -1;
					(req.ref as ZimbraFolder).dispatchEvent(new ZimbraEvent(ZimbraEvent.FOLDER_REMOVED));
					break;
				case ZimbraEvent.MESSAGE_LOADED:
					(req.ref as ZimbraMessage).inca_internal::decode(d.Body.GetMsgResponse.m[0], $__folderHashmap, $__tagHashmap);
					(req.ref as ZimbraMessage).dispatchEvent(new ZimbraEvent(ZimbraEvent.MESSAGE_LOADED));
					break;
				case ZimbraEvent.MESSAGE_MODIFIED:
				case ZimbraEvent.MESSAGE_MOVED:
				case ZimbraEvent.MESSAGE_TAGGED:
					for(i=0;i<d.Header.context.notify[0].modified.m.length;i++){
						if((req.ref as ZimbraMessage).id == d.Header.context.notify[0].modified.m[i].id){
							if(req.callType == ZimbraEvent.MESSAGE_MODIFIED) (req.ref as ZimbraMessage).inca_internal::__flags = d.Header.context.notify[0].modified.m[i].f || "";
							if(req.callType == ZimbraEvent.MESSAGE_MOVED) (req.ref as ZimbraMessage).inca_internal::__folder = $__folderHashmap[d.Header.context.notify[0].modified.m[i].l];
							if(req.callType == ZimbraEvent.MESSAGE_TAGGED) (req.ref as ZimbraMessage).inca_internal::setTags(d.Header.context.notify[0].modified.m[i].t, $__tagHashmap);
							(req.ref as ZimbraMessage).dispatchEvent(new ZimbraEvent(req.callType));
							break;
						}
					}
					break;
				case ZimbraEvent.MESSAGE_REMOVED:
					(req.ref as ZimbraMessage).inca_internal::__id = -1;
					(req.ref as ZimbraMessage).dispatchEvent(new ZimbraEvent(ZimbraEvent.MESSAGE_REMOVED));
					break;
				case ZimbraEvent.CONVERSATION_LOADED:
					(req.ref as ZimbraConversation).inca_internal::decode(d.GetConvResponse.c[0]);
					(req.ref as ZimbraConversation).dispatchEvent(new ZimbraEvent(ZimbraEvent.CONVERSATION_LOADED));
					break;
				case ZimbraEvent.CONVERSATION_MODIFIED:
				case ZimbraEvent.CONVERSATION_MOVED:
				case ZimbraEvent.CONVERSATION_TAGGED:
					for(i=0;i<d.Header.context.notify[0].modified.m.length;i++){
						try{
							if(req.callType == ZimbraEvent.CONVERSATION_MODIFIED) (req.ref as ZimbraConversation).getMessage(d.Header.context.notify[0].modified.m[i].id).inca_internal::__flags = d.Header.context.notify[0].modified.m[i].f || "";
							if(req.callType == ZimbraEvent.CONVERSATION_MOVED) (req.ref as ZimbraConversation).getMessage(d.Header.context.notify[0].modified.m[i].id).inca_internal::__folder = $__folderHashmap[d.Header.context.notify[0].modified.m[i].l];
							if(req.callType == ZimbraEvent.CONVERSATION_TAGGED) (req.ref as ZimbraConversation).getMessage(d.Header.context.notify[0].modified.m[i].id).inca_internal::setTags(d.Header.context.notify[0].modified.m[i].t, $__tagHashmap);
						}catch(e:Error){ 
							// ...
						}
					}
					for(i=0;i<d.Header.context.notify[0].modified.c.length;i++){
						if((req.ref as ZimbraConversation).id == d.Header.context.notify[0].modified.c[i].id){
							(req.ref as ZimbraConversation).inca_internal::__flags = d.Header.context.notify[0].modified.c[i].f || "";
							(req.ref as ZimbraConversation).dispatchEvent(new ZimbraEvent(req.callType));
						}
					}
					break;
				case ZimbraEvent.CONVERSATION_REMOVED:
					(req.ref as ZimbraConversation).inca_internal::__id = -1;
					(req.ref as ZimbraConversation).dispatchEvent(new ZimbraEvent(ZimbraEvent.CONVERSATION_REMOVED));
					break;
			}
		}
		
	}
	
}