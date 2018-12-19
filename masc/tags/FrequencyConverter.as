/*
MASC 2018. DeviceAnalog
топик для публикации данных выглядит так:	MASC/tags/PLC/DA/num	{"A":###,"OUT":###,"OUT_off":#,"OPEN":###,"CLOSE":###,"errConfig":#,"errOUT_IN":#,"errOUT_R":#,"name":@}
					 настроек сигнала:		MASC/sets/PLC/DA/num	{"typeDA":###,"num":###,"R_active":#####,"R_num":#####[5],"IN":##,"OUT_min":##,"OUT_max":##,"srcIN":@,"srcOUT":@,"srcOPEN":@,"srcCLOSE":@,"eu":@}

da:DeviceAnalog
  {
		A:int 				1-Автомат/ 0-Ручное
		type:int			Тип аналогового клапана 0 -обычный, 1 - с дискретным управлением
		num:int 			Номер девайса
		IN:Number			Положение 0-100% (при наличии)
		OUT:Number			Управление 0-100%
		OUT_min:int			Управление - ограничение минимального открытия в автомате
		OUT_max:int			Управление - ограничение максимального открытия в автомате
		OPEN:int			Концевик ОТКРЫТ (при наличии)
		CLOSE:int			Концевик ЗАКРЫТ (при наличии)
		OUT_off:int 		Управление - отключено		
		R_active:int		Регулятор - номер элемента массива активного регулятора
		R_num:Vector.<int> 	Регулятор - номера регуляторов привязанных к девайсу
		S_num:Vector.<int> 	Сеттинг - номера настроек девайса(условие переключения А/Р, закрытия/открытия, блокировка, выдача команды и тд)		
		errConfig:int		1- Ошибка конфигурации - не привязано управление(обратная связь может быть не привязана)
		errOUT_IN:int		0-100% - Ошибка управления - рассогласование положения и управления более 3% (показывать значение) 
		errOUT_R:int		1 - Ошибка регулятора (управление не приводит к изменению регулируемого параметра)
		
		name:String			Имя девайса
		srcIN:String		Строковая переменная для хранения "топика" (источника) сигнала - положение девайса
		srcOUT:String		Строковая переменная для хранения "топика" (источника) сигнала - управление с девайса
		srcOPEN:String		Строковая переменная для хранения "топика" (источника) сигнала - стостояние концевика ОТКРЫТО
		srcCLOSE:String		Строковая переменная для хранения "топика" (источника) сигнала - стостояние концевика ЗАКРЫТО
		eu:String			Инженерные единицы выдачи управления
	
	  
	  function DeviceAnalog  Функция которая выполняется при инициализации девайса.
	  function dropDA()		Функция сброса сигнала и его значений
	  function dropErr()	Функция сброса ошибок сигнала
  }
*/

package masc.tags {
	
	public class FrequencyConverter extends DeviceAnalog { 
		/*
		public var reg:Vector.<Regulator>  //Создать классы
		public var cor:Vector.<Correction> //Создать
		
		public var IN,OUT:Number;
		public var A,type,num,OUT_min,OUT_max,OPEN,CLOSE,OUT_off,R_active,errConfig,errOUT_IN,errOUT_R:int;
		public var R_num:Vector.5;
		public var S_num:Vector.10;
		public var name:String="Устройство управления аналоговое"; 
		public var srcIN,srcOUT,srcOPEN,srcCLOSE,eu:String;
		
		public function DeviceAnalog() {
			trace("New DA created")// constructor code
			drop();
		}
		public function drop():void{
			err=0;
		}
		public function dropErr():void{
			err=0;
		}
		*/
		override public function DeviceAnalog() {
			trace("New FC created")// constructor code
			drop();
		}
	}
}
