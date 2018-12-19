import masc.tags.Kotel;
import masc.tags.Kotelnaya;
var needPower,indxK:int;

function processKotelnaya(kotelnaya:Kotelnaya):void {
	//Тут надо понять как работать с котельной и составить алгоритм.
	//По каждому котлу можно работать отдельно - следующий цикл, но надо чтоб алгоритм как-то понимал что происходит.
	//kotelnaya.SP - физ значение на подаче
	//kotelnaya.DT - физ значение улицы
	//Дальше надо по таблице провести расчёт задания и записать его в SP (перезаписав последнее)
	//trace("------------------Processing kotelnaya-----------------");
	
	//var pair:Object=kotelnaya.table[kotelnaya.table.length-1];
	//kotelnaya.
	//if (kotelnaya.DT<kotelnaya.table[0].DT){
	//	pair=kotelnaya.table[0];
	//	SP=pair.SP;
//	} else if (kotelnaya.DT>pair.DT){
	//	SP=pair.SP
//	} else {
	//	for each(pair in kotelnaya.table){
	//		trace(pare.DT,pare.SP);
	//	}
	//}
	
	kotelnaya.timeWait=60; //Hello
	if (kotelnaya.A) {	
		kotelnaya.t++; 
		//Усредняем Т за заданное время
	    if (kotelnaya.timeWait > 0) {
			kotelnaya.fiz_f=(kotelnaya.timeWait*kotelnaya.fiz_f+kotelnaya.fiz)/(kotelnaya.timeWait+1);
		} else kotelnaya.fiz_f=kotelnaya.fiz;	
	
		//определение мощности необходимой для поддержание Т от -2 до +2 0-ничего делать не надо +-1 надо добавить/отнять(смотрим на Т)
		kotelnaya.power=0;
		kotelnaya.power=-1*(kotelnaya.fiz-kotelnaya.SP)/kotelnaya.delta;
		if (kotelnaya.power>2) kotelnaya.power=2;
		if (kotelnaya.power<-2) kotelnaya.power=-2;
		
		// Каждую минуту(примерно) определяем что делать
		if (kotelnaya.t>=kotelnaya.timeWait) { 
			kotelnaya.t=0;
		// Определяем ростет температура или нет ли почти не меняется
			kotelnaya.T_inc=0;
			if (kotelnaya.fiz_f>(kotelnaya.fiz_f_old+0.1))  kotelnaya.T_inc=1;
			if (kotelnaya.fiz_f>(kotelnaya.fiz_f_old+1))  kotelnaya.T_inc=2;
			if (kotelnaya.fiz_f<(kotelnaya.fiz_f_old-0.1))  kotelnaya.T_inc=-1;
			if (kotelnaya.fiz_f<(kotelnaya.fiz_f_old-1))  kotelnaya.T_inc=-2;
		//Стартуем считать заново рост/падение Т
			kotelnaya.fiz_f_old=kotelnaya.fiz;
			kotelnaya.fiz_f=kotelnaya.fiz;
		//Определяем надо добавлять или отнимать газ
			needPower=0;
			if (kotelnaya.power=1 && kotelnaya.T_inc!=1) needPower=1; 	//Если надо добавить немного газу и Т не растет то добавляем
			if (kotelnaya.power=-1 && kotelnaya.T_inc!=-1) needPower=-1;  //Если надо убрать немного газу и Т не падает то убираем
			if (kotelnaya.power=2 && kotelnaya.T_inc!=2) needPower=1;		// Если надо добавить много газу и Т растет медленно
			if (kotelnaya.power=-2 && kotelnaya.T_inc!=-2) needPower=-1;	// Если надо добавить много газу и Т растет медленно
			
		//Выбор котла для работы
			//Если надо добавить газу
			indxK=-1;
			if (needPower=1) {
				// Ищем котел с одной работающей горелкой для запуска второй
				for (var i:int = 0;i < kotelnaya.Kotli.length;i++) {
					if (kotelnaya.Kotli[i].A=1 && kotelnaya.Kotli[i].isOn && kotelnaya.Kotli[i].errFlame0=0 && kotelnaya.Kotli[i].errFlame1=0 && kotelnaya.Kotli[i].blocked=0 && kotelnaya.Kotli[i].isFlame0=1 && kotelnaya.Kotli[i].errFlame1=0) { 
						indxK=i; kotelnaya.Kotli[i].gor1=1;
					}
				}
				// если не нашли работающий котел с одной горекой то запускаем следующий свободный котел
				if (indxK=-1) {
					if (kotelnaya.Kotli[i].A=1 && kotelnaya.Kotli[i].isOn && kotelnaya.Kotli[i].errFlame0=0 && kotelnaya.Kotli[i].errFlame1=0 && kotelnaya.Kotli[i].blocked=0 && kotelnaya.Kotli[i].isFlame0=0 && kotelnaya.Kotli[i].errFlame1=0) { 
						indxK=i; kotelnaya.Kotli[i].gor0=1; 
					}
				}
			}
			//Если надо убавить газу
			if (needPower=-1) {
				// Ищем котел с одной работающей горелкой для остановки
				for (var i:int = 0;i < kotelnaya.Kotli.length;i++) {
					if (kotelnaya.Kotli[i].A=1 && kotelnaya.Kotli[i].isOn && kotelnaya.Kotli[i].errFlame0=0 && kotelnaya.Kotli[i].errFlame1=0 && kotelnaya.Kotli[i].blocked=0 && kotelnaya.Kotli[i].isFlame0=1 && kotelnaya.Kotli[i].errFlame1=0) { 
						indxK=i; kotelnaya.Kotli[i].gor0=0;
					}
				}
				// если не нашли работающий котел с одной горекой то останавливаем первый работающий с двумя горелками
				if (indxK=-1) {
					if (kotelnaya.Kotli[i].A=1 && kotelnaya.Kotli[i].isOn && kotelnaya.Kotli[i].errFlame0=0 && kotelnaya.Kotli[i].errFlame1=0 && kotelnaya.Kotli[i].blocked=0 && kotelnaya.Kotli[i].isFlame0=1 && kotelnaya.Kotli[i].errFlame1=1) { 
						indxK=i; kotelnaya.Kotli[i].gor1=0; 
					}
				}
			}			//trace(kotelnaya.t);
			
		}
		
		for each(var kotel:Kotel in kotelnaya.Kotli) {
			//if (kotel.A=1 && kotel.isOn=1) 
				
		}                                   
		
	}
	
	
	for each(kotel in kotelnaya.Kotli) {
		
		kotel.gor0=1;
	}
}    

/*var power:int = selectPower()
public function selectPower():int {
			// constructor code
	
	power=1;
	return power;
		}*/
