#!/bin/bash      
WORD=$1
LOG=$2                                                     
RESULT=`awk '{print $9}' $LOG | grep -v $WORD | sort |  uniq -c` 
if [ -n "$RESULT" ]; then                                             
        RESULT="  count http                                          
$RESULT"                                                              
        logger "$RESULT"                                              
fi