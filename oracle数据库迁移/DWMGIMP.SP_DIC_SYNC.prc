CREATE OR REPLACE PROCEDURE DWMGIMP.SP_DIC_SYNC
(VI_PARTITION_TAB  IN VARCHAR,
 VI_PARTITION_TYPE IN VARCHAR,
 VI_PARTITION_SUB_TYPE IN VARCHAR,
 OI_RETURN OUT INTEGER 
)
/*
*@name SP_DIC_SYNC
*@parameter vi_partition_tab              是否是分区表（Y是、N否）
*@parameter vi_partition_type             分区类型（日分区表、月分区表、年分区表、特殊分区、非分区）
*@parameter vi_partition_sub_type         分区子类型（日增量、月增量、年增量、非分区、特殊分区）
*@parameter oi_return                     返回值  执行状态码： 0正常 其他 出错
*auther 刘向南
*/

is 

/*
*@description 变量定义
*@variable-define vi_task_id   integer   任务日志ID
*@variable-define vi_task_name varchar2  任务名
*@variable-define v_table_name varchar2  表名
*@variable-define vi_task_pos  varchar2  任务位置
*@variable-define vi_err_code  integer   错误代码
*@variable-define vi_err_msg   varchar2  错误信息
*@variable-define exc_return   exception 程序中间返回自定义异常
*@variable-define exc_error    exception 程序出错返回自定义异常
*/

vi_task_id       integer;              --任务日志ID
vi_task_name　   varchar2(30);         --任务名
vi_task_pos      varchar2(50);         --任务位置
vi_err_code      integer;              --出错代码
vi_err_msg       varchar2(200);        --出错信息
exc_return       exception;            --程序中间返回自定义异常
exc_error        exception;            --程序出错返回自定义异常
user_number      number;               --用户数目
uuid             varchar2(128);        --唯一数
view_name        varchar2(30);         --视图
v_count          number;
v_unique_no      varchar2(128);   
v_schema_name    varchar2(30);
v_table_name     varchar2(40);
v_view_name      varchar2(30);
v_partition_name varchar2(40);
v_insert         varchar2(4000);
v_data_count     number;
v_trun_p         varchar2(4000);
v_check          varchar2(1024);
v_data_count_old varchar2(1024);
v_begin_date     date;
v_end_date       date;
v_status         number;
v_segment_type   varchar2(30);
v_bytes          number;
v_count4         number;
v_count_1        number;
v_date_1         date;
v_date_2         date;
v_date_3         date;
v_date_4         date;
v_segment_tp     varchar2(300);


