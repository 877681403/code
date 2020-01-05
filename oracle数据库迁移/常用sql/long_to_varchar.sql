--创建函数时，还需要显示授权，grant select any dictionary to liuxiangnan;
create or replace function long_to_varchar
(
iv_table_owner in varchar,
iv_table_name in varchar,
iv_table_partition in varchar
)
return varchar
as

    vv_high_value varchar2(4000);
begin 
   select high_value
     into vv_high_value
     from dba_tab_partitions
 where table_owner=iv_table_owner
   and   table_name=iv_table_name
   and   partition_name=iv_table_partition;
  return vv_high_value;
end;