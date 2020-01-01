

---------------前台数据，不在迁移规则内的数据，需要手动导入-------数据量小（割接当天处理）---------
--前台数据导入
--手动开command窗口，执行,
--生成的文件也在新开的command窗口执行
set echo off;
set feedback off;
set heading off;
set pagesize 0;
set linesize 1000;
set termout off;
set trimout on;
set trimspool on;
set newpage 0;
set space 0;
set verify off;
set markup html off spool off;
set long 2048576;
set trim on;
spool E:\个人目录\刘向南\A库迁移\脚本20191105\数据同步\insert_data_single_qiantai.sql
  select 'alter session enable parallel dml;'||chr(10)||
         'set timing on;'||chr(10)||
		 'set time on;'||chr(10)||
		 'truncate table '||a.owner||'.'||a.table_name||';'||chr(10)||
		 'insert /*+parallel(b,8) append */ into '||chr(10)||
		 a.owner||'.'||a.table_name||' b'||chr(10)||
		 'select /*+parallel(c,8)*/ * from '||
		 a.owner||'.'||a.table_name||'@to_old_a c;'||chr(10)||
		 'commit;'chr(10)
	from dba_tables@to_old_a a
   where a.owner||'.'||a.table_name in 
         ('MASAQER.BI_INDEX_INFO',
		  'MASAQER.M',
		  '');
		  
spool off


--------------------------------------------------------------

--1.维表中记录
select count(1) from dwmigimp.tb_dic_dba_segments@to_old_a ;
--276166


--------------------------------------------------------------

--2.配置表记录
select count(1) from dwmigimp.tb_dic_sync_cfg
--276137
--(其中29条是大小写问题，需手动处理)


--查看生成试图报错的
select * from dwmigexp.tb_dic_sync_cfg_err@to_old_a
--29

--(配置表不可能比维表多，后面有过程删除配置表比维表多的记录)