begin

	--grant select any table to dwmigimp;
	--grant delete any table to dwmigimp;
	--grant insert any table to dwmigimp;
	--grant drop any table to dwmigimp;
	--grant alter any table to dwmigimp;

	--打开并行
	excute immediate 'alter session enable parallel dml';

	/*
	*@description 变量初始化
	*/

	vi_task_name :='';
	vi_task_pos:='程序开始';

	v_count_1:=0;
	if vi_partition_tab='N' then 
	   v_segment_tp:='%TABLE';
	else 
	   v_segment_tp:='%PARTITION';   
	end if;



	loop
		 
	  begin
		
		vi_task_pos:='变量初始化';
		v_unique_no:=null;
		v_schema_name:=null;
		v_table_name:=null;
		v_view_name:=null;
		v_partition_name:=null;
		v_segment_type:=null;
		v_bytes:=0;
		
		select sysdate into v_date_1 from dual;
		
		--根据配置表status不是1或3进行循环跑
		--用于uuid更新一条记录，然后用uuid反向查询防止抢占资源
		
		vi_task_pos:='uuid更新一条记录';
		
		uuid:=sys_guid();
		update dwmigimp.tb_dic_sync_cfg b 
		  set  unique_no=uuid
		 where 
		  exists(select a.owner,
						a.table_name
				   from dwmigimp.tb_dic_qianyi_tab a 
				where trim(a.owner)=b.schema_name
				and   trim(a.table_name)=b.table_name
				and   trim(a.partition_tab)=vi_partition_tab
				and   trim(a.partition_type)=vi_partition_type
				and   trim(a.partition_subtype)=vi_partition_sub_type
				and   trim(a.sync_way)='DB_LINK'
				and   trim(a.sync_flag)='Y'
		  )
		  and  trim(b.priority)=(select max(d.priority)
								   from dwmigimp.tb_dic_sync_cfg d,
										dwmigimp.tb_dic_qianyi_tab from
								  where d.schema_name=trim(f.owner)
								  and   d.table_name=trim(f.table_name)
								  and   trim(f.partition_tab)=vi_partition_tab
								  and   trim(f.partition_type)=vi_partition_type
								  and   trim(f.partition_subtype)=vi_partition_sub_type
								  and   d.unique_no is null
								  and   d.status=0
								  and   d.segment_tp like v_segment_tp							  
		  )--优先取最近分区
		  and unique_no is null
		  and status=0
		  and rownum<2;
		 
		 v_count4:=sql%rowcount;
		 commit;
		 
		 if v_count4=0 then
			exit;
		 end if;
		 
		 select sysdate into date_2 from dual;
		 
		 vi_task_pos:='根据uuid查询一条记录';
		 select unique_no,
				schema_name,
				table_name,
				view_name,
				partition_name,
				segment_tp,
				p_bytes,
				count_1
		   into v_unique_no,
				v_schema_name,
				v_table_name,
				v_view_name,
				v_partition_name,
				v_segment_tp,
				v_bytes,
				v_count_1
		   from dwmigimp.tb_dic_sync_cfg
		  where unique_no=uuid;
		  
		 select sysdate into date_3 from dual;
		 
		 
		 vi_task_pos:='清除目标库数据对象';
		 if v_segment_type='TABLE' then 
			v_trun_p:='truncate table '||v_schema_name||'.'||v_table_name||'';
		 
		 elsif v_segment_type='TABLE PARTITION' then 
			v_trun_p:='alter table '||v_schema_name||'.'||v_table_name||' truncate partition '||v_partition_name||'';
		 
		 elsif v_segment_type='TABLE SUBPARTITION' then
			v_trun_p:='alter table '||v_schema_name||'.'||v_table_name||' truncate subpartition '||v_partition_name||'';	
		 end if;
		 excute immediate v_trun_p;

		 
		 vi_task_pos:='数据同步';
		 select sysdate into begin_date from dual;
		 
		 if v_bytes<512 then
			if v_segment_type='TABLE' then 
			   v_insert:='insert into '
						  ||v_schema_name||'.'||v_table_name||' b'
						  ||' select * from '||v_schema_name||'.'||v_table_name||'@to_old_a a';
						  
			elsif v_segment_type='TABLE PARTITION' then 
			   v_insert:='insert into '
						  ||v_schema_name||'.'||v_table_name||' partition('||v_partition_name||') b'
						  ||' select * from dwmigexp.'||v_view_name||'@to_old_a a';
						
			elsif v_segment_type='TABLE SUBPARTITION' then
				v_insert:='insert into '
						  ||v_schema_name||'.'||v_table_name||' subpartition('||v_partition_name||') b'
						  ||' select * from dwmigexp.'||v_view_name||'@to_old_a a';
						
			end if;
					
		 elsif v_bytes<1024 then
			if v_segment_type='TABLE' then 
			   v_insert:='insert  /*+parallel(b,4) append */ into '
						  ||v_schema_name||'.'||v_table_name||' b'
						  ||' select /*+parallel(a,4)*/* from  '||v_schema_name||'.'||v_table_name||'@to_old_a a';
			elsif v_segment_type='TABLE PARTITION' then 
			   v_insert:='insert /*+parallel(a,4) append */ into '
						  ||v_schema_name||'.'||v_table_name||' partition('||v_partition_name||') b'
						  ||' select /*+parallel(a,4)*/ * from dwmigexp.'||v_view_name||'@to_old_a a';
			elsif v_segment_type='TABLE SUBPARTITION' then
				v_insert:='insert /*+parallel(b,4) append */ into '
						  ||v_schema_name||'.'||v_table_name||' subpartition('||v_partition_name||') b'
						  ||' select /*+parallel(a,4)*/ * from dwmigexp.'||v_view_name||'@to_old_a a';
			end if;
			
		 else
			if v_segment_type='TABLE' then 
			   v_insert:='insert  /*+parallel(b,8) append */ into '
						  ||v_schema_name||'.'||v_table_name||' b'
						  ||' select /*+parallel(a,8)*/* from  '||v_schema_name||'.'||v_table_name||'@to_old_a a';
			elsif v_segment_type='TABLE PARTITION' then 
			   v_insert:='insert /*+parallel(a,8) append */ into '
						  ||v_schema_name||'.'||v_table_name||' partition('||v_partition_name||') b'
						  ||' select /*+parallel(a,8)*/ * from dwmigexp.'||v_view_name||'@to_old_a a';
			elsif v_segment_type='TABLE SUBPARTITION' then
				v_insert:='insert /*+parallel(b,8) append */ into '
						  ||v_schema_name||'.'||v_table_name||' subpartition('||v_partition_name||') b'
						  ||' select /*+parallel(a,8)*/ * from dwmigexp.'||v_view_name||'@to_old_a a';
			end if;
			
		 end if;
		 
		 excute immediate v_insert;
		 v_data_count:=sql%rowcount;
		 commit;
		 
		 select sysdate into v_end_date from dual;
		 
		 
		 
		 vi_task_pos:='跟新配置表';
		 update dwmigimp.tb_dic_sync_cfg
		   set status=1
		  where schema_name=v_schema_name
		  and   table_name=v_table_name
		  and   nvl(partition_name,'0')=nvl(v_partition_name,'0');
		 commit;
		 
		 select sysdate into v_date_4 from dual;
		 
		 
		 vi_task_pos:='写入同步日志';
		 insert into dwmigimp.tb_sync_log(
		   unique_no,
		   schema_name,
		   table_name,
		   partition_name,
		   date_1,
		   date_2,
		   date_3,
		   begin_date,
		   end_date,
		   --src_count,
		   des_count
		   --err_desc
		 )values(
		   v_unique_no,
		   v_schema_name,
		   v_table_name,
		   v_partition_name,
		   v_date_1,
		   v_date_2,
		   v_date_3,
		   v_begin_date,
		   v_end_date,
		   v_date_4,
		   1,
		   v_data_count	   
		 );
		 commit;
		 

	  exception  
		when other then 
		vi_task_pos:='循环内异常处理';
		vi_err_msg:=substr(sqlerrm,1,200);
		
		--异常报错更新配置表，不在循环处理报错的
		update dwmigimp.tb_dic_sync_cfg
		  set status=3
		 where schema_name=v_schema_name
		 and   table_name=v_table_name
		 and   nvl(partition_name,'0')=nvl(v_partition_name,'0');
		 commit;
		 
		 vi_task_pos:='更新日志表，记录异常信息';
		 insert into dwmigimp.tb_sync_log(
		   unique_no,
		   schema_name,
		   table_name,
		   partition_name,
		   date_1,
		   date_2,
		   date_3,
		   begin_date,
		   end_date,
		   date_4,
		   --src_count
		   des_count,
		   err_desc
		 )values(
		   v_unique_no,
		   v_schema_name,
		   v_table_name,
		   v_partition_name,
		   v_date_1,
		   v_date_2,
		   v_date_3,
		   v_begin_date,
		   v_end_date,
		   v_date_4,
		   3,
		   ---999,
		   -999,
		   vi_err_msg
		 );
		 commit;
		 
	  end;
	  
	end loop;


  oi_return:=0;
  
exception
  when exc_return then
	  /*
	  *@description 程序中间返回，记录程序结束日志，正常返回
	  *@call masamk#sp_mk_sys_log
	  *@field-mapping oi_return=0;
	  */
	  
	  /*
	  *masakr.--sp_kr_sys_log(vi_task_id,null,null,null,0,null,vi_task_pos,vi_result);
	  */
	  oi_return:=0;
	  
  when exc_error then 
	  oi_return:=vi_err_code;
  when other then
      vi_err_code:=sqlcode;
      vi_err_msg:=substr(sqlerrm,1,200);
      --dbms_output.put_line(vi_task_pos||vi_err_msg);
      insert into dwmigimp.tb_dic_sync_err
	  values(vi_task_pos,
	         v_schema_name,
			 v_table_name,
			 v_partition_name,
			 vi_err_msg
	        );
      commit;
      rollback;
      oi_return:=vi_err_code;
      	  
      excute immediate 'alter session disable parallel dml';	  

end;