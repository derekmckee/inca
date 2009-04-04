package inca.api {
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;
	
	import inca.api.events.*;
	import inca.api.models.*;
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
				throw new Error("Server format error. Protocol should not be included");
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
						
			sendRequest(req, ZimbraEvent.SEARCH);
		}
		
		public function getMessage(id:int, read:Boolean = true, html:Boolean = false):void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = {GetMsgRequest:
							{
								_jsns: "urn:zimbraMail",
								m: {
									id: id,
									read: (read) ? 1: 0,
									html: (html) ? 1: 0
								}
							}
					};
			
			sendRequest(req, ZimbraEvent.MESSAGE_LOADED);
		}
		
		public function getConversation(cid:int, fid:int, read:Boolean = true, html:Boolean = false):void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = {SearchConvRequest:
							{
								_jsns: "urn:zimbraMail",
								sortBy: "dateDesc",
								cid: cid,
								read: (read) ? 1: 0,
								fetch: fid,
								html: (html) ? 1: 0
							}
					};
			
			sendRequest(req, ZimbraEvent.CONVERSATION_LOADED);
		}
		
		public function getMessagesFromConversation(cid:int, limit:uint = 25, offset:uint = 0):void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = {SearchConvRequest:
							{
								_jsns: "urn:zimbraMail",
								sortBy: "dateDesc",
								offset: offset,
								limit: limit,
								cid: cid
							}
						}
			
			sendRequest(req, ZimbraEvent.CONVERSATION_MESSAGES_LOADED);
		}
		
		// -->> Private Methods
		private function noOpRequest():void{
			var req:Object = ObjectUtil.clone($__request);
			req.Body = {NoOpRequest: 
							{
								_jsns: "urn:zimbraMail"
							}
						};
			
			sendRequest(req, "nooprequest");
		}
		
		private function $__noOpRequest(event:TimerEvent):void{
			noOpRequest();
			$__idle = true;
		}
		
		private function sendRequest(data:Object, callType:String, ref:* = null):void{
			if(!$__loggedIn && data.Body.AuthRequest == null) throw new Error("Connection Error. You are not logged in.");

			if($__changeID) data.Header.context.change = {type: "new", token: $__changeID};
			if($__notificationID) data.Header.context.notify = {seq: $__notificationID};
			
			var uri:URLRequest = new URLRequest($__connectionType + $__server + "/service/soap/");
			uri.method = URLRequestMethod.POST;
			uri.data = JSON.encode(data);	
			var loader:DynamicURLLoader = new DynamicURLLoader();
			loader.callType = callType;
			if(ref) loader.ref = ref;
			loader.addEventListener(Event.COMPLETE, $__onRequestDone);
			loader.load(uri);
			$__idle = false;
			
			if(callType != "nooprequest"){
				$__idleTimer.reset();
				$__idleTimer.start();
			}
		}
		
		private function setTagProps(instance:ZimbraTag, data:Object):void{
			instance.connector = this;
			instance.color = data.color || ZimbraTag.ORANGE;
			instance.name = data.name;
			instance.inca_internal::__id = data.id;
			if(data.u) instance.inca_internal::__unreadCount = data.u;
		}
		
		private function setParentFolders():void{
			for(var i:uint=0;i<$__mailbox.folders.length;i++){
				if((($__mailbox.folders[i] as ZimbraFolder).parentFolder as ZimbraFolder).name) continue;
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
					setTagProps(tag, ts[i]);
					
					t.push(tag);
					$__tagHashmap[ts[i].id] = tag;
				}
				$__mailbox.tags = t;
			}
		}
		
		private function setFolderProps(instance:ZimbraFolder, data:Object):void{
			instance.name = data.name;
			instance.connector = this;
			instance.inca_internal::__count = data.n;
			instance.inca_internal::__size = data.s;
			
			instance.inca_internal::__unreadCount = data.u || 0;
			if(data.color != null) instance.color = data.color;
			instance.parentFolder = new ZimbraFolder();
			instance.parentFolder.inca_internal::__id = data.l;
			
			instance.inca_internal::__id = data.id;
		}
		
		private function setFolders(container:Array, origFolders:Array):void{
			var fs:Array = origFolders;
			var folder:ZimbraFolder;
			for(var i:uint=0;i<fs.length;i++){
				if(fs[i].view != "message" && fs[i].view != null) continue;
				
				folder = new ZimbraFolder();
				setFolderProps(folder, fs[i]);
				
				container.push(folder);
				$__folderHashmap[folder.id] = folder;
				
				if(fs[i].folder) arguments.callee.apply(null, [container, fs[i].folder]);
			}
		}
		
		private function setMessageProps(instance:ZimbraMessage, data:Object):void{
			instance.connector = this;
			instance.inca_internal::__id = data.id;
			if(data.m[0].cid) instance.inca_internal::__conversation_id = data.m[0].cid;
			
			instance.inca_internal::__subject = data.su;
			instance.inca_internal::__excerpt = data.fr;
			instance.inca_internal::__date = new Date(data.d);
			if(data.mp){
				instance.inca_internal::__content = data.mp[0].content;
				instance.inca_internal::__contentType = data.mp[0].ct;
				instance.inca_internal::__size = data.mp[0].s;
			}
			
			setMessageFlags(instance, (data.f || ""));
			
			var messageInfo:ZimbraMessageInfo;
			for(var i:uint=0;i<data.e.length;i++){
				messageInfo = new ZimbraMessageInfo();
				messageInfo.inca_internal::__name = data.e[i].d;
				messageInfo.inca_internal::__fullName = data.e[i].p;
				messageInfo.inca_internal::__email = data.e[i].a;
				
				instance.inca_internal::addMessageInfo(messageInfo);
			}
		}
		
		private function setMessageFlags(message:ZimbraMessage, flags:String):void{
			if(flags.indexOf("u") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.UNREAD;
			if(flags.indexOf("f") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.FLAGGED;
			if(flags.indexOf("a") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.HAS_ATTACHMENT;
			if(flags.indexOf("s") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.SENT_BY_ME;
			if(flags.indexOf("r") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.REPLIED;
			if(flags.indexOf("w") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.FORWARDED;
			if(flags.indexOf("d") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.DRAFT;
			if(flags.indexOf("x") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.DELETED;
			if(flags.indexOf("n") != -1) message.inca_internal::__flags = message.flags | ZimbraMessage.NOTIFICATION_SENT;
			if(flags.indexOf("!") != -1){
				message.inca_internal::__flags = message.flags | ZimbraMessage.PRIORITY_HIGH;
			}else if(flags.indexOf("?") != -1){
				message.inca_internal::__flags = message.flags | ZimbraMessage.PRIORITY_LOW;
			}else{
				message.inca_internal::__flags = message.flags | ZimbraMessage.PRIORITY_NORMAL;
			}
		}

		private function parseSearchResponse(searchResponse:Object):SearchResponse{
			var response:SearchResponse = new SearchResponse();
			response.inca_internal::__type = (searchResponse.m) ? Zimbra.LIST_TYPE_MESSAGE: Zimbra.LIST_TYPE_CONVERSATION;
			if(searchResponse.more) response.inca_internal::__more = searchResponse.more;
			if(searchResponse.offset) response.inca_internal::__offset = searchResponse.offset;
			var msgs:Array = searchResponse.m || searchResponse.c || [];
			var message:ZimbraMessage;
			var messageInfo:ZimbraMessageInfo;
			for(var i:uint=0;i<msgs.length;i++){
				message = new ZimbraMessage();
				setMessageProps(message, msgs[i]);
				
				response.inca_internal::addMessage(message);
			}
			
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
					
					if(type == "created") $__tagHashmap[tag.id] = tag;
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
					if(base.m[i].f) setMessageFlags(message, (base.m[i].f || ""));
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

        	dispatchEvent(new ZimbraNotifyEvent(ZimbraEvent.NOTIFY, created, modified, deleted));	
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
			
			trace (req.data);
			var d:* = JSON.decode(req.data);
			$__changeID = Math.max($__changeID, d.Header.context.change.token);
			if(d.Header.context.refresh != null) setMailboxProps(d.Header.context.refresh);
			if(d.Header.context.notify != null) parseNotification(d.Header.context.notify[0]);
			
			var sResponse:SearchResponse;
			switch(req.callType){
				case ZimbraEvent.LOGGED_IN:
					$__request.Header.context.authToken = d.Body.AuthResponse.authToken;
					$__request.Header.context.sessionId = d.Body.AuthResponse.sessionId;
					$__loggedIn = true;
					if(!$__idleTimer){
						$__idleTimer = new Timer(NoOpRequestTime);
						$__idleTimer.addEventListener(TimerEvent.TIMER, $__noOpRequest);
						$__idleTimer.start();
					}
					dispatchEvent(new ZimbraEvent(req.callType));
					break;
				case ZimbraEvent.CONVERSATION_MESSAGES_LOADED:
				case ZimbraEvent.CONVERSATION_LOADED:
					sResponse = parseSearchResponse(d.Body.SearchConvResponse);
					dispatchEvent(new ZimbraEvent(req.callType, sResponse));
					break;
				case ZimbraEvent.SEARCH:
					sResponse = parseSearchResponse(d.Body.SearchResponse);
					dispatchEvent(new ZimbraEvent(req.callType, sResponse));
					break;
				case ZimbraEvent.MESSAGE_LOADED:
					sResponse = parseSearchResponse(d.Body.GetMsgResponse);
					dispatchEvent(new ZimbraEvent(req.callType, sResponse));
					break;
				case "nooprequest":
					break;
				case ZimbraEvent.TAG_CREATED:
					var tag:ZimbraTag = (req.ref as ZimbraTag);
					var tagBody:Object = d.Body.CreatetagResponse.tag[0];
					setTagProps(tag, $__tagHashmap[tagBody.id]);
					break;
				case ZimbraEvent.FOLDER_CREATED:
					var folder:ZimbraFolder = (req.ref as ZimbraFolder);
					var folderBody:Object = d.Body.CreateFolderResponse.folder[0];
					setFolderProps(folder, $__folderHashmap[folderBody.id]);
					setParentFolders();
					break;
			}
		}
		
	}
	
}