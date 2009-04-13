package inca.api.models {
	
	import flash.events.EventDispatcher;
	
	import inca.api.Zimbra;
	import inca.api.events.ZimbraEvent;
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraTag extends EventDispatcher {
		
		public static const BLUE:uint 	= 1;
		public static const CYAN:uint 	= 2;
		public static const GREEN:uint 	= 3;
		public static const PURPLE:uint = 4;
		public static const RED:uint 	= 5;
		public static const YELLOW:uint = 6;
		public static const ORANGE:uint = 9;
		
		private var $__id:int = -1;
		private var $__color:uint;
		private var $__name:String;
		private var $__unreadCount:uint = 0;
		private var $__connector:Zimbra = new Zimbra();
		
		public function ZimbraTag(){
		}
		
		public function get id():int{ return $__id; }
		public function get color():uint{ return $__color; }
		public function get name():String{ return $__name; }
		public function get unreadCount():uint{ return $__unreadCount; }
		
		public function set color(value:uint):void{ if($__id == -1) $__color = value; }
		public function set name(value:String):void{ if($__id == -1) $__name = value; }
		
		public function set connector(value:Zimbra):void{ $__connector = value; }
		public function get connector():Zimbra{ return $__connector; }
		
		inca_internal function set __id(value:uint):void{ $__id = value; }
		inca_internal function set __unreadCount(value:uint):void{ $__unreadCount = value; }
		
		inca_internal function decode(data:Object):void{
			color = data.color || ZimbraTag.ORANGE;
			name = data.name;
			
			$__unreadCount = data.u || data.unreadCount;
			$__id = data.id;
		}
		
		public function create():void{
			if($__id != -1) throw new Error("Server Error. Tag is already on server.");
			if(!$__name || !$__name.length) throw new Error("Parameter Error. Need to specify all required fields");
			if($__connector.loggedIn){
				var body:Object = {CreateTagRequest: 
							{
								_jsns: "urn:zimbraMail",
								tag: {
									name: $__name,
									color: ($__color || ZimbraTag.ORANGE)
								}
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.TAG_CREATED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function rename(value:String):void{
			if($__id == -1) throw new Error("Server Error. Tag is not on server.");
			if($__connector.loggedIn){
				var body:Object = {TagActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "rename",
									id: $__id,
									name: value
								}
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.TAG_MODIFIED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function changeColor(value:uint):void{
			if($__id == -1) throw new Error("Server Error. Tag is not on server.");
			if($__connector.loggedIn){
				var body:Object = {TagActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "color",
									id: $__id,
									color: value
								}
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.TAG_MODIFIED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}
		
		public function remove():void{
			if($__id == -1) throw new Error("Server Error. Tag is not on server.");
			if($__connector.loggedIn){
				var body:Object = {TagActionRequest: 
							{
								_jsns: "urn:zimbraMail",
								action: {
									op: "delete",
									id: $__id	
								}
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.TAG_REMOVED, this);
			}else{
				throw new Error("Connection Error. You are not logged in.");
			}
		}

	}
	
}