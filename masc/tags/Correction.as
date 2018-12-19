/*
MASC 2018. Correction
топик для публикации данных выглядит так:	MASC/tags/PLC/COR/num	{"A":###,"OUT":###,"OUT_off":#,"OPEN":###,"CLOSE":###,"errConfig":#,"errOUT_IN":#,"errOUT_R":#,"name":@}
					 настроек сигнала:		MASC/sets/PLC/COR/num	{"typeDA":###,"num":###,"R_active":#####,"R_num":#####[5],"IN":##,"OUT_min":##,"OUT_max":##,"srcIN":@,"srcOUT":@,"srcOPEN":@,"srcCLOSE":@,"eu":@}

cor:Correction
  {
		<cor id="0" num="0" active="0" val1="MASC/tags/PLC/0/AI/3:fiz" exp="dequal" val2="MASC/tags/PLC/0/AI/3:SP" val3="20" type="0" koef="10"/>
		
		active:int 			Активна или нет
		num:int 			Номер девайса
		
		val1:String			Значение(число) или строка топика для вытягивания значения X уравнения X <отношение> Y на Z
		val2:String			Значение(число) или строка топика для вытягивания значения Y уравнения X <отношение> Y на Z
		val3:String			Значение(число) или строка топика для вытягивания значения Z уравнения X <отношение> Y на Z
		
		exp:String			строка с формой отношения X к Y (0 equl ==, 1 dqul <>, 2 grtn >, 3 less <, 4 egrt >=, 5 eles <=) Можно вносить и цифры
		type:int			тип коррекции (0 аналоговая, 1 дискретная)
		koef:Number			значение коэффициента
	  
	  function Correction  Функция которая выполняется при инициализации.
	  function drop()		Функция сброса сигнала и его значений
	  function dropErr()	Функция сброса ошибок сигнала
  }
*/

package masc.tags {
	
	public class Correction{
		//public var reg:Vector.<Regulator>  //Создать классы
		//public var cor:Vector.<Correction> //Создать
		
		public var koef:Number;
		public var active,type,num:int;
		public var val1,val2,val3,exp:String;
		
		public function Correction() {
			trace("New COR created")// constructor code
			drop();
		}
		public function drop():void{
			koef=0;
			active=0; type=num=0;
			val1=val2=val3=exp="";
		}
		public function addProp(nam:String,val:*):void{
			switch (nam){
				case "type": type=int(val); break;
				case "active": active=int(val); break;
				case "num": num=int(val); break;
				case "koef": koef=Number(val);break;
				case "val1": val1=val.toString(); break;
				case "val2": val2=val.toString(); break;
				case "val3": val3=val.toString(); break;
			}
		}
	}
}
