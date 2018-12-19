/*
MASC 2018. DiscretInput
топик для публикации данных выглядит так:	MASC/tags/PLC/DI/num	{"fiz":###,"SP":###,"SPcor":###, "err":#}
					 настроек сигнала:		MASC/sets/PLC/DI/num	{"name":@,"filtr":##}

di:DiscretInput
  {
	  fiz:int				Фактичесоке (публикуемое) значение сигнала
	  fizOld:int			Для хранения прежнего значения(может потребоваться)
	  SP:int				Задание на сигнал									//Пока не известно если эти значения будут нужны (возможно в корректировках)
	  SPcor:int				Скорректированное значение задания сигнала 			//Пока не известно если эти значения будут нужны (возможно в корректировках)
	  cod:int				Для записи фактического значения от модуля
	  
	  num:int				Номер аналогово входа в системе
	  err:int				Для хранения ошибок по сигналу
	  filtr:int				Указанное фильтрация сигнала (время осле кторого значение можно считать принятым) //Пока не реализуем
	  noSub:int				Накопительная для счётчика отсутствия значения от брокера. При обращении к mainData если в течении 500 повторов нет данных, выводится сообщение в ошибку и повторный запрос на подписку отправляется принудительно
	  type:int				Тип сигнала 0 - прямой	1 - обратный
	  name:String			Строковая переменная для хранения имени сигнала
	  src:String			Строковая переменная для хранения "топика" (источника) сигнала
	  tag:String			Строковая переменная с именем тега в сообщении топика
	  
	  args:Array String		Список значений к архивированию (заполняется в случае изменения значения)
	  vals:Array String		Значения к архивированию (заполняется в случае изменения значения)
	  
	  pub:Boolean			Флаг, который ставим при смене значения для публикации и архивирования.
	  
	  function DiscretInput 		Функция которая выполняется при инициализации сигнала.
	  function drop()				Функция сброса сигнала и его значений
	  function dropErr()			Функция сброса ошибок сигнала
	  function addProp(String,*)	Функция вносит значение по имени в элемент структуры
	  function getSrc(String)		Закрытая функция разбирает строку на составляющие src и tag
	  function getProp(String):*	Функция возвращает значение по имени элемента структуры
  }
*/

package masc.tags {
	
	public class DiscretInput {
		public var fiz,fizOld,SP,SPcor,cod,num,err,filtr,noSub:int;
		public var type:int;
		public var src,tag,name:String="Дискретный вход"
		public var pub:Boolean=false;
		public var args,vals:Array;
		public var regs:Array;
		
		public function DiscretInput() {
			trace("New DI created")// constructor code
			drop();
		}
		public function drop():void{
			fiz=fizOld=SP=SPcor=noSub=err=filtr=0;
			args=vals=[];
		}
		public function dropErr():void{
			err=0;
		}
		public function addProp(nam:String,val:*):void{
			switch (nam){
				case "fiz": fiz=int(Number(val)>0); break;
				case "type": type=int(val); break;
				case "num": num=int(val); break;
				case "src": getSrc(val.toString()); break;
				case "filtr": filtr=int(val); break;
				default: trace("Свойство DI."+nam+" не назначено. Нет в перечне функции addProp");  break;
			}
		}
		private function getSrc(st:String):void{
			var arr:Array=st.split(":");
			src=arr[0];
			if (arr.length>1) {
				tag=arr[arr.length-1];
			} else {
				tag="RAW";
			}
		}
		public function getProp(nam:String):*{
			switch (nam){
				case "fiz": return fiz; break;
				case "SP": return SP; break;
				case "SPcor": return SPcor; break;
				case "type": return type; break;
				case "num": return num; break;
				case "src": return src; break;
				case "filtr": return filtr; break;
				default: trace("Свойство DI."+nam+" не возвращено. Нет в перечне функции getProp"); return null; break;
			}
			return null;
		}
	}
}
