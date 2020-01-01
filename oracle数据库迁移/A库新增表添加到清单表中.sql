

-----------------------------------更新完清单表，再去跑配置表-----------------------------
--配置表是关联清单表生成的，新增表不插入清单表，即使库中新建，配置表中也不会有，也不会同步



--1.先跑一下过程dwmigimp.tb_sys_mig_table.prc
--生成结果表dwmigimp.tb_sys_mig_tab_qianyi
--经常备份
create table dwmigimp.tb_sys_mig_tab_qianyi_20191202
as
select * from dwmigimp.tb_sys_mig_tab_qianyi



--2.筛选出来哪些表是提取清单后新增的
select a.*
  from dwmigimp.tb_sys_mig_tab_qianyi_20191202 a
 where a.owner||'.'||a.table_name not in 
       (select b.owner||'.'||b.table_name 
	      from dwmigimp.tb_sys_mig_tab_qianyi_20191123 b)
		  

		  
--3.删除max(),min(),count 的配置表
delete from dwmigimp.tb_statistics_table_info


--4.重新插入新增的
--获取字段带有（statis_date,deal_date,statis_month,statis_year）的表
--手动执行
insert into dwmigimp.tb_statistics_table_info
  select '',
         owner,
		 table_name,
		 column_name,
		 '',
		 '',
		 0,
		 '',
		 '',
		 '',
		 'Y',
		 '',
		 'N',
		 '',
		 '',
		 'N'
	from (select '',
	             c.owner,
				 c.table_name,
				 d.column_name,
				 row_num() over(partition by d.owner,d.table_name order by column_name) rn
			from (select a.*
			        from dwmigimp.tb_sys_mig_tab_qianyi_20191202 a
				   where a.owner||'.'||a.table_name not in 
				        (select b.owner||'.'||b.table_name
				            from dwmigimp.tb_sys_mig_tab_qianyi_20191123 b
						)
				 )c,
				 dba_tab_columns@to_old_a d 
		   where c.owner=d.owner
		   and   c.table_name=d.table_name
		   and   d.column_name in 
		         ('STATIS_DATE','DEAL_DATE','STATIS_MONTH','STATIS_YEAR')
		 )
	where rn=1;
		 
commit;


--插入不带周期字段的表
insert into dwmigimp.tb_statistics_table_info
  select '',
         owner,
		 table_name,
		 '',
		 '',
		 '',
		 0,
		 '',
		 '',
		 '',
		 'N',
		 '',
		 'N',
		 '',
		 '',
		 'N'
	from dwmigimp.tb_sys_mig_tab_qianyi_20191202 a
	where a.owner||'.'||a.table_name not in 
	      (select b.owner||'.'||b.table_name 
		     from dwmigimp.tb_sys_mig_tab_qianyi_20191123 b)
	and not exists(select 1 
	                 from dwmigimp.tb_statistics_table_info c
					 where a.owner=c.owner
					 and   a.table_name=c.name
				   )
		  );
commit;
		 

--更新分区表
update dwmigimp.tb_statistics_table_info c
  set c.part_flag='Y'
  where c.owner||'.'||c.name in 
        (select a.owner||'.'||a.table_name
		   from dba_tab_partitions@to_old_a a
		 );
commit;


--分区控制表汇总
drop table dwmigimp.tb_dic_tab_partition_mid


create table dwmigimp.tb_dic_tab_partition_mid
  as
	select owner,
		   table_name,
		   partition_name,
		   cur_partition_count+his_partition_count keep_partition_count,
		   last_day_type_id
	  from MASACB.TB_SYS_TAB_PARTITIONS@to_old_a
    union all
    select owner,
           table_name,
           partition_name,
           partition_count keep_partition_count,
           last_day_type_id
      from MASACH.TB_SYS_TAB_PARTITIONS@to_old_a
    union all 
    select owner,
	       table_name,
		   partition_name,
		   cur_partition_count+his_partition_count keep_partition_count,
		   last_day_type_id
	  from MASACS.TB_SYS_TAB_PARTITIONS@to_old_a
	union all
    select owner,
           table_name,
           partition_name,
           cur_partition_count+his_partition_count keep_partition_count,
           last_day_type_id
      from MASADW.TB_SYS_TAB_PARTITIONS@to_old_a
    union all
    select owner,
           table_name,
           partition_name,
           cur_partition_count+his_partition_count keep_partition_count,
           last_day_type_id
      from MASAKR.TB_SYS_TAB_PARTITIONS@to_old_a
    union all
    select owner,
           table_name,
           partition_name,
           cur_partition_count+his_partition_count keep_partition_count,
           last_day_type_id
      from MASAMK.TB_SYS_TAB_PARTITIONS@to_old_a
    union all 
    select owner,
           table_name,
           partition_name,
           cur_partition_count+his_partition_count keep_partition_count,
           last_day_type_id
      from MASAODS.TB_SYS_TAB_PARTITIONS@to_old_a
    union all
    select owner,
           table_name,
           partition_name,
           partition_count keep_partition_count,
           last_day_type_id
      from MASASE.TB_SYS_TAB_PARTITIONS@to_old_a
    union all
    select owner,
           table_name,
           partition_name,
           cur_partition_count+his_partition_count keep_partition_count,
           last_day_type_id
      from MASASK.TB_SYS_TAB_PARTITIONS@to_old_a
	union all
	 select owner,
           table_name,
           partition_name,
           cur_partition_count+his_partition_count keep_partition_count,
           last_day_type_id
      from MASATHP.TB_SYS_TAB_PARTITIONS@to_old_a
	union all
	select owner,
           table_name,
           partition_name,
           cur_partition_count+his_partition_count keep_partition_count,
           last_day_type_id
      from MASAFBI.TB_SYS_TAB_PARTITIONS@to_old_a ;
    	



