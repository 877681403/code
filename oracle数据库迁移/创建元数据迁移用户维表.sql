
--创建元数据迁移用户维表
create table dwmgimp.tb_dic_qianyi_metadata_users
as
select username 
  from dba_users@to_old_a
  where  username not in ('DWMIGEXP','SYSMAN','MGMT_VIEW','TSMSYS')
  AND    username not in 
        ('SYS','AUDSYS','SYSTEM','OUTLN','GSMADMIN_INTERNAL','GSMUSER',
	    'DIP','REMOTE_SCHEDULER_AGENT','DBSFWUSER','ORACLE_OCM','SYS$UMF',
	    'DBSNMP','APPQOSSYS','GSMCATUSER','GGSYS','XDB','ANONYMOUS','WMSYS',
	    'AIUAP','BOMC','SYSBACKUP','SYSDG','SYSKM','SYSRAC','XS$NULL');
		
grant all on dwmgimp.tb_dic_qianyi_metadata_users to public ;