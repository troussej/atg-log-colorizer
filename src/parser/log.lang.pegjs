//test=STACKTRACE_AT
// **** debug   Tue Jan 26 16:35:33 CET 2016    1453822533848   /atg/commerce/PipelineManager   Post Link Transaction

LINE = l:( NUCLEUS_STARTED / LOG / NAKED_MESSAGE  / FAILSAFE)  {  l.fulltext=text(); return l }

LOG
 =  start:LOG_START _ message:(MESSAGE){
 return {level: start.level, value: [ start, '\t', message],};
 }
 
NUCLEUS_STARTED
  = _ ("Nucleus running, app server startup continuing" / "Invoking custom Nucleus initializer for Weblogic appserver.") _ {
    return {level:'keyword', value:text(), unique:true}
  }

FAILSAFE
   = ANY {return {value:text(),failsafe:true}}
 
LOG_START =logStart:( DYNAMO_LOG_START /DOZER_LOG_START/ JREBEL_LOG_START /JBOSS_LOG_START){
  return {value:logStart,type:'logstart', level:logStart.level}
}
 
DYNAMO_LOG_START
  = LOG_PREFIX? _ level:LEVEL _ date:TIMESTAMP _ process:INTEGER _ component:COMPONENT 
  { return {level:level.level, value: [level,'\t',date,'\t',component]}}

// 2016-02-03 12:23:14,948 DEBUG [org.jboss.system.ServiceController] PipelineResult has 0 errors
JBOSS_LOG_START
 = date:$(WORD _ WORD) _ level:LEVEL _ "["? classname:CLASS "]"? {
   return {value: [date, '\t',level,'\t', '[',classname,']' ] , level:level.level}
 }

// 2017-10-16 15:55:43 JRebel: Watching EJB 'DMSTopic' for changes
JREBEL_LOG_START 
 = date:$(WORD _ WORD) _ jrebel:"JRebel:" {
   return {value: [date, '\t',jrebel ] , level:'jrebel'}
 }

// <Jul 26, 2017 10:50:54 PM CEST> <Warning>
DOZER_LOG_START
  = "<" date:[^>]+ ">" _ "<" level:LEVEL ">"{
  return {value:text(), level:level.level}
 }

CLASS_ELEM=$[^. :;\(\)]+

CLASS
 = (CLASS_ELEM ".")+ CLASS_ELEM {
  return {value:text(),type:'class'}
 }

COMPONENT
   = PATH {
     return {
       value:text(),
       level:'component'
     }
   }

NAKED_MESSAGE = _ msg:MESSAGE _ {
  return {level:msg.level,value:msg.value}
}

MESSAGE
   = PIPELINE_MSG / STACKTRACE /  SQL_MSG / ANY_MESSAGE

PIPELINE_MSG = PIPELINE_MSG_GENERIC / PIPE_CHAIN_END / PIPE_RESULT


PIPELINE_MSG_GENERIC
  = prefix:$CHAIN_KEYWORD ws:_ name:WORD _ {
    return [ 
      {
        value:prefix,
        level:'chain'
      }, 
      ws,
      {
        value:name,
        level:'keyword'
      }
    ]
  }

  //Done Executing Chain: updateOrder


CHAIN_KEYWORD
  = "Executing link:" / "Done Executing Chain:" / "Executing Chain:" / "Last processor in chain, stopping chain execution for chain:"

//Link loadPriceInfoObjectsForOrder return value: 1
PIPE_CHAIN_END
 = prefix:$"Link " name:WORD suffix:" return value: " val:WORD {
  return [
    {
        value:prefix,
        level:'chain'
    }, 
    {
      value:name,
      level:'keyword'
    }, 
    {
      value:suffix,
      level:'chain'
    }, 
    {
      value:val,
      level:'keyword'
    }
  ]
 }

 //debug   Tue Jan 26 16:35:33 CET 2016    /atg/commerce/PipelineManager   PipelineResult has 0 errors
 PIPE_RESULT
  = prefix:$"PipelineResult has " val:INTEGER suffix:$" errors" {
    return [ prefix,{value:val,level:'keyword'},suffix ]
  }


