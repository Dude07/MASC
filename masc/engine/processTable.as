function processTable(num:int,val:Number):Number{
	var ret:Number=0; var obj0,obj1:Object;
	if (num>tables.length) {processError("Номер таблицы "+num+" на найден в проекте."); return 0;}
	var table:Array = tables[num];
	obj0=table[0];
	obj1=table[table.length-1];
	//trace("Выборка задания по тaблице №"+num,table.length,obj0.ins,obj1.ins);

	if (obj0["ins"]>obj1["ins"]){
		//trace("Таблица нисходящая");
		if (val>=obj0["ins"]) { return obj0["out"]};  //trace("За пределами верхней границы. Возвращаю "+obj0["out"]);
		if (val<=obj1["ins"]) { return obj1["out"]};  //trace("За пределами нижней границы. Возвращаю "+obj0["out"]);
		
		for (var i:int=0; i<table.length-1; i++){
			obj0=table[i];
			obj1=table[i+1];
			//trace(obj1["ins"],val,obj0["ins"],(Number(val) > Number(obj1["ins"]) && Number(val) <= Number(obj0["ins"])));
			if (val >= obj1["ins"] && val < obj0["ins"]){
				ret=obj1["out"]-(obj1["out"]-obj0["out"])*(val-Math.floor(val));  
				//trace("Recalculating table "+num+". In val="+val+"range="+obj0["ins"],obj1["ins"]+". Got value "+ret);
				break;
			}
		}
	} else {
		//trace("Таблица восходящая");
		if (val<=obj0["ins"]) return obj0["out"];
		if (val>=obj1["ins"]) return obj1["out"];
		
		for ( i=0; i<table.length-1; i++){
			obj0=table[i];
			obj1=table[i+1];
			//trace(obj0["ins"],val,obj1["ins"],(Number(val) > Number(obj0["ins"]) && Number(val) <= Number(obj1["ins"])));
			if (val > obj0["ins"] && val <= obj1["ins"]){
				ret=obj1["out"]-(obj1["out"]-obj0["out"])*(val-Math.floor(val));  
				//trace("Recalculating table "+num+". In val="+val+"range="+obj0["ins"],obj1["ins"]+". Got value "+ret);
				break;
			}
		}
		
	}
	return ret;
}