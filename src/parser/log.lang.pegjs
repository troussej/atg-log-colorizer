

// **** debug   Tue Jan 26 16:35:33 CET 2016    1453822533848   /atg/commerce/PipelineManager   Post Link Transaction

LINE = l:( LOG / NUCLEUS_STARTED / FAILSAFE)  { return l }

LOG
 =  start:LOG_START _ message:MESSAGE{
 return {level: start.level, value: [ start, message]};
 }
 
NUCLEUS_STARTED
  = _ "Nucleus running, app server startup continuing" _ {
    return {level:'special', value:text(), unique:true}
  }

FAILSAFE
   = ANY {return {value:text(),failsafe:true}}
 
LOG_START = DYNAMO_LOG_START
 
DYNAMO_LOG_START
  = LOG_PREFIX? _ level:LEVEL _ date:TIMESTAMP _ process:INTEGER _ component:COMPONENT 
  { return {level:level, value: [level,date,component]}}


COMPONENT
   = PATH {
     return {
       value:text(),
       level:'component'
     }
   }
    
MESSAGE "logMessage"
  =  ANY  {
    return {value:text()}
  }
 
WORD "WORD"
  =$[^ \t\n\r]+
  
LOG_PREFIX "log prefix"
  = "****"
  
LEVEL = ERROR / DEBUG / INFO / TRACE
  
DEBUG "level: debug"
  = "debug"i {return 'debug'}

ERROR "level: error"
  = "err"i "or"i?  {return 'error'}

INFO "level: info"
  = "info"i  {return 'info'}

TRACE "level: trace"
  = "trace"i  {return 'trace'}

NODE "NODE"
  =$[^ \t\n\r/]+
 
PATH "PATH"
  =$ ("/" NODE)+

TIMESTAMP "TIMESTAMP"
     = $(WORD _ WORD _ INTEGER _ Digit Digit ":" Digit Digit ":" Digit Digit _ WORD _ INTEGER)

 
 // STD_LOG_LINE (%{SERVERNAME}%{SPACE})?20%{TIMESTAMP_ISO8601:logtimestamp}%{SPACE}%{LOGLEVEL:level}%{SPACE}\[%{JAVACLASS:class}\]%{SPACE}%{DATA:logMessage}?

INTEGER "INTEGER"
  =  $Digit+

Digit "digit"
 =$ [0-9]

_ "whitespace"
  = [ \t\n\r]* {return ' '}
  
ANY "any"
   = .*