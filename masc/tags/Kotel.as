/*
MASC 2018. Kotel    
топик для публикации данных выглядит так:	MASC/tags/PLC/K0/num	{"A":###,"name":@}
						настроек котла:		MASC/sets/PLC/K0/num	{ Что-то тут надо додумать}

kotel:Kotel
  {
		A:int 					1-Автомат/ 0-Ручное
		type:int				Тип котла 0 - двухгорелочный дискретный, 1 - двухгорелочный дискретно/аналоговый
		num:int 				Номер котла
		kotelnaya:int			Номер котельной
		
		errFlame0:int			Состояние ошибки/аварии горелки
		errFlame1:int			Состояние ошибки/аварии давления теплообменника котла
		gor0:int				Управление горелкой 0 (может быть 0-1 при дискретном управлении и 0-100 при аналоговом)
		gor1:int				Управление горелкой 1 (может быть 0-1 при дискретном управлении и 0-100 при аналоговом)
		isOn:int				Состояние котла 
		isFlame0:int			Состояние горелки 0
		isFlame1:int			Состояние горелки 1
		noSub:int				Переменная для хранения количества не найденных тегов
		blocked:int				Переменная для хранения режима работы котельной
		noConn:Boolean			Переменная для хранения состояния пропала ли связь с котельной
		
		args:Array String		Список значений к архивированию (заполняется в случае изменения значения на 1 процент от шкалы)
		vals:Array String		Значения к архивированию (заполняется в случае изменения значения на 1 процент от шкалы)
		
		name:String				Имя девайса
		src_gor0:String			Строковая переменная для хранения "топика" (управления) сигнала - управление горелкой 1
		src_gor0_v:String		Строковая переменная для хранения "топика" (управления) сигнала - отображения горелки 1
		src_gor1:String			Строковая переменная для хранения "топика" (управления) сигнала - управление горелкой 2
		src_gor1_v:String		Строковая переменная для хранения "топика" (управления) сигнала - отображения горелки 2
		src_isOn:String			Строковая переменная для хранения "топика" (источника) сигнала - состояние котла (питание в норме, котёл работает)
		src_isFlame0:String		Строковая переменная для хранения "топика" (источника) сигнала - состояние котла (плама горелки 1)
		src_isFlame1:String		Строковая переменная для хранения "топика" (источника) сигнала - состояние котла (плама горелки 1)
		src_errFlame0:String	Строковая переменная для хранения "топика" (источника) сигнала - состояние ошибки горелки
		src_errFlame1:String	Строковая переменная для хранения "топика" (источника) сигнала - состояние ошибки давления
		src_mode:String			Строковая переменная для хранения "топика" (источника) сигнала - режим котла
		src_mode_v:String		Строковая переменная для хранения "топика" (источника) сигнала - отображения режим котла
		src_blocked:String		Строковая переменная для хранения "топика" (источника) сигнала - режим работы котельной (блокировать управление Дистанционный/Местный режим)
		
	  function Kotel0			Функция которая выполняется при инициализации девайса.
	  function drop()			Функция сброса сигнала и его значений
	  function dropErr()		Функция сброса ошибок сигнала
  }
*/

package masc.tags {
	
	public class Kotel {
		public var A,type,num,kotelnaya,errFlame1,errFlame0,gor0,gor1,isOn,isFlame0,isFlame1,noSub,blocked:int;
		public var name:String="Котёл двух горелочный дискретный"; 
		public var src_gor0,src_gor1,src_gor0_v,src_gor1_v,src_isOn,src_isFlame0,src_isFlame1,src_errFlame0,src_errFlame1,src_mode,src_mode_v,src_blocked:String;
		public var args,vals:Array;
		public var pub,noConn:Boolean;
		
		public function Kotel() {
			trace("New Kotel created")// constructor code
			drop();
		}
		public function drop():void{
			A=type=gor0=gor1=isOn=isFlame0=isFlame1=0;
			pub=noConn=false
			dropErr();
		}
		public function dropErr():void{
			errFlame1=errFlame0=0;
		}
		public function addProp(nam:String,val:*):void{
			switch (nam){
				case "A": A=int(Number(val)>0); break;
				case "type": type=int(val); break;
				case "num": num=int(val); break;
				case "kotelnaya": kotelnaya=int(val); break;
				case "gor0": gor0=int(val); break;
				case "gor1": gor1=int(val); break;
				default: trace("Свойство Kotel."+nam+" на назначено. Нет в перечне функции addProp"); break;
			}
		}
		public function getProp(nam:String):*{
			switch (nam){
				case "A": return A; break;
				case "type": return type; break;
				case "num": return num; break;
				case "kotelnaya": return kotelnaya; break;
				case "gor0": return gor0; break;
				case "gor1": return gor1; break;
				default: trace("Свойство Kotel."+nam+" не возвращено. Нет в перечне функции getProp"); return null; break;
			}
			return null;
		}
	}
}
