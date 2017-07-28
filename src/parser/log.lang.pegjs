

// **** debug   Tue Jan 26 16:35:33 CET 2016    1453822533848   /atg/commerce/PipelineManager   Post Link Transaction

LINE = l:( LOG / NAKED_MESSAGE / NUCLEUS_STARTED / FAILSAFE)  { return l }

LOG
 =  start:LOG_START _ message:(MESSAGE){
 return {level: start.level, value: [ start, '\t', message]};
 }
 
NUCLEUS_STARTED
  = _ "Nucleus running, app server startup continuing" _ {
    return {level:'keyword', value:text(), unique:true}
  }

FAILSAFE
   = ANY {return {value:text(),failsafe:true}}
 
LOG_START = DYNAMO_LOG_START /DOZER_LOG_START/JBOSS_LOG_START
 
DYNAMO_LOG_START
  = LOG_PREFIX? _ level:LEVEL _ date:TIMESTAMP _ process:INTEGER _ component:COMPONENT 
  { return {level:level.value, value: [level,'\t',date,'\t',component]}}

// 2016-02-03 12:23:14,948 DEBUG [org.jboss.system.ServiceController] PipelineResult has 0 errors
JBOSS_LOG_START
 = date:$(WORD _ WORD) _ level:LEVEL _ "["? classname:CLASS "]"? {
   return {value: [date, '\t',level,'\t', '[',classname,']' ] , level:level.value}
 }

// <Jul 26, 2017 10:50:54 PM CEST> <Warning>
DOZER_LOG_START
  = "<" date:[^>]+ ">" _ "<" level:LEVEL ">"{
  return {value:text(), level:level.value}
 }

CLASS
 = ([a-zA-Z0-9#$]+ ".")* [a-zA-Z0-9#$]+ {
  return {value:text(),type:'component'}
 }

COMPONENT
   = PATH {
     return {
       value:text(),
       level:'component'
     }
   }

NAKED_MESSAGE = _ MESSAGE _

MESSAGE
   = PIPELINE_MSG / STACKTRACE /  ANY_MESSAGE

PIPELINE_MSG = PIPELINE_MSG_GENERIC / PIPE_CHAIN_END


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

CHAIN_KEYWORD
  = "Transaction is" / "Executing link:" / "Executing Chain:" / "Last processor in chain, stopping chain execution for chain:"

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

STACKTRACE = EXCEPTION_OCCURED / STACKTRACE_AT /STACKTRACE_SOURCE/ STACKTRACE_CONTAINER /  STACKTRACE_CAUSED_BY

// Exception occured CommerceException


EXCEPTION_OCCURED
= prefix:$("Exception occured" _) exception:CLASS {
  return [ prefix,{value:exception,level:'exception'} ]
}

//Caused by :CONTAINER:atg.service.actor.ActorException: There was an error while trying to invoke a method.; SOURCE:java.lang.NullPointerException
 STACKTRACE_CAUSED_BY
 = "Caused by" _ ":" container:STACKTRACE_CONTAINER {
  return {
    value: [ "Caused by :", container ],
    type:'causedby'
    }
 }

 STACKTRACE_CONTAINER
 = "CONTAINER" ":" exception:CLASS ":" _  msg:$[^;]+ ";" _ source:STACKTRACE_SOURCE? {
  return {
    value: [  "CONTAINER",":", {value:exception,level:'exception'},": ",msg,"; ", source ],
    type:'container'
    }
 }

 STACKTRACE_SOURCE
  = "SOURCE" ":" exception:CLASS {
    return [ "SOURCE:",{value:exception, level:'exception'} ]
  }
 
// at atg.adapter.gsa.GSAItem.getPersistentPropertyValue(GSAItem.java:1349)
STACKTRACE_AT
   = at:$"at" ws:_ method:CLASS "(" javaclass:CLASS ":" line:INTEGER ")" {
    return {
      value: [ at, ws, {value:method, level:'at.method'},"(", {value:javaclass, level:'at.className'},":",{value:line, level:'identifier'},")" ]
    }
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
 = ( "order"i / "commerceItem"i / "shippingGroup"i /"paymentGroup"i / "returnRequest"i / "returnItem"i )_ [=:]? _ WORD {
  return {value:text(),level:'keyword.id'}
 }
 
WORD "WORD"
  =$[^ \t\n\r]+
  
LOG_PREFIX "log prefix"
  = "****"
  
LEVEL = ERROR / DEBUG / INFO / TRACE / WARNING
  
DEBUG "level: debug"
  = "debug"i {return { value:'debug', level:'levelType'}}
  
 WARNING "level: warning"
  = "warn"i "ing"i? {return { value:'warning', level:'levelType'}}

ERROR "level: error"
  = "err"i "or"i? {return { value:'error', level:'levelType'}}

INFO "level: info"
  = "info"i  {return { value:'info', level:'levelType'}}

TRACE "level: trace"
  = "trace"i  {return { value:'trace', level:'levelType'}}

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