--生成视图报错的需要手动处理
--如果字段是varchar
--手动开command窗口，执行
set echo off;
set feedback off;
set heading off;
set pagesize 0;
set linesize 1000;
set termout off;
set trimout on;
set trimspool on;
set newpage 0;
set space 0;
set verify off;
set markup html off spool off;
set long 2048576;
set trim on;
spool E:\个人目录\刘向南\A库迁移\脚本20191105\数据同步\insert_data_single_qiantai.sql
  select 'alter session enable parallel dml;'||chr(10)||
         'set timing on;'||chr(10)||
		 'set time on;'||chr(10)||
		 'alter table '||a.table_owner||'.'||a.table_name||' truncate partition "'||a.partition_name||'";'||chr(10)||
		 'insert /*+parallel(b,8) append */ into '||chr(10)||
		 a.table_owner||a.table_name||' partition("'||a.partition_name||'") b'|\chr(10)||
		 'select /*+parallel(c,8)*/ * from '||chr(10)||
		 a.table_owner||'.'||a.table_name||'@to_old_a c'||chr(10)||
		 'where deal_date='''||substr(a.partition_name,-8)||''';'||chr(10)||
		 'commit;'||chr(10)
	from dwmgexp.tb_dic_sync_cfg_err@to_old_a a
	where table_name='TB_FBI_D11_30028_BEFTRANS_DATA'
	order by a.table_owner,a.table_name,a.partition_name;
		  
spool off





--------------------------------------------------------------

--3.查看生成配置表的过程报错信息
select * from dwmgexp.tb_dic_err_desc@to_old_a;

--------------------------------------------------------------


--4.生成配置表报错的
--查看生成配置表错误的记录是否在老库dba_segments中
--如果不在，则说明老库删掉了，不用在生成配置表记录
select * 
  from dwmigexp.tb_dic_sync_cfg_err@to_old_a a
 where exists 
 (select 1 
    from dba_segments@to_old_a b
	where a.table_owner=b.owner
	and   a.table_name=b.segment_name
	and   nvl(a.partition_name,'0')=nvl(b.partition_name,'0')
 ) ;
 --其中有29条 是表民或者分区名大小写问题，手动处理
 
 --如果存在，说明生成配置表出错，定位什么问题，update 维表重新生成配置表此纪录
 --重跑生成配置表调度
 update dwmigexp.tb_dic_dba_segments@to_old_a
   set unique_id =null
   where (owner,segment_name,nvl(partition_name,'0')) 
     in  (select table_owner,table_name,nvl(partition_name,'0')
            from dwmigexp.tb_dic_sync_cfg_err@to_old_a
	     );
  commit;
  
  --------------------------------------------------------------
  
  --5.查看差异（维表比配置表多的，更新维表中unique_id进行重新生成少的这部分配置表记录）
  --一般情况下不会有差异（除非生成配置表时出现异常，查看生成配置表错误的日志表）
  select * 
    from dwmigexp.tb_dic_dba_segments@to_old_a
   where owner||'.'||segment_name||'.'||nvl(partition_name,'0') in
         (select owner||'.'||segment_name||'.'||nvl(partition_name,'0')
		    from dwmigexp.tb_dic_dba_segments@to_old_a
		  minus 
		  select schema_name||'.'||table_name||'.'||nvl(partition_name,'0')
		    from dwmigimp.tb_dic_sync_cfg);
  --29条，结果如同上面
  
  
  --更新维表unique_id 重新生成配置表（排除大小写，有其他记录，则重新生成）
  update dwmigexp.tb_dic_dba_segments@to_old_a
    set unique_id=null
	where owner||'.'||segment_name||'.'||nvl(partition_name,'0') in
         (select owner||'.'||segment_name||'.'||nvl(partition_name,'0')
		    from dwmigexp.tb_dic_dba_segments@to_old_a
		  minus 
		  select schema_name||'.'||table_name||'.'||nvl(partition_name,'0')
		    from dwmigimp.tb_dic_sync_cfg);
  commit;
  
  
  
 ----------------------------------------------------------------
 
--6.查看未同步分类
select distinct trim(b.partition_type),
                trim(b.partition_subtype),
				count(1)
  from dwmigimp.tb_dic_sync_cfg a,
       dwmigimp.tb_dic_qianyi_tab b
  where a.schema_name=b.owner
  and   a.table_name=b.segment_name
  and   a.sync_flag='Y'
  and   a.status=0
  group by trim(b.partition_type),trim(b.partition_subtype)
  
  
  
-------------------------------------------------------------------

--7.查看正在同步的
select a.* 
  from dwmigimp.tb_dic_sync_cfg a,
       dwmigimp.tb_dic_qianyi_tab b
  where a.schema_name=b.owner
  and   a.table_name=b.table_name
  and   b.sync_flag='Y'
  and   a.status=0
  and   a.unique_no is not null;  
  
  
  
  
-------------------------------------------------------------------
--8.同步过程异常
select * from dwmigimp.tb_dic_sync_err




-------------------------------------------------------------------

--9.同步可能出现问题，status=1,unique_no 为空，
--重新同步，在重新稽核（知会程培培）
--（这种问题在B库迁移时出现了，A库迁移时未出现，问题未能复现）
select * from dwmigimp.tb_dic_sync_cfg
  where unique_no is null
  and   status=1;

--解决方案
update dwmigimp.tb_dic_sync_cfg
  set  status=0,unique_no=null
 where unique_no is null
 and   status=1;
 
 commit;
  
  
  
  
-------------------------------------------------------------------

 --10.查看配置表中status=0，且unique_no 有值的记录（分两种）
--原因1：正在执行，此纪录表正在同步中
--原因2：终止调度时，只更新unique_no，就不会向下执行了，尤其是大表同步时间的长
select * from dwmigimp.tb_dic_sync_cfg
where status=0
and   unique_no is not null;

--查看配置表中status=0，且unique_no不为空的记录在日志中的状态
select * 
  from dwmigimp.tb_sync_log
 where (schema_name,table_name,nvl(partition_name,'0')) in 
       (select schema_name,table_name,nvl(partition_name,'0')
	      from dwmgimp.tb_dic_sync_cfg
		  where status=0
		  and   unique_no is not null
		  )
  and  to_char(date_1)='02-12月-19';

--解决办法,更新配置表重新跑数据
update dwmigimp.tb_dic_sync_cfg
  set unique_no=null,status=0,count_1=0 
where unique_no is not null
and   status=0;
commit;
  
-------------------------------------------------------------------

--11.查询配置表中状态status=3的记录（例如，，没分区，并行不足报错的）
--解决方案，元数据处理后，把配置表状态，unique_no 更新，重新同步

--查看配置表中状态为3的记录（需要再次处理）
select count(1) 
  from dwmigimp.tb_dic_sync_cfg
  where status=3;
 

 
--状态为3的详情（最近出现的）
select schema_name,
       table_name,
       partition_name,
       status,
       error_desc,
       date_1
  from dwmigimp.tb_sync_log a
 where status=3 
 order by date_1 desc;

 
 
--涉及到视图变更的，更新维表unique_id=null跑调度，生成配置表
--先更新维表
update dwmigexp.tb_dic_dba_segments@to_old_a
  set unique_id=null
 where (owner||'.'||segment_name||'.'||nvl(partition_name,'0')) in 
       (select schema_name||'.'||table_name||'.'||nvl(partition_name,'0')
	      from (select schema_name,
		               table_name,
					   partition_name,
					   status,
					   error_desc,
					   date_1
				  from dwmigimp.tb_sync_log a
				  where status=3 
				  and   error_desc like '%ORA-00913%')
		);
COMMIT;



--从配置表中删除
delete from dwmigimp.tb_dic_sync_cfg
where (schema_name,table_name,nvl(partition_name,'0')) in 
       (select schema_name||'.'||table_name||'.'||nvl(partition_name,'0')
	      from (select schema_name,
	           table_name,
			   partition_name,
			   status,
			   error_desc,
			   date_1
		  from dwmigimp.tb_sync_log a 
		 where status=3 
		 and   error_desc like '%ORA-00913%%')
	  );
commit;	  



-----------------------------------------------------------------


--12.元数据更改完成，更改status=0,unique_no 设为 null 重新跑数据
update dwmigimp.tb_dic_sync_cfg
  set status=0,unique_no=null
 where status=3;
 
 commit;
 
 

-------------------------------------------------------------------

--13.数据稽核完成，对配置表进行更新，数据重导
update dwmigimp.tb_dic_sync_cfg
  set status=0,unique_no=null,count_1=0
 where (schema_name,table_name,nvl(partition_name,'0') in
       (select owner,table_name,nvl(partition_name,'0')
	       from dwmigimp.tb_dic_sync_again
		   where remark='数据不一致'
	    ) ;
commit;

--update 完成后即可清除稽核有问题的表，方便下次插入次配置表
delete from dwmigimp.tb_dic_sync_again 
  where remark='数据不一致';
 commit;
 
 
 
--------------------------------------------------------------------

--14.查询日志表status=3的error描述
select distinct substr(error_desc,0,35)
  from dwmigimp.tb_sync_log
  where status=3;
  
--列举
--ORA-12801:并行查询服务器中发出错误信号
--ORA-01438:number类型精度不匹配
--ORA-02149:分区不存在
--ORA-12827:可用并行查询不足
--ORA-06535:EXCUTE IMMEDIATE IS NULL OR 0 length
--ORA-04021:等待对象锁超时
--ORA-00947:没有足够的值（字段数问题，表结构变更）
--ORA-00913:字段数不一致
--ORA-14251:子分区不存在
--ORA-02049:分布式事务处理等待锁
--ORA-00942:表或视图不存在
--ORA-00997:不合法long类型
--------------------------------20191126----------------------------
--ORA-00913: too many values%                                                       --归类为字段修改或类型修改
--ORA-00942：table or view does not exists%                                         --表不存在
--ORA-12801:                                                                        --并行不足
--ORA-14251: Specifield subpartition does not exists%                               --子分区不存在
--ORA-02049：Specifiled partition does not exists%                                  --分区不存在
--ORA-12899: value too large for column%                                            --归类为字段修改或类型修改
--ORA-01722：invalid number%                                                        --归类为字段修改或类型修改
--ORA-00932：inconsistent datatype:expect DATE got NUMBER%                          --归类为字段修改或类型修改
--ORA-01438: value large than specifield precision allowed for this column          --归类为字段修改或类型修改
--ORA-01688：unable to extent%                                                      --表空间满了
--ORA-03233: unable to extent table%                                                --表空间满了
--ORA-00997：illegal use of LONG datatype%                                          --表中含有long字段，不能用DB_LINK同步，只能用调度
--ORA-12805：parallel query server died unexpectediy%                               --并行意外终止
--ORA-03150: end-of-file on communication channel for database link%                --DB_LINK连接不上，因为数据库暂时重启了
--ORA-12541：TNS：no listener%                                                      --数据库监听未启，因为书库刚重启
--ORA-00947: enough values%                                                         --归类为字段修改或类型修改
--ORA-08103：object no longer exists%                                               --对象不存在、
--ORA-00054: reource busy and acquire with NOWAIT specifield or timeout expired%    --资源忙
--ORA-24801: illegal parameter value in OCI lob function 





----------------------------------------------------------------------------

--15.查看过程哪个环节跑得慢
select date_1,
       a.unique_no,
	   a.schema_name,
	   a.table_name,
	   a.partition_name,
	   a.status,
	   a.des_count,
	   b.p_bytes,
	   error_desc,
	   round((a.date_2-a.date_1)*24*60,2) uuid,
	   round((a.date_3-a.date_2)*24*60,2) uuid查询,
	   round((a.begin_date-a.date_3)*24*60,2) 清数据,
	   round((a.begin_date-a.end_date)*24*60,2) 同步数据,
	   round((a.date_4-a.end_date)*24*60,2) 更新配置表
  from dwmigimp.tb_sync_log a,
       dwmigimp.tb_dic_sync_cfg b
  where a.schema_name=b.schema_name
  and   a.table_name=b.table_name
  and   nvl(a.partition_name,'0')=nvl(b.partition_name,'0')
  and   date_1 is not null
  and   a.status=1
  and   to_char(a.date_1)='02-12月-19'
  and   to_char(a.dtaae_1,'yyyy-mm-dd hh24:mi:ss')>'2019-12-02 08:00:00'
  order by round((a.begin_date-a.end_date)*24*60,2) desc;
  
  
  
  
  
-------------------------------------------------------------------------------

--16.查看每天同步数据
select sum(bytes)/1024/1024/1024/1024 T ,sysdate
  from dba_segments;
  
  
  
  
  
-------------------------------------------------------------------------------

--17.元数据稽核完成，涉及字段变更的，表删除重建
--首先删除配置表中的相关记录
delete from dwmigimp.tb_dic_sync_cfg
 where (schema_name,table_name) in 
       (select owner,table_name
	      from dwmigimp.tb_re_create_tab_list
		);
commit;

--在更新维表
update dwmigexp.tb_dic_dba_segments@to_old_a
  set unique_id=null 
 where (owner,segment_name) in
       (select owner,table_name 
	      from dwmigimp.tb_re_create_tab_list
		);
commit;


--查看重建表，有没有调度同步的表，若有调度重跑
select * from dwmigimp.tb_dic_qianyi_tab
 where sync_flag='Y'
 and   trim(sync_way)='调度'
 and   owner||'.'||table_name in 
       (select owner||'.'||table_name 
	      from dwmigimp.tb_re_create_tab_list
		  )
		  
		  
--清除重建配置表
truncate table dwmigimp.tb_re_create_tab_list;





----------------------------------------------------------------------------------------

--18.表字段变更单个表处理
--首先删除配置表中的相关记录
delete from dwmigimp.tb_dic_sync_cfg
 where schema_name=''
 and   table_name='';
 
 commit;
 
--在update维表
--从跑生成配置表的调度
update dwmigexp.tb_dic_dba_segments@to_old_a
  set unique_id=null
  where owner=''
  and   segment_name='';
  
  commit;
  
  
  
  
  
------------------------------------------------------------------------------------------

--19.只涉及数据重导，不涉及字段修改
update dwmigimp.tb_dic_sync_cfg
  set unique_no=null,status=0
  where schema_name=''
  and   table_name=''
  and   partition_name like '%%';
  
  commit;

  
  
  
  
-------------------------------------------------------------------------------------------

--20.停止调度方法
--（直接停调度，但库中会话还在继续执行）
--把配置表状态改为5，获取不到即可

update dwmigimp.tb_dic_sync_cfg
  set status=5
  where unique_no is null;
commit;

--把配置表状态改回来，改成0，重跑调度
update dwmigimp.tb_dic_sync_cfg
  set status=0
  where status=5;
  commit;
  
  
  
  
  
---------------------------------------------------------------------------------------------

--21.老A库需要同步的数据量
select /*+parallel(a,8)*/
       round(sum(bytes/1024/1024/1024/1024),3) T ,sysdate
  from dba_segments@to_old_a a,
       dwmigimp.tb_dic_qianyi_tab b
 where a.owner=b.owner
 and   a.segment_name=b.table_name
 and   a.sync_flag='Y'
 
 
 
 
 --新库已同步数据量
 select /*+parallel(a,8)*/
       round(sum(bytes/1024/1024/1024/1024),3) T ,sysdate
  from dba_segments a,
       dwmigimp.tb_dic_qianyi_tab b
 where a.owner=b.owner
 and   a.segment_name=b.table_name
 and   a.sync_flag='Y'
 
 
 
 
---------------------------------------------------------------------------------------------

--22.割接当天需要同步数据量
--single_size 表示单周期大小（也就是一天的数据量，不是单个子分区量）
select trim(a.partition_type),
       trim(a.partition_subtype),
	   round(sum(a.single_size_m)/1024/1024,3) TB
  from dwmigimp.tb_dic_qianyi_tab a
 where trim(a.load_period)='D'
 and   trim(a.sync_flag)='Y'
 group by trim(a.partition_type),trim(a.partition_subtype)
 
 
 
 
 
 
----------------------------------------------------------------------------------------------

--23.查看日志出错
select max(b.date_1),
       a.schema_name,
	   a.table_name,
	   a.view_name,
	   a.partition_name,
	   max(b.error_desc),
	   a.segment_tp,
	   a.p_bytes
  from dwmigimp.tb_dic_sync_cfg a,
       dwmigimp.tb_sync_log b 
 where a.schema_name=b.schema_name
 and   a.table_name=b.table_name
 and   nvl(a.partition_name,'0')=nvl(b.partition_name,'0')
 and   a.status=3 
 and   to_char(date_1)='10-12月-19'
 and   b.error_desc is not null
 group by a.schema_name,
          a.table_name,
		  a.view_name,
		  a.partition_name,
		  a.segment_tp,
		  a.p_bytes
 order by 1,2,3;
		  
		  
------------------------------------------------------------------------

--24.调度同步的表，同步量
select sum(bytes/1024/1024/1024/1024) T 
  from dba_segments@to_old_a a,
       dwmigimp.tb_dic_qianyi_tab b 
  where a.owner=b.owner
  and   a.segment_name=b.table_name
  and   b.sync_flag='Y'
  and   trim(b.sync_way)='调度'
  ;
  
  
  
-------------------------------------------------------------------------

--25.查看迁移会话dwmigimp
select gse.inst_id,
       --gse.sid,
	   --gse.serial#,
	   pro.spid,
	   pro.sql_text,
	   --'alter system kill session '||''''||gse.sid||'.'||gse.serial#||''''||';'
	   'kill -9 '||pro.spid
  from gv$session gse,
       gv$sql gsql,
	   gv$process pro
where gse.inst_id=gsql.inst_id
and   gse.sql_id=gsql.sql_id
and   pro.addr=gse.paddr
and   pro.inst_id=gse.inst_id
and   schemaname like '%DWMIGIMP%'
and   sql_text like 'insert /*+parallel%'
--and  gse.inst_id='6'
  

  
-------------------------------------------------------------------------

--26.查看新老库当前连接数
select inst_id,count(1)
  from gv$process@to_old_a
  group by inst_id;
  
select inst_id,count(1)
  from gv$process
  group by inst_id;
  
  
--查看新老库最大连接数
select value 
  from gv$parameter@to_old_a
  where name='processes';
  
select value 
  from gv$parameter
  where name='processes';
  

  