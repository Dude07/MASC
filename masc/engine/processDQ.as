import masc.tags.DiscretOutput;

function processDQ(dq:DiscretOutput):void{
	//trace(dq.src);
	var obj:Object
	var errOld:int;
	var tag:String="";
	var value:int=0;

	dq.args=[]; dq.vals=[]; 
	errOld=dq.err; //Это чтоб не тащить значение ошибки, так как его не будет всё-равно
	obj=mainData[dq.src];
	tag="fiz";
	if (dq.tag.length>0) tag=dq.tag;
	if (obj) {} else {dq.noSub=checkSubscription(dq.src, dq.noSub); return;}
	
	//trace("Got data " +tag+"="+obj[tag],ai.type,obj[tag],ai.fiz,Number(obj[tag])==ai.fiz);

	if (obj[tag]!=undefined) {
		if (Boolean(obj[tag])==true) value=1 else value=0;
		if (value==dq.fiz) dq.pub=false; else {dq.fiz=value; trace("Дискретный выход №"+dq.num+". "+dq.name+". Значение сигнала = "+dq.fiz); dq.pub=true; dq.args=["fiz"]; dq.vals=[(dq.fiz).toString()]}
	} else {
		processError("У поставщика информации "+(dq.src).toString()+" нет параметра "+tag+" для DQ"+(dq.num).toString());
	}
	return;
	//Гду-то тут нужен обработчик состояний, а именно смены значения по фильтру. Можно использовать параметр time, но думаю в этом нет смысла, так как значения и так ленивые
	if (errOld!=dq.err) {dq.args.push("err"); dq.vals.push(dq.err);}
}