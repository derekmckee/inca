package inca.net {
	
	import flash.events.Event;
	import flash.net.NetConnection;
	
	import inca.events.DataEvent;

	public class NetStream extends flash.net.NetStream {
		
		public static const METADATA:String = "metadata";
		public static const XMP_DATA:String = "xmp_data";
		public static const CUE_POINT:String = "cue_point";
		public static const IMAGE_DATA:String = "image_data";
		public static const TEXT_DATA:String = "text_data";
		public static const DRM_CONTENT:String = "drm_content";
		public static const PLAY_STATUS:String = "play_status";
		
		public function NetStream(connection:NetConnection, peerID:String=CONNECT_TO_FMS){
			super(connection, peerID);
			
			client = {
				onXMPData: function(info:Object):void{
					dispatchEvent(new DataEvent(XMP_DATA, info));
				},
				onMetadata: function(info:Object):void{
					dispatchEvent(new DataEvent(METADATA, info));
				},
				onCuePoint: function(info:Object):void{
					dispatchEvent(new DataEvent(CUE_POINT, info));
				},
				onImageData: function(info:Object):void{
					dispatchEvent(new DataEvent(IMAGE_DATA, info));
				},
				onTextData: function(info:Object):void{
					dispatchEvent(new DataEvent(TEXT_DATA, info));
				},
				onDRMContentData: function(info:Object):void{
					dispatchEvent(new DataEvent(DRM_CONTENT, info));
				},
				onPlayStatus: function(info:Object):void{
					dispatchEvent(new DataEvent(PLAY_STATUS, info));
				}
			};
		}
		
	}
	
}