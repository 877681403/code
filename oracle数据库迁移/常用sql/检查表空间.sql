select t.tablespace_name "��ռ�����",
       t.total_space "�ܿռ��С",
       t.total_space-nvl(f.free_space,'0') "��ʹ�ÿռ��С",
       nvl(f.free_space,'0') "ʣ��ռ��С",
       round((f.free_space / t.total_space) * 100) || '%' "ʣ��"
  from
   (select tablespace_name,
           round(sum(bytes)/1024/1024) free_space
      from dba_free_space
     group by tablespace_name)f,
   (select tablespace_name,
           round(sum(bytes)/1024/1024) total_space
      from dba_data_files
     group by  tablespace_name)t
 where f.tablespace_name(+)=t.tablespace_name
 order by round((nvl(f.free_space,'0') / t.total_space) * 100);