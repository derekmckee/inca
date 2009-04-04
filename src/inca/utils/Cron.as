package inca.utils {
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import inca.events.CronEvent;
	
	public class Cron extends EventDispatcher {
		
		private var $__timer:Timer = new Timer(60000);
		private var $__running:Boolean = false;
		private var $__tasks:Array = new Array();
		private var $__tasksId:Object = new Object();
		
		public function Cron(){
			$__timer.addEventListener(TimerEvent.TIMER, checkTask);
		}
		
		public function start():void{
			if(!$__running){
				var secRes:uint = (60 - ((new Date()).getSeconds() + 1)) * 1000;
				var delay:Timer = new Timer(secRes, 1);
				delay.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void{ 
															checkTask((event.clone() as TimerEvent));
															$__timer.start();
														});
				delay.start();
				$__running = true;
			}
		}
		
		public function stop():void{
			$__running = false;
			$__timer.stop();
		}
		
		public function addTask(task:String):void{
			task = StringUtil.trim(task);
			if(!StringUtil.beginsWith(task, "#")){
				validateTask(task);
				$__tasksId[task.split(" ").pop()] = $__tasks.push(task);
			}
		}
		
		public function removeTask(id:String):void{
			if($__tasksId[id] == null) throw new Error("Task id " + id + " not found");
			$__tasks[$__tasksId[id]] = null;
			$__tasksId[id] = null;
			delete $__tasksId[id];
		}
		
		public function get running():Boolean{
			return $__running;
		}
		
		private function validateTask(str:String):void{
			if(str.split(" ").length != 6) throw new Error("Task format error");
			if($__tasks[str.split(" ").pop()] != null) throw new Error("Task id already exists");
		}
		
		private function $__transform(item:String):*{
			if(item.indexOf(",") != -1 && item.indexOf("/") == -1){
				return ArrayUtil.toObject(item.split(","));
			}else if(item.indexOf("/") != -1 && item.indexOf(",") == -1){
				var items:Array = new Array("0");
				for(var i:uint=0;i<(60 - uint(item.split("/")[1]));){
					i += uint(item.split("/")[1]);
					items.push(i);
				}
				return ArrayUtil.toObject(items);
			}else{
				return item;
			}
		}
		
		private function $__check(item:*, index:int, array:Array):void{
			var date:Date = new Date();
			var pieces:Array = item.split(" ");
			var mins:* = $__transform(pieces.shift());
			var hours:* = $__transform(pieces.shift());
			var days:* = $__transform(pieces.shift());
			var months:* = $__transform(pieces.shift());
			var weekDay:* = $__transform(pieces.shift());
			var id:String = pieces.shift();
			var dispatch:Boolean = (mins is String) ? (date.getMinutes().toString() == mins || mins == "*"): ((date.getMinutes() + 1).toString() in mins);
			dispatch = dispatch && ((hours is String) ? (date.getHours().toString() == hours || hours == "*"): ((date.getHours() + 1).toString() in hours));
			dispatch = dispatch && ((days is String) ? (date.getDate().toString() == days || days == "*"): ((date.getDate() + 1).toString() in days));
			dispatch = dispatch && ((months is String) ? ((date.getMonth() + 1).toString() == months || months == "*"): ((date.getMonth() + 2).toString() in months));
			dispatch = dispatch && ((weekDay is String) ? (date.getDay().toString() == weekDay || weekDay == "*"): ((date.getDay() + 1).toString() in weekDay));
			
			dispatchEvent(new CronEvent(CronEvent.TASK, id));
		}
		
		private function checkTask(event:TimerEvent):void{
			$__tasks.forEach($__check);
		}

	}
	
}