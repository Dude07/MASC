/*
MASC 2018. AnalogInput
топик для публикации данных выглядит так:	MASC/tags/PLC/AI/num	{"fiz":###,"SP":###,"SPcor":###, "err":#}
					 настроек сигнала:		MASC/sets/PLC/AI/num	{"eu":@,"name":@,"fiz_min":###,"fiz_max":###,"cod_min":#####,"cod_max":#####,"mA_min":##,"mA_max":##,"filtr":##}

ai:AnalogInput
  {
	  fiz:Number			Фактичесоке (публикуемое) значение сигнала
	  fiz_notF:Number 		Мгновенное физическое значение вычисленное с мА. Не фильтрованное.
	  fizOld:Number			Для хранения прежнего значения(может потребоваться)
	  SP:Number				Задание на сигнал
	  SPcor:Number			Скорректированное значение задания сигнала
	  fiz_min:Number		указанное минимальное для физ шкалы
	  fiz_max:Number		указанное максимальное для физ шкалы
	  cod:Number			Для записи фактического значения от модуля
	  cod_min:Number		Указанное минимальное фактическое от модуля
	  cod_max:Number		Указанное максимальное фактическое от модуля
	  mA:Number				Для записи вычисленного значения милиампер от модуля
	  mltp:Number			Множитель для физ значения от готового источника
	  
	  num:int				Номер аналогово входа в системе
	  err:int				Для хранения ошибок по сигналу
	  filtr:int				Указанное фильтрации сигнала
	  mA_min:int			Указанное минимальное значение для милиампер
	  mA_max:int			Указанное максимальное значение для милиампер
	  noSub:int				Накопительная для счётчика отсутствия значения от брокера. При обращении к mainData если в течении 500 повторов нет данных, выводится сообщение в ошибку и повторный запрос на подписку отправляется принудительно
	  type:int				Тип сигнала (по источнику)  0 - данные сырые от модуля, тут все настройки cod,fiz,mA
														1 - готовые данные от источника, тут только fiz и так же значение mltp - множитель готового значения (например: если от источника приходит целочисленнное int, со смещением запятой в Number)
	  name:String			Строковая переменная для хранения имени сигнала
	  src:String			Строковая переменная для хранения "топика" (источника) сигнала
	  tag:String			Строковая переменная в сообщении топика
	  eu:String				Строковая переменная для хранения единиц измерения физической шкалы
	  
	  args:Array String		Список значений к архивированию (заполняется в случае изменения значения на 1 процент от шкалы)
	  vals:Array String		Значения к архивированию (заполняется в случае изменения значения на 1 процент от шкалы)
	  
	  pub:Boolean			Флаг, который ставим при смене значения.
	  
	  regs:Array			Массив из Regulators для данного AI
	  
	  function AnalogInput  Функция которая выполняется при инициализации сигнала.
	  function drop()		Функция сброса сигнала и его значений
	  function dropErr()	Функция сброса ошибок сигнала
	  function addProp(String,*)	Функция вносит значение по имени в элемент структуры
	  function getSrc(String)		Закрытая функция разбирает строку на составляющие src и tag
	  function getProp(String):*	Функция возвращает значение по имени элемента структуры
  }
*/

package masc.tags {
	
	public class AnalogInput {
		public var fiz,fiz_notF,fizOld,SP,SPold,SPcor,SPcorOld,fiz_min, fiz_max,cod,cod_min,cod_max,mA,mltp:Number;
		public var num,err,filtr,mA_min,mA_max,noSub:int;
		public var type:int;
		public var name:String="Аналоговый вход"
		public var src,tag,eu:String;
		public var pub:Boolean=false;
		public var args,vals:Array;
		public var regs:Array;
		
		public function AnalogInput() {
			trace("New AI created")// constructor code
			drop();
		}
		public function drop():void{
			fiz=SP=SPcor=SPold=SPcorOld=0;
			mA=noSub=0;
			err=0;
			args=vals=regs=[];
		}
		public function dropErr():void{
			err=0;
		}
		public function addProp(nam:String,val:*):void{
			switch (nam){
				case "fiz": fiz=Number(val); break;
				case "mA": mA=int(val); break;
				case "type": type=int(val); break;
				case "num": num=int(val); break;
				case "src": getSrc(val.toString()); break;
				case "eu": eu=val.toString(); break;
				case "filtr": filtr=int(val); break;
				case "fiz_min": fiz_min=Number(val);break;
				case "fiz_max": fiz_max=Number(val);break;
				case "cod_min": cod_min=Number(val);break;
				case "cod_max": cod_max=Number(val);break;
				case "mA_min": mA_min=int(val); break;
				case "mA_max": mA_max=	int(val); break;
				case "mltp": mltp=Number(val);break;
				default: trace("Свойство AI."+nam+" не назначено. Нет в перечне функции addProp");  break;
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
				case "mA": return mA; break;
				case "SP": return SP; break;
				case "SPcor": return SPcor; break;
				case "type": return type; break;
				case "num": return num; break;
				case "src": return src; break;
				case "eu": return eu; break;
				case "filtr": return filtr; break;
				case "fiz_min": return fiz_min;break;
				case "fiz_max": return fiz_max;break;
				case "cod_min": return cod_min;break;
				case "cod_max": return cod_max;break;
				case "mA_min": return mA_min; break;
				case "mA_max": return mA_max; break;
				case "mltp": return mltp;break;
				default: trace("Свойство AI."+nam+" не возвращено. Нет в перечне функции getProp"); return null; break;
			}
			return null;
		}
	}
}
