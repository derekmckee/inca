package inca.api.models {
	
	import flash.events.EventDispatcher;
	
	import inca.api.Zimbra;
	import inca.api.errors.*;
	import inca.api.events.ZimbraEvent;
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraMessage extends EventDispatcher {
		
		private var $__id:int = -1;
		private var $__conversation_id:int = -1;
		private var $__folder:ZimbraFolder;
		private var $__subject:String = "";
		private var $__excerpt:String = "";
		private var $__content:String = "";
		private var $__contentType:String = "text/plain";
		private var $__size:uint = 0;
		private var $__date:Date = new Date();
		private var $__info:Array = new Array();
		private var $__flags:uint = 0;
		private var $__tags:Array = new Array();
		private var $__connector:Zimbra = new Zimbra();
		
		public function ZimbraMessage(){
		}
		
		public function get id():int{ return $__id; }
		public function get conversation_id():int{ return $__conversation_id; }
		public function get folder():ZimbraFolder{ return $__folder; }
		public function get subject():String{ return $__subject; }
		public function get excerpt():String{ return $__excerpt; }
		public function get content():String{ return $__content; }
		public function get contentType():String{ return $__contentType; }
		public function get size():uint{ return $__size; }
		public function get date():Date{ return $__date; }
		public function get info():Array{ return $__info; }
		public function get flags():uint{ return $__flags; }
		public function get tags():Array{ return $__tags; }
		public function get connector():Zimbra{ return $__connector; }
		
		inca_internal function set __id(value:uint):void{ $__id = value; }
		inca_internal function set __conversation_id(value:uint):void{ $__conversation_id = value; }
		inca_internal function set __folder(value:ZimbraFolder):void{ $__folder = value; }
		inca_internal function set __subject(value:String):void{ $__subject = value; }
		inca_internal function set __excerpt(value:String):void{ $__excerpt = value; }
		inca_internal function set __date(value:Date):void{ $__date = value; }
		inca_internal function set __size(value:uint):void{ $__size = value; }
		inca_internal function set __flags(value:String):void{ setFlags(value); }
		inca_internal function set __content(value:String):void{ $__content = value; }
		inca_internal function set __contentType(value:String):void{ $__contentType = value; }
		public function set connector(value:Zimbra):void{ $__connector = value; }
		inca_internal function addMessageInfo(value:ZimbraMessageInfo):void{ $__info.push(value); }
		
		private function setFlags(value:String):void{
			var res:uint = 0;
			if(value.indexOf("u") != -1) res = res | ZimbraFlag.UNREAD;
			if(value.indexOf("f") != -1) res = res | ZimbraFlag.FLAGGED;
			if(value.indexOf("a") != -1) res = res | ZimbraFlag.HAS_ATTACHMENT;
			if(value.indexOf("s") != -1) res = res | ZimbraFlag.SENT_BY_ME;
			if(value.indexOf("r") != -1) res = res | ZimbraFlag.REPLIED;
			if(value.indexOf("w") != -1) res = res | ZimbraFlag.FORWARDED;
			if(value.indexOf("d") != -1) res = res | ZimbraFlag.DRAFT;
			if(value.indexOf("x") != -1) res = res | ZimbraFlag.DELETED;
			if(value.indexOf("n") != -1) res = res | ZimbraFlag.NOTIFICATION_SENT;
			if(value.indexOf("!") != -1){
				res = res | ZimbraFlag.PRIORITY_HIGH;
			}else if(value.indexOf("?") != -1){
				res = res | ZimbraFlag.PRIORITY_LOW;
			}else{
				res = res | ZimbraFlag.PRIORITY_NORMAL;
			}
			$__flags = res;
		}
		
		inca_internal function setTags(value:String, tagsHashmap:Object):void{
			var res:Array = new Array();
			var tgs:Array = value.split(",");
			for(var i:uint=0;i<tgs.length;i++){
				res.push(tagsHashmap[tgs[i]]);
			}
			$__tags = res;
		}
		
		private function getMainMimePart(obj:Array):Object{
			var res:Object;
			for(var i:uint=0;i<obj.length;i++){
				if(obj[i].body != null && obj[i].body){
					res = obj[i];
					break;
				}
				if(obj[i].mp){
					var tmp:Object = arguments.callee(obj[i].mp);
					if(tmp != null){
						res = tmp;
						break;
					}
				}
			}
			return res;
		}
		
		inca_internal function decode(data:Object, folderHashmap:Object, tagsHashmap:Object):void{
			$__id = data.id;
			$__conversation_id = data.cid;
			$__folder = folderHashmap[data.l];
			$__subject = data.su;
			$__excerpt = data.fr;
			$__date = new Date(data.d);
			$__size = data.s;
			var mmp:Object = getMainMimePart(data.mp);
			if(mmp != null){
				$__content = mmp.content;
				$__contentType = mmp.ct;
			}
			setFlags((data.f || ""));
			setTags((data.t || ""), tagsHashmap);
			
			var zmInfo:ZimbraMessageInfo;
			for(var i:uint=0;i<data.e.length;i++){
				zmInfo = new ZimbraMessageInfo();
				zmInfo.inca_internal::decode(data.e[i]);
				
				$__info.push(zmInfo);
			}
		}
		
		private function setMessageProps(props:Object, eventType:String):void{
			if($__connector.loggedIn){
				var body:Object = {MsgActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: props
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, eventType, this);
			}else{
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function markAsRead():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setMessageProps({id: $__id, op: "read"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function markAsUnread():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setMessageProps({id: $__id, op: "!read"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function markAsSpam():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setMessageProps({id: $__id, op: "spam"}, ZimbraEvent.MESSAGE_MOVED);
		}
		
		public function markAsNotSpam():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setMessageProps({id: $__id, op: "!spam"}, ZimbraEvent.MESSAGE_MOVED);
		}
		
		public function move(folder:ZimbraFolder):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			if(folder.id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
			setMessageProps({id: $__id, op: "move", l: folder.id}, ZimbraEvent.MESSAGE_MOVED);
		}
		
		public function remove():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setMessageProps({id: $__id, op: "move", l: 3}, ZimbraEvent.MESSAGE_REMOVED);
		}
		
		public function flag():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setMessageProps({id: $__id, op: "flag"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function unflag():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setMessageProps({id: $__id, op: "!flag"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function tag(tag:ZimbraTag):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			if(tag.id == -1) throw new ZimbraError(ZimbraError.e10002, 10002);
			setMessageProps({id: $__id, op: "tag", tag: tag.id}, ZimbraEvent.MESSAGE_TAGGED);
		}
		
		public function untag(tag:ZimbraTag = null):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			if(tag.id == -1) throw new ZimbraError(ZimbraError.e10002, 10002);
			if(tag != null){
				setMessageProps({id: $__id, op: "!tag", tag: tag.id}, ZimbraEvent.MESSAGE_TAGGED);
			}else{
				setMessageProps({id: $__id, op: "update", t: ""}, ZimbraEvent.MESSAGE_TAGGED);
			}
		}

	}
	
}