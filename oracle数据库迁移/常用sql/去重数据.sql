--去重数据
delete from masadata.t_oracle_table_info a 
where (a.table_schema,a.table_name,a.column_name) in 
(select table_schema,table_name,column_name
   from masadata.t_oracle_table_info
   group by table_schema,table_name,column_name
   having count(*)>1)
and rowid not in (select min(rowid)
                   from masadata.t_oracle_table_info 
                   group by table_schema,table_name,column_name
                   having count(*)>1
                   );