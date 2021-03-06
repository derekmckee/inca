package inca.api.models {
	
	import flash.events.EventDispatcher;
	
	import inca.api.Zimbra;
	import inca.api.errors.*;
	import inca.api.events.ZimbraEvent;
	import inca.core.inca_internal;
	
	use namespace inca_internal;
	
	public class ZimbraTag extends EventDispatcher {
		
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
			color = data.color || ZimbraColor.ORANGE;
			name = data.name;
			
			$__unreadCount = data.u || data.unreadCount;
			$__id = data.id;
		}
		
		public function create():void{
			if($__id != -1) throw new ZimbraError(ZimbraError.e10011, 10011);
			if(!$__name || !$__name.length) throw new ZimbraError(ZimbraError.e10008, 10008);
			if($__connector.loggedIn){
				var body:Object = {CreateTagRequest: 
							{
								_jsns: "urn:zimbraMail",
								tag: {
									name: $__name,
									color: ($__color || ZimbraColor.ORANGE)
								}
							}
						};
				$__connector.inca_internal::sendProxiedRequest(body, ZimbraEvent.TAG_CREATED, this);
			}else{
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function rename(value:String):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10002, 10002);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function changeColor(value:uint):void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10002, 10002);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}
		
		public function remove():void{
			if($__id == -1) throw new ZimbraError(ZimbraError.e10002, 10002);
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
				throw new ZimbraError(ZimbraError.e10004, 10004);
			}
		}

	}
	
}