// [++SQLSelect++]
SQL_MSG
 = val:$(_ "[++SQLSelect++]" _) {
  return {
    level:'sql',
    value:val
  }
 }

STACKTRACE = value:(EXCEPTION_OCCURED / STACKTRACE_AT  /  STACKTRACE_CAUSED_BY / STACKTRACE_ERROR ){
  return {value:value,type:'stacktrace'}
}

// Exception occured CommerceException


EXCEPTION_OCCURED
= prefix:$("Exception occured" _) exception:EXCEPTION {
  return [ prefix,exception ]
}

//Caused by :CONTAINER:atg.service.actor.ActorException: There was an error while trying to invoke a method.; SOURCE:java.lang.NullPointerException
//Caused by (#2):com.d
 STACKTRACE_CAUSED_BY
 = "Caused by"  _ index:$( "(#" INTEGER ")" )? _ ":" container:STACKTRACE_ERROR {
  return {
    value: [ "Caused by :",  index, container ],
    type:'causedby'
    }
 }

 STACKTRACE_ERROR =  (STACKTRACE_ERROR_ELEM _  ";" _ )* STACKTRACE_ERROR_ELEM
 
 STACKTRACE_ERROR_ELEM
 = prefix:$(  ("SOURCE:CONTAINER"/ "CONTAINER" / "SOURCE") ":")? exception:EXCEPTION sep:[;:]? ws:_  msg:$[^;]*  _ {
  return {
    value: [ prefix, exception,sep, ws,msg ],
    type:'stack_error_elem'
    }
 }


  
 
// at atg.adapter.gsa.GSAItem.getPersistentPropertyValue(GSAItem.java:1349)
STACKTRACE_AT
   = at:$"at" ws:_ method:CLASS "(" javaclass:CLASS  sep:":"? line:INTEGER? ")" {
    return {
      value: [ '\t',at, ws, {value:method, level:'at.method'},"(", {value:javaclass, level:'at.className'},sep,{value:line, level:'identifier'},")" ]
    }
   }

EXCEPTION
 = exception:CLASS {
  return {value:exception.value,level:'exception'}
}
    
ANY_MESSAGE "logMessage"
  =  elements:( SYMBOL _? ) *   {
    let value = [];
    elements.map( elem => {value.push(elem[0]); value.push(elem[1]) })
    return {value:value, type:'message'}
  }



SYMBOL
 =  KEYWORD / WORD

KEYWORD
 = ( "order"i / "commerceItem"i / "shippingGroup"i /"paymentGroup"i / "returnRequest"i / "returnItem"i ) _ [=:; \t] _ [^ .;,\t\n\r]+ {
  return {value:text(),level:'keyword.id'}
 }
 
WORD "WORD"
  =$[^ \t\n\r]+
  
LOG_PREFIX "log prefix"
  = "****"
  
LEVEL = ERROR / DEBUG / INFO / TRACE / WARNING
  
DEBUG "level: debug"
  = "debug"i {return { value:'debug', level:'debug'}}
  
WARNING "level: warning"
  = "warn"i "ing"i? {return { value:'warning', level:'warning'}}

ERROR "level: error"
  = "err"i "or"i? {return { value:'error', level:'error'}}

INFO "level: info"
  = "info"i  {return { value:'info', level:'info'}}

TRACE "level: trace"
  = "trace"i  {return { value:'trace', level:'trace'}}

NODE "NODE"
  =$[^ \t\n\r/]+
 
PATH "PATH"
  =$ (("/" NODE)+ / NODE / "/")

TIMESTAMP "TIMESTAMP"
     = $(WORD _ WORD _ INTEGER _ Digit Digit ":" Digit Digit ":" Digit Digit _ WORD _ INTEGER)

 
 // STD_LOG_LINE (%{SERVERNAME}%{SPACE})?20%{TIMESTAMP_ISO8601:logtimestamp}%{SPACE}%{LOGLEVEL:level}%{SPACE}\[%{JAVACLASS:class}\]%{SPACE}%{DATA:logMessage}?

INTEGER "INTEGER"
  =  $Digit+

Digit "digit"
 =$ [0-9]

_ "whitespace"
  = $[ \t\n\r]*
  
ANY "any"
   = .*