CREATE OR REPLACE PROCEDURE DWMIGEXP.SP_DIC_CONFI_OLD(oi_return out integer)

/** head 
*@name SP_DIC_CONFI_OLD
*@parameter oi_return:返回值  执行状态码， 0正常，其他 出错
*结果表：
*/

is
  
/*
*@description 变量定义
*@variable-define vi_task_id integer 任务日志ID
*@variable-define vi_task_name varchar2 任务名
*@variable-define vi_table_name varchar2 表名
*@variable-define vi_task_pos varchar2 任务位置
*@variable-define vi_err_code integer 出错代码
*@variable-define vi_err_msg varchar2 出错信息
*@variable-define vi_month  varchar2 整数类型的统计月份
*@variable-define vi_result integer 临时结果
*@variable-define exc_return expection 程序中间返回自定义异常
*@variable-define exc_error exception 程序出错返回自定义异常
*/  
  vi_task_id integer; --任务日志
  vi_task_name varchar2(50);--任务名
  vi_task_pos  varchar2(50);--任务位置
  vi_err_code integer ;--出错代码
  vi_err_msg  varchar2(300);--出错信息
  exc_return exception; --程序中间返回自定义异常
  exc_error  exception; --程序出错返回自定义异常
  user_number number;--用户数目
  uuid varchar2(128);--唯一数
  v_view varchar2(30);--视图
  v_create    varchar2(4000);
  v_count1 number;
  v_owner varchar2(50);
  v_segment_name varchar2(50);
  v_partition_name varchar2(50);
  v_tablespace_name varchar2(50);
  v_segment_type varchar2(50);
  v_bytes varchar2(50);
  v_priority number;   --优先级
  

begin
  
  vi_task_name :='';
  vi_task_pos :='程序开始';
  
  loop
    begin
	  vi_task_pos:='循环中根据UUID更新维表';
	  uuid:=sys_guid();
	  update dwmigexp.tb_dic_dba_segments
	    set unique_id=uuid
		where unique_id is null
		and   rownum<2;
	  v_count1:=sql%rowcount;
	  commit;
	  
	  --判断是否取到数，没有则退出程序
	  if v_count1=0 then
	     exit;
	  end if;
	  
	  vi_task_pos:='根据UUID反向查询一条记录';
	  select owner,
	         segment_name,
			 partition_name,
			 tablespace_name,
			 segment_type,
			 bytes,
			 priority
		into v_owner,
		     v_segment_name,
			 v_partition_name,
			 v_tablespace_name,
			 v_segment_type,
			 v_bytes,
			 v_priority
		from dwmigexp.tb_dic_dba_segments
		where unique_id=uuid;
		
	  vi_task_pos:='生成视图';
      select 'view_a_'||dwmigexp.seq_view.nextval into v_view from dual;
      
	  vi_task_pos:='创建视图';
      if v_segment_type='TABLE PARTITION' then
         v_create:='create view '||v_view||
		           ' as select * from '||v_owner||'.'||v_segment_name||
                   ' partition ('||v_partition_name||')';
         execute immediate v_create;
      elsif v_segment_type='TABLE SUBPARTITION' then 
         v_create:='create view '||v_view||
		           ' as select * from '||v_owner||'.'||v_segment_name||
                   ' subpartition ('||v_partition_name||')';
         execute immediate v_create;
      elsif v_segment_type='TABLE'	then
         v_view:=null;
      end if;
      
      vi_task_pos:='生成配置表';
      insert into dwmigimp.tb_dic_sync_cfg@to_new_a
        (
		 schema_name,
		 table_name,
		 view_name,
		 partition_name,
		 tablespace_name,
		 segment_tp,
		 status,
		 count_1,
		 p_bytes,
		 priority
		)	  
	  values(
	         v_owner,
			 v_segment_name,
			 v_view,
			 v_partition_name,
			 v_tablespace_name,
			 v_segment_type,
			 0,
			 0,
			 v_bytes/1024/1024,
			 v_priority
			 
	  );
	  commit;
	  
	exception
      when others then 
	    vi_err_msg:=substr(sqlerrm,1,200);
		--dbms_output.put_line(vi_task_pos||vi_err_msg);
		--循环内打印错误日志
		insert into dwmigexp.tb_dic_sync_cfg_err(
		  table_owner,
		  table_name,
		  partition_name,
		  deal_time,
		  position,
		  err_desc
		)
		values(
		  v_owner,
		  v_segment_name,
		  v_partition_name,
		  sysdate,
		  vi_task_pos,
		  vi_err_msg
		);
		commit;
		
	end;
  end loop;

   oi_return:=0;

 --循环外的异常处理   
 exception
   
   when exc_return then 
     /**@description 程序中间返回，记录程序结束日志，正常返回
     *@call masamk#sp_mk_sys_log
     *@field-mapping oi_return=(0)
     */
       
     /**masakr#sp_kr_sys_log(vi_task_id,null,null,null,0,null,vi_task_pos,vi_result)
     */
       oi_return:=0;
   
   when exc_error then 
       
       /*
     *这里都是自定义异常，上面的也是
     */
      oi_return:=vi_err_code;
   
   when others then 
     vi_err_code:=sqlcode;
	 vi_err_msg:=substr(sqlerrm,1,200);
	 insert into dwmigexp.tb_dic_err_desc(
	   err_pos,
	   err_desc
	 )
	 values(
	   vi_task_pos,
	   vi_err_msg
	 );
	 commit;
	 
	 rollback;
	 oi_return:=vi_err_code;
	 
end;
/