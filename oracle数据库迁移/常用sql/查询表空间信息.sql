
select a.a1 ��ռ�����,
       c.c2 ����,
       c.c3 ������,
       b.b2/1024/1024 ��ռ��СM,
      (b.b2-a.a2)/1024/1024 ��ʹ��M,
       a.a2/1024/1024 ʣ��M,
       substr((b.b2-a.a2) / b.b2 * 100,1,5) ������
  from (select tablespace_name a1,sum(nvl(bytes,0)) a2 from dba_free_space group by tablespace_name) a,
       (select tablespace_name b1,sum(bytes) b2 from dba_data_files group by tablespace_name) b,
       (select tablespace_name c1,contents c2,extent_management c3 from dba_tablespaces) c
   where a.a1=b.b1
   and   c.c1=b.b1
   order by 1;