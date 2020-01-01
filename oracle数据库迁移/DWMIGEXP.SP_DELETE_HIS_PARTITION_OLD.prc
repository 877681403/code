CREATE OR REPLACE PROCEDURE DWMIGEXP.SP_DELETE_HIS_PARTITION_OLD(oi_return out integer)

/** head 
*@name SP_DELETE_HIS_PARTITION_OLD
*@parameter oi_return:返回值  执行状态码， 0正常，其他 出错
*结果表：
*/

is
 
  vi_task_id integer; --任务日志
  vi_task_name varchar2(50);--任务名
  vi_task_pos  varchar2(50);--任务位置
  vi_err_code integer ;--出错代码
  vv_err_msg  varchar2(300);--出错信息
  exc_return exception; --程序中间返回自定义异常
  exc_error  exception; --程序出错返回自定义异常
  
  

begin
  
   --删除维表中老库已经删除的分区，和老库分区控制保持一致
   delete from dwmigexp.tb_dic_dba_segments a
     where not exists 
	  (select 1 from dba_segments t 
	     where t.owner=a.owner
		 and   t.segment_name=a.segment_name
		 and   nvl(t.partition_name,'0')=nvl(a.partition_name,'0')
	 );
	 commit;
     
   --删除配置表中维表中已经删除的分区，和维表保持一致
   delete from dwmigimp.tb_dic_sync_cfg@to_new_a b
     where not exists 
	   (select 1 from dwmigexp.tb_dic_dba_segments c 
	      where c.owner=b.owner
		  and   c.segment_name=b.table_name
		  and   nvl(c.partition_name,'0')=nvl(b.partition_name,'0')
	   );
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