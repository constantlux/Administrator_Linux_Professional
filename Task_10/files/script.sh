#!/bin/bash


LOG_NAME=./apache_logs
LAST_ROW=./last_row



#Проверяем наличие файлов логов
ARRAY=`find $LOG_NAME*`
if  [ $? -ne 0 ]
then
	echo "Нет файла лога"
	exit 1
fi


#Читаем все логи или есть уже обработанный отрезок
if [ -e $LAST_ROW ] 
then
	if [ -s $LAST_ROW ]
	then
		BEGIN=`cat $LAST_ROW`
		NROW=`nl $LOG_NAME | grep -F "$BEGIN" | awk '{print $1+1}'`
		tail -n+$NROW $LOG_NAME > $LOG_NAME.tmp
	else
		cp $LOG_NAME $LOG_NAME.tmp 
	fi
else
	touch $LAST_ROW
	cp $LOG_NAME $LOG_NAME.tmp
fi

#Парсим если есть, что обрабатывать
if [ -s $LOG_NAME.tmp ]
then	
	BDATE=`head -n 1 $LOG_NAME.tmp | awk '{print $4" "$5}' | sed -r 's/(\[|\])//g'`
	EDATE=`tail -n 1 $LOG_NAME.tmp | awk '{print $4" "$5}' | sed -r 's/(\[|\])//g'`
	TOP_IP=`cat $LOG_NAME.tmp | awk '{print $1}'  | sort | uniq -c | sort -r | head -n 20`
	TOP_URL=`cat $LOG_NAME.tmp | awk '{print $7}'  | sort | uniq -c | sort -r | head -n 20`
	TOP_HTTP=`cat $LOG_NAME.tmp | awk '{print $9}'  | sort | uniq -c | sort -r | head -n 20`
	SRV_ERR=`cat $LOG_NAME.tmp | awk '{print $9}' | grep -P "^5\d\d" | sort | uniq -c | sort -r`
	
	#Делаем отметку о последней обработанной записи
	tail -n 1 $LOG_NAME.tmp > $LAST_ROW
	
	#Формируем отчёт
	PRINT="                                                                                                         
	Обработаны логи за интервал 
	$BDATE -  $EDATE                                                                                                          
	ТОП 20 ip                                                                                                                 
	  count ip
	$TOP_IP                                                                                                                
	ТОП 20 url                                                                                                                
	  count url
	$TOP_URL                                                                                                               
	ТОП 20 HTTP 
	  count code
	$TOP_HTTP                                                                                                              
	Ошибки на стороне сервиса                                                                                                 
	  count error
	$SRV_ERR
	"
else
       PRINT="Нет новых записей"
fi      


#echo "$PRINT"


#Удаляем временный файл   
if [ -e $LOG_NAME.tmp ]
then
	rm $LOG_NAME.tmp
fi	
		                                  

#Отправляем
echo "$PRINT" | mail -s "Поставка парсинга" vagrant@examle.org