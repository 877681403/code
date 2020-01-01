select *
  from dba_users@to_old_a
  where username not like 'MASA%'
  and   username not in ('DWMIGEXP','SYSMAN','MGMT_VIEW','TSMSYS')
  AND   username not in 
       ('SYS','AUDSYS','SYSTEM','OUTLN','GSMADMIN_INTERNAL','GSMUSER',
	   'DIP','REMOTE_SCHEDULER_AGENT','DBSFWUSER','ORACLE_OCM','SYS$UMF',
	   'DBSNMP','APPQOSSYS','GSMCATUSER','GGSYS','XDB','ANONYMOUS','WMSYS',
	   'AIUAP','BOMC','SYSBACKUP','SYSDG','SYSKM','SYSRAC','XS$NULL')
	   

	   