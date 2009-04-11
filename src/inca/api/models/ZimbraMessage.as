package inca.api.models {
	
	import flash.events.EventDispatcher;
	
	import inca.api.Zimbra;
	import inca.api.events.ZimbraEvent;
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraMessage extends EventDispatcher {
		
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
		
		private var $__id:int = -1;
		private var $__conversation_id:int = -1;
		private var $__subject:String = "";
		private var $__excerpt:String = "";
		private var $__content:String = "";
		private var $__contentType:String = "text/plain";
		private var $__size:uint = 0;
		private var $__date:Date = new Date();
		private var $__info:Array = new Array();
		private var $__flags:uint = 0;
		private var $__connector:Zimbra = new Zimbra();
		
		public function ZimbraMessage(){
		}
		
		public function get id():int{ return $__id; }
		public function get conversation_id():int{ return $__conversation_id; }
		public function get subject():String{ return $__subject; }
		public function get excerpt():String{ return $__excerpt; }
		public function get content():String{ return $__content; }
		public function get contentType():String{ return $__contentType; }
		public function get size():uint{ return $__size; }
		public function get date():Date{ return $__date; }
		public function get info():Array{ return $__info; }
		public function get flags():uint{ return $__flags; }
		
		inca_internal function set __id(value:int):void{ $__id = value; }
		inca_internal function set __conversation_id(value:int):void{ $__conversation_id = value; }
		inca_internal function set __subject(value:String):void{ $__subject = value; }
		inca_internal function set __excerpt(value:String):void{ $__excerpt = value; }
		inca_internal function set __content(value:String):void{ $__content = value; }
		inca_internal function set __contentType(value:String):void{ $__contentType = value; }
		inca_internal function set __size(value:uint):void{ $__size = value; }
		inca_internal function set __date(value:Date):void{ $__date = value; }
		inca_internal function set __flags(value:String):void{
			var res:uint = 0;
			if(value.indexOf("u") != -1) res = res | ZimbraMessage.UNREAD;
			if(value.indexOf("f") != -1) res = res | ZimbraMessage.FLAGGED;
			if(value.indexOf("a") != -1) res = res | ZimbraMessage.HAS_ATTACHMENT;
			if(value.indexOf("s") != -1) res = res | ZimbraMessage.SENT_BY_ME;
			if(value.indexOf("r") != -1) res = res | ZimbraMessage.REPLIED;
			if(value.indexOf("w") != -1) res = res | ZimbraMessage.FORWARDED;
			if(value.indexOf("d") != -1) res = res | ZimbraMessage.DRAFT;
			if(value.indexOf("x") != -1) res = res | ZimbraMessage.DELETED;
			if(value.indexOf("n") != -1) res = res | ZimbraMessage.NOTIFICATION_SENT;
			if(value.indexOf("!") != -1){
				res = res | ZimbraMessage.PRIORITY_HIGH;
			}else if(value.indexOf("?") != -1){
				res = res | ZimbraMessage.PRIORITY_LOW;
			}else{
				res = res | ZimbraMessage.PRIORITY_NORMAL;
			}
			$__flags = res;
		}
		
		inca_internal function addMessageInfo(value:ZimbraMessageInfo):void{ $__info.push(value); }	
		
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
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function set connector(value:Zimbra):void{ $__connector = value; }
		public function get connector():Zimbra{ return $__connector; }
		
		public function markMessageAsRead():void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			setMessageProps({id: $__id, op: "read"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function markMessageAsUnread():void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			setMessageProps({id: $__id, op: "!read"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function markMessageAsSpam():void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			setMessageProps({id: $__id, op: "spam"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function markMessageAsNotSpam():void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			setMessageProps({id: $__id, op: "!spam"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function moveMessage(folder:ZimbraFolder):void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			if(folder.id == -1) throw new Error("Server Error. Folder is not on the server");
			setMessageProps({id: $__id, op: "move", l: folder.id}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function removeMessage():void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			setMessageProps({id: $__id, op: "move", l: 3}, ZimbraEvent.MESSAGE_REMOVED);
		}
		
		public function flagMessage():void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			setMessageProps({id: $__id, op: "flag"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function unflagMessage():void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			setMessageProps({id: $__id, op: "!flag"}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function tagMessage(tag:ZimbraTag):void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			if(tag.id == -1) throw new Error("Server Error. Tag is not on the server");
			setMessageProps({id: $__id, op: "tag", tag: tag.id}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		public function untagMessage(tag:ZimbraTag):void{
			if($__id == -1) throw new Error("Server Error. Message is not on the server");
			if(tag.id == -1) throw new Error("Server Error. Tag is not on the server");
			setMessageProps({id: $__id, op: "!tag", tag: tag.id}, ZimbraEvent.MESSAGE_MODIFIED);
		}
		
		/*
		{"Header":{"context":{"_jsns":"urn:zimbra","userAgent":{"name":"ZimbraWebClient - FF3.0 (Mac)","version"
:"5.0.13_GA_2791.RHEL5_64"},"sessionId":{"_content":1300,"id":1300},"account":{"_content":"inca@funciton
.com","by":"name"},"format":{"type":"js"},"authToken":"0_3300680fc6c2d1f745446c273472b1c4d09b80c5_69
643d33363a30313232393937622d336336642d343562342d613438642d6232363461656434303939383b6578703d31333a313233353631343338303837343b747970653d363a7a696d6272613b"
}},"Body":{"SendMsgRequest":{"_jsns":"urn:zimbraMail","suid":1235441778805,"m":{"idnt":"0122997b-3c6d-45b4-a48d-b264aed40998"
,"f":"!","e":[{"t":"t","a":"fernando.florez@gmail.com","p":"fernando"},{"t":"c","a":"fernando.florez
@gmail.com","p":"fernando"},{"t":"b","a":"fernando.florez@gmail.com","p":"fernando"},{"t":"f","a":"inca
@funciton.com","p":"inca inca"}],"su":{"_content":"prueb"},"mp":[{"ct":"text/plain","content":{"_content"
:"mensajeeee"}}]}}}}
	SEND*/

	}
	
}