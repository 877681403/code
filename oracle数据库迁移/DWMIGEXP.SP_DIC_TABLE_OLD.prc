CREATE OR REPLACE PROCEDURE DWMIGEXP.SP_DIC_TABLE_OLD(oi_return out integer)

/** head 
*@name SP_DIC_TABLE_OLD
*@parameter oi_return:返回值  执行状态码， 0正常，其他 出错
*结果表：
*迁移范围（程序账号MASA%开头，排除临时表，其余都迁移）
*/

is
 
  vi_task_id integer; --任务日志
  vi_task_name varchar2(50);--任务名
  vi_task_pos  varchar2(50);--任务位置
  vi_err_code integer ;--出错代码
  vv_err_msg  varchar2(300);--出错信息
  exc_return exception; --程序中间返回自定义异常
  exc_error  exception; --程序出错返回自定义异常
  user_number number;--用户数目
  uuid varchar2(128);--唯一数
  v_view varchar2(30);--视图
  v_create    varchar2(4000);
  

begin
  
  --检查users用户清单
  select count(1) into user_number from dwimgimp.tb_dic_qianyi_users@to_new_a;
  
  --数目有误，则直接退出存储过程
  if user_number <>22 then
     vv_err_msg :='用户清单数目有误';
	 dbms_output.put_line(vv_err_msg);
	 oi_return:=999;
	 return;
  end if;
  
  --每次更新维表，priority都会+1，这样就能区分哪些是最近的分区，先取最近的分区进行同步
  
  --生成系统维表
  insert into dwimgexp.tb_dic_dba_segments(
   owner,
   segment_name,
   partition_name,
   tablespace_name,
   bytes,
   priority
  )
  select a.owner,
         a.segment_name,
		 a.partition_name,
		 a.segment_type,
		 a.bytes,
		 (select max(nvl(priority,0))+1 from dwmigexp.tb_dic_dba_segments) v_priority
    from sys.dba_segments a,
	     dwmigimp.tb_dic_qianyi_tab@to_new_a t1
     where a.owner in (select * from dwmigimp.tb_dic_qianyi_users@to_new_a)
	 and   a.segment_name =trim(t1.table_name)
	 and   trim(t1.sync_flag)='Y'
	 and   trim(t1.sync_way)='DB_LINK'
	 ;
	 commit;
	 
	 --第一次生成tb_dic_dba_segments时，因表中无数据，
	 --select max(nvl(priority,0))+1 from dwmigexp.tb_dic_dba_segments 的值还是空，
	 --所以在第一次插进去数据，更新一下优先级为空的数据就行，
	 --只要维表中有一条数据，以后的优先级都会自增1
	 update dwmigexp.tb_dic_dba_segments
	   set priority=1
	   where priority is null;
	 
	 commit;
	 
	 oi_return:=0;
	 
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
   when other then 
       vi_err_code:=sqlcode;
	   vv_err_msg:=substr(sqlerrm,1,200);
	   rollback;
	   
	   /**masakr#sp_kr_sys_log(vi_task_id,null,null,null,0,null,vi_task_pos,vi_result)
	   */
	   
	   oi_return:=vi_err_code;
	
end;
/