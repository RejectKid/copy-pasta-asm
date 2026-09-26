extern malloc, calloc, free, memcpy, memmove, memset, memcmp
extern strlen, strcmp, strcpy, strcat, strtod, sscanf, strftime
extern fopen, fclose, fseek, ftell, fread, fwrite, fputc, fputs, fprintf, ferror
extern puts, getenv, exit
%ifdef WINDOWS
extern _snprintf, _time64, _localtime64, _gmtime64, _mkgmtime64, _strtoi64
%define snprintf_fn _snprintf
%define time_fn _time64
%define localtime_fn _localtime64
%define gmtime_fn _gmtime64
%define timegm_fn _mkgmtime64
%define strtoll_fn _strtoi64
%else
extern snprintf,time,localtime,gmtime,timegm,strtoll
%define snprintf_fn snprintf
%define time_fn time
%define localtime_fn localtime
%define gmtime_fn gmtime
%define timegm_fn timegm
%define strtoll_fn strtoll
%endif
