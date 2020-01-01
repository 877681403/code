

----------割接当天需要同步的数据类型

--1.日数据（每天都在同步的）
--跑完配置表，直接跑调度


--2.月表日数据（割接当天需要同步一把）
--更新完月分区日增量，在启动调度
update dwmigimp.tb_dic_sync_cfg b
  set unique_no=null,status=0
  where exists(select 1 
                 from (select a.owner,
				              a.table_name,
							  a.cycle_column
					     from dwmigimp.tb_dic_qianyi_tab a
						 where trim(a.sync_flag)='Y'
						 and   trim(a.partition_type)='月分区表'
						 and   trim(a.partition_subtype)='日增量'
				       )t 
                 where t.owner=b.schema_name
				 and   t.table_name=b.table_name
               )
  and  b.partition_name like '%201912%';
  
  commit;
  
  
  
--3.年表日数据(割接当天需要同步一把)
--更新完年分区日增量，在启动调度
update dwmigimp.tb_dic_sync_cfg  b 
  set  unique_no=null,status=0
  where exists(select 1
                 from (select a.owner,
				              a.table_name,
							  a,cycle_column
					     from dwmigimp.tb_dic_qianyi_tab a
						 where trim(a.sync_flag)='Y'
						 and   trim(a.partition_type)='年分区表'
						 and   trim(a.partition_subtype)='日增量'
					  )t
				 where t.owner=b.schema_name
				 and   t.table_name=b.table_name
			   )
  and b.partition_name like '%2019%';
  
  commit;


  
--4.年表月数据（割接当天在同步一把）
--更新完年分区月增量，在启动调度
update dwmigimp.tb_dic_sync_cfg b
  set unique_no=null.status=0
  where exists(select 1
                 from (select a.owner,
				              a,table_name,
							  a.cycle_column
					     from dwmigimp.tb_dic_qianyi_tab a 
						where  trim(a.sync_flag)='Y'
						 and   trim(a.partition_type)='年分区表'
						 and   trim(a.partition_subtype)='月增量'
					  )t
				where t.owner=b.schema_name
				 and   t.table_name=b.table_name
			   )
  and b.partition_name like '%2019%';
  
  commit;

  
  
  
  --特殊分区（割接当天要同步一把）
  update dwmigimp.tb_dic_sync_cfg b
     set unique_no=null,status=0
	 where exists(select 1
	                 from (select a.owner,
					              a.table_name
						     from dwmigimp.tb_dic_qianyi_tab a
							 where trim(a.partition_type)='特殊分区'
							 and   trim(a.sync_flag)='Y'
							 )t
				   where t.owner=b.schema_name
				    and  t.table_name=b.table_name
				 );
    commit;
	
	
	
--非分区表（不包含临时表）
update dwmigimp.tb_dic_sync_cfg b
  set unique_no=null,status=0
  where b.segment_tp='TABLE'
  and   exists(select 1 
                 from (select a.owner,
				              a.table_name
						 from dwmigimp.tb_dic_qianyi_tab a
						 where trim(a.sync_flag)='Y'
						 and   trim(a.partition_type)='非分区'
						 and   trim(a.partition_subtype)='非分区表'
						 and   trim(a.sync_way)='DB_LINK'
						 )t 
                   where t.owner=b.schema_name
				    and  t.table_name=b.table_name
				 );
    commit;

  
  
  
  
  
  
  
  