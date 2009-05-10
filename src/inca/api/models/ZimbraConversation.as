package inca.api.models {
	
	import flash.events.EventDispatcher;
	
	import inca.api.Zimbra;
	import inca.api.errors.*;
	import inca.api.events.ZimbraEvent;
	import inca.core.inca_internal;
	
	use namespace inca_internal;

	public class ZimbraConversation extends EventDispatcher {
		
		private var $__id:int = -1;
		private var $__date:Date = new Date();
		private var $__subject:String = "";
		private var $__count:uint = 0;
		private var $__excerpt:String = "";
		private var $__messages:Array = new Array();
		private var $__connector:Zimbra = new Zimbra();	
		private var $__flags:uint = 0;	
		private var $__messageHashmap:Object = new Object();
		
		public function ZimbraConversation(){
		}
		
		public function get id():int{ return $__id; }
		public function get date():Date{ return $__date; }
		public function get subject():String{ return $__subject; }
		public function get count():uint{ return $__count; }
		public function get excerpt():String{ return $__excerpt; }
		public function get messages():Array{ return $__messages; }
		public function get connector():Zimbra{ return $__connector; }
		public function get flags():uint{ return $__flags; }
		
		inca_internal function set __id(value:int):void{ $__id = value; }
		inca_internal function set __date(value:Date):void{ $__date = value; }
		inca_internal function set __subject(value:String):void{ $__subject = value; }
		inca_internal function set __excerpt(value:String):void{ $__excerpt = value; }
		inca_internal function set __count(value:uint):void{ $__count = value; }
		inca_internal function set __flags(value:String):void{ setFlags(value); }
		
		public function set connector(value:Zimbra):void{ $__connector = value; }
		
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
		
		inca_internal function decode(data:Object):void{
			$__id = data.id;
			$__date = new Date(data.d);
			$__subject = data.su;
			$__count = data.n;
			$__excerpt = data.fr;
			setFlags((data.f || ""));
			for(var i:uint=0;i<data.m.length;i++) $__messageHashmap[data.m[i]] = i;
			$__messages = data.m;
		}
		
		private function setConversationProps(props:Object, eventType:String):void{
			if($__connector.loggedIn){
				var body:Object = {ConvActionRequest: 
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
		
		public function getMessage(id:uint):ZimbraMessage{
			if(!$__connector.loggedIn) throw new ZimbraError(ZimbraError.e10004, 10004);
			if($__messageHashmap[id] == null) throw new ZimbraError(ZimbraError.e10005, 10005);
			if(!($__messages[$__messageHashmap[id]] is ZimbraMessage)) $__messages[$__messageHashmap[id]] = $__connector.getMessage(id);
			return $__messages[$__messageHashmap[id]];
		}
		
		public function downloadMessages():void{
			if(!$__connector.loggedIn) throw new ZimbraError(ZimbraError.e10004, 10004);
			for(var i:uint=0;i<$__messages.length;i++){
				$__messages[i] = $__connector.getMessage($__messages[i].id);
			}
		}
		
		public function markAsRead():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10006, 10006);
			setConversationProps({id: $__id, op: "read"}, ZimbraEvent.CONVERSATION_MODIFIED);
		}	
		
		public function markAsUnread():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10006, 10006);
			setConversationProps({id: $__id, op: "!read"}, ZimbraEvent.CONVERSATION_MODIFIED);
		}	
		
		public function markAsSpam():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10006, 10006);
			setConversationProps({id: $__id, op: "spam"}, ZimbraEvent.CONVERSATION_MOVED);
		}
		
		public function markAsNotSpam():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10006, 10006);
			setConversationProps({id: $__id, op: "!spam"}, ZimbraEvent.CONVERSATION_MOVED);
		}
		
		public function move(folder:ZimbraFolder):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10006, 10006);
			if(folder.id == -1) throw new ZimbraError(ZimbraError.e10003, 10003);
			setConversationProps({id: $__id, op: "move", l: folder.id}, ZimbraEvent.CONVERSATION_MOVED);
		}
		
		public function remove():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setConversationProps({id: $__id, op: "move", l: 3}, ZimbraEvent.CONVERSATION_REMOVED);
		}
		
		public function flag():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setConversationProps({id: $__id, op: "flag"}, ZimbraEvent.CONVERSATION_MODIFIED);
		}
		
		public function unflag():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10007, 10007);
			setConversationProps({id: $__id, op: "!flag"}, ZimbraEvent.CONVERSATION_MODIFIED);
		}
		
		public function tag(tag:ZimbraTag):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10006, 10006);
			if(tag.id == -1) throw new ZimbraError(ZimbraError.e10002, 10002);
			setConversationProps({id: $__id, op: "tag", tag: tag.id}, ZimbraEvent.CONVERSATION_TAGGED);
		}
		
		public function untag(tag:ZimbraTag = null):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10006, 10006);
			if(tag.id == -1) throw new ZimbraError(ZimbraError.e10002, 10002);
			if(tag != null){
				setConversationProps({id: $__id, op: "!tag", tag: tag.id}, ZimbraEvent.CONVERSATION_TAGGED);
			}else{
				setConversationProps({id: $__id, op: "update", t: ""}, ZimbraEvent.CONVERSATION_TAGGED);
			}
		}
		
	}
	
}

/*
{"Header":{"context":{"_jsns":"urn:zimbra","userAgent":{"name":"ZimbraWebClient - FF3.0 (Mac)","version"
:"5.0.16_GA_2921.RHEL5_64"},"sessionId":{"_content":1233,"id":1233},"account":{"_content":"fernando@funciton
.com","by":"name"},"format":{"type":"js"},"authToken":"0_8bc7a20d0bc6a4be2311f9eeff9d8ea2b8c1079c_69
643d33363a61656663373530322d373861662d343833302d386561632d3862323363383061333762653b6578703d31333a313234313536323135313133383b747970653d363a7a696d6272613b"
}},"Body":{"ConvActionRequest":{"_jsns":"urn:zimbraMail","action":{"id":"84875","op":"!read"}}}}

{"Body":{"ConvActionResponse":{"action":{"op":"!read","id":"84875"},"_jsns":"urn:zimbraMail"}},"Header"
:{"context":{"sessionId":[{"_content":"1233","id":"1233"}],"change":{"token":127748},"notify":[{"modified"
:{"m":[{"f":"aru","id":"84881"},{"f":"su","id":"84874"},{"f":"au!","id":"84896"},{"f":"u","id":"84876"
},{"f":"au","id":"84895"},{"f":"ru!","id":"84873"},{"f":"sau","id":"84885"}],"c":[{"f":"saru!","id":"84875"
}],"folder":[{"i4ms":127748,"u":2,"i4next":84890,"n":1307,"s":135247912,"id":"5"},{"i4ms":127748,"u"
:5,"i4next":85119,"n":1203,"s":376616963,"id":"2"}]},"seq":1}],"_jsns":"urn:zimbra"}},"_jsns":"urn:zimbraSoap"
}

*/