package inca.utils {
	
	import flash.utils.ByteArray;
	import flash.net.registerClassAlias;
	import flash.utils.getQualifiedClassName;
	import flash.net.getClassByAlias;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	public class ObjectUtil	{
		
		public static function clone(object:*):*{
			
			var alias:String = getQualifiedClassName(object).split('::').join('.');
			var type:Class = getDefinitionByName(alias) as Class;
			
			traverse(object);
			
			var r:ByteArray = new ByteArray();
			r.writeObject(object);
			r.position = 0;
			var clone:*;
			try{
				clone = r.readObject();
				return clone as type;
			}catch (e:TypeError){	
				// trace (e);
			}
			return null;
		}
		
		private static function traverse(object:*):void{
			var alias:String = getQualifiedClassName(object).split('::').join('.');
			var type:Class = getDefinitionByName(alias) as Class;
			
			try{
				getClassByAlias(alias);
			}catch(e:ReferenceError){
				registerClassAlias(alias,type);			
			}
			
			var x:XML = describeType(object),
				childrens:XMLList = x.children(),
				l:int = childrens.length(),
				i:int = -1,
				xClass:XML;
			while(++i<l){
				xClass = childrens[i] as XML;
				
				registerAll(xClass);
				
				var childName:String = xClass.attribute("name");
				if ("variable" == xClass.name()){
					var childObj:* = object[childName];
					if (null != childObj){
						traverse(childObj);
					}
				}
			}
		}
		
		private static function registerAll(x:XML):void{
			var a:Array = ['type','declaredBy','returnType'],
				l:int = a.length,
				i:int = -1,
				raw:String,
				aSplit:Array,
				type:Class,
				alias:String;
			while(++i<l){
				raw = x.attribute(a[i] as String).toString();
				if(raw.indexOf('::') != -1){
					aSplit = raw.split('::');
					if(aSplit.length == 2){
						alias = aSplit.join('.');
						type = getDefinitionByName(alias) as Class;
						try{
							getClassByAlias(alias)
						}catch(e:ReferenceError){
							//trace ('Register --> '+alias+' as '+type);
							registerClassAlias(alias,type);
						}
					}
				}
			}
		}

	}
	
}