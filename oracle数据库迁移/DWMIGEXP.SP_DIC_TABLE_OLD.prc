CREATE OR REPLACE PROCEDURE DWMIGEXP.SP_DIC_TABLE_OLD(oi_return out integer)

/** head 
*@name SP_DIC_TABLE_OLD
*@parameter oi_return:����ֵ  ִ��״̬�룬 0���������� ����
*�����
*Ǩ�Ʒ�Χ�������˺�MASA%��ͷ���ų���ʱ�����඼Ǩ�ƣ�
*/

is
 
  vi_task_id integer; --������־
  vi_task_name varchar2(50);--������
  vi_task_pos  varchar2(50);--����λ��
  vi_err_code integer ;--�������
  vv_err_msg  varchar2(300);--������Ϣ
  exc_return exception; --�����м䷵���Զ����쳣
  exc_error  exception; --����������Զ����쳣
  user_number number;--�û���Ŀ
  uuid varchar2(128);--Ψһ��
  v_view varchar2(30);--��ͼ
  v_create    varchar2(4000);
  

begin
  
  --���users�û��嵥
  select count(1) into user_number from dwimgimp.tb_dic_qianyi_users@to_new_a;
  
  --��Ŀ������ֱ���˳��洢����
  if user_number <>22 then
     vv_err_msg :='�û��嵥��Ŀ����';
	 dbms_output.put_line(vv_err_msg);
	 oi_return:=999;
	 return;
  end if;
  
  --ÿ�θ���ά��priority����+1����������������Щ������ķ�������ȡ����ķ�������ͬ��
  
  --����ϵͳά��
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
	 
	 --��һ������tb_dic_dba_segmentsʱ������������ݣ�
	 --select max(nvl(priority,0))+1 from dwmigexp.tb_dic_dba_segments ��ֵ���ǿգ�
	 --�����ڵ�һ�β��ȥ���ݣ�����һ�����ȼ�Ϊ�յ����ݾ��У�
	 --ֻҪά������һ�����ݣ��Ժ�����ȼ���������1
	 update dwmigexp.tb_dic_dba_segments
	   set priority=1
	   where priority is null;
	 
	 commit;
	 
	 oi_return:=0;
	 
 exception
   
   when exc_return then 
       /**@description �����м䷵�أ���¼���������־����������
	   *@call masamk#sp_mk_sys_log
	   *@field-mapping oi_return=(0)
	   */
       
	   /**masakr#sp_kr_sys_log(vi_task_id,null,null,null,0,null,vi_task_pos,vi_result)
	   */
       oi_return:=0;
   
   when exc_error then 
       
       /*
	   *���ﶼ���Զ����쳣�������Ҳ��
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