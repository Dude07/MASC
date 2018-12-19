/*
MASC 2018. Kotelnaya    
топик для публикации данных выглядит так:	MASC/tags/PLC/K0/num	{"A":###,"name":@}
						настроек котла:		MASC/sets/PLC/K0/num	{ Что-то тут надо додумать}

kotelnaya:Kotelnaya
  {
		A:int 					1-Автомат/ 0-Ручное
		num:int 				Номер котельной
		err:int					Для хранения кода ошибки в котельной. Посмотрим что прикрутить сюда
		pub:Boolean				Флаг смены состояния в котельной
		distReg:Boolean			Хранит в себе значение местное или дистанционное управление котельной
		fiz:Number				Температура объекта или подачи
		SP:Number				Задание на температуру объекта или подачи
		delta:Number			Дельта для разбега температуры
		power:int 				Уровень необходимой мощности
		timeWait:int			Время ожидания на принятие решения по горелкам
		t:int					Таймер 
		fiz_f:Number			Фильтрованное физическое подачи
		fiz_f_t:int				Время фильтрации
		fiz_f_old:Number		Фильтрованное старое физическое подачи
		T_inc:int				Температура рост(+1) или падение(-1)  или стагнация(0)(+-0.1 градуса за минуту)
		
		ping:Number				Время последнего пинга от котельной в милисекундах (Последних данных из топика ping для проверки связи)
		algorithm:Object		Объект в котором хранятся настройки работы алгоритма котельной
			SP:String			Топик сигнала температуры для задания (объект или подача)
			fiz:String			Топик сигнала температуры (объект или подача)
		process:Bool			Переменная флаг, которая высталяется, когда произошло смещение по ключевым значениям котельной и необходимо обработка алгоритмом

		Kotli:Vector.<Kotel>;	массив Котлов в данной котельной
		
		
		name:String				Имя девайса
		src_sets:String			Строковая переменная для хранения "топика" с установками котельной (как правило, режим работы и режимы работы котлов)
		src_ping:String			Строковая переменная для хранения "топика" для обновления значения присутствия устройства в системе
		src_mode:String			Строковая переменная для хранения "топика" куда записывать смену режима работы котельной
		src_pubAll:String		Строковая переменная для хранения "топика" триггера отправки всех данных котельной в брокер (при подключении клиента)
		
		function Kotelnaya		Функция которая выполняется при инициализации котельной.
		function drop()			Функция сброса котельной и её значений
		function dropErr()		Функция сброса ошибок сигнала
  }

*/


package masc.tags {
	import fl.data.DataProvider;
	import masc.tags.Kotel;
	
	public class Kotelnaya {
		public var A,num,err,timeWait,t,fiz_f_t,power,T_inc:int;
		public var pub,distReg,process:Boolean;
		public var algorithm:Object;
		public var name:String="Котельная"; 
		public var Kotli:Vector.<Kotel>;
		public var src_sets,src_ping,src_mode,src_pubAll:String;
		public var ping,fiz,SP,fiz_f,fiz_f_old,delta:Number;
		
		public function Kotelnaya() {
			trace("New Kotelnaya created")// constructor code
			drop();
		}
		public function drop():void{
			A=num=-1;
			pub=distReg=process=false;
			algorithm=new Object();
			src_sets,src_ping,src_mode,src_pubAll="";
			Kotli=new Vector.<Kotel>();
			t=fiz_f=fiz_f_old=delta=fiz_f_t=fiz=T_inc=0;
			dropErr();
		}
		public function dropErr():void{
			err=0;
		}
		
		public function addProp(nam:String,val:*):void{
			switch (nam){
				case "A": A=int(Number(val)>0); break;
				case "num": num=int(val); break;
				case "err": err=int(val); break;
				case "timeWait": timeWait=int(val); break;
				case "t": t=int(val); break;
				case "fiz_f_t": fiz_f_t=int(val); break;
				case "power": power=int(val); break;
				
				case "name": name=val.toString(); break;
				case "fiz": fiz=Number(val);break;				
				case "fiz_f": fiz_f=Number(val);break;
				case "fiz_f_old": fiz_f_old=Number(val);break;
				case "delta": delta=Number(val);break;
				default: trace("Свойство Kotelnaya."+nam+" на назначено. Нет в перечне функции addProp"); break;
			}
		}
		public function getProp(nam:String):*{
			switch (nam){
				case "A": return A; break;
				case "num": return num; break;
				case "err": return err; break;
				case "timeWait": return timeWait; break;
				case "t": return t; break;
				case "fiz_f_t": return fiz_f_t; break;
				case "power": return power; break;
				
				case "name": return name; break;
				case "fiz": return fiz; break;
				case "fiz_f": return fiz_f; break;
				case "fiz_f_old": return fiz_f_old; break;
				case "delta": return delta;break;
				default: trace("Свойство Kotelnaya."+nam+" на назначено. Нет в перечне функции addProp"); return null; break;
			}
			return null;
		}
	}
}
