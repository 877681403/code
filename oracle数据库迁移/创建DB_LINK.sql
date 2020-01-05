

	
--创建B库指向新A库的BD_LINK
create public database link to_new_a
  connect to dwmigimp identified by "3edc#EDC"
  using'(DESCRIPTION=
        (ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.66)(PORT=1521)))
        (LOAD_BALANCE==yes)
		(CONNECT_DATA=(SERVICE_NAME=ngdwa))
        )';

		


--创建老A库指向新A库的DB_LINK
create public database link to_new_a
  connect to dwmigimp identified by "3edc#EDC"
  using'(DESCRIPTION=
        (ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.66)(PORT=1521)))
        (LOAD_BALANCE==yes)
		(CONNECT_DATA=(SERVICE_NAME=ngdwa))
        )';
--drop public database link to_new_a;



--创建老A库指向新A库的DB_LINK(第二个)
create public database link to_new_a
  connect to dwmigimp identified by "3edc#EDC"
  using'(DESCRIPTION=
        (ADDRESS_LIST=
		             (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.215)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.216)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.218)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.219)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.143)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.144)(PORT=1521))
		)
        (LOAD_BALANCE=yes)
		(CONNECT_DATA=(SERVICE_NAME=ngdwa))
		)';
		
		
		
--创建新A库指向B库的DNB_LINK
create public database link to_old_b
  connect to dwmigexp identified by "VWjp1$Pnj"
  using'(DESCRIPTION=
        (ADDRESS_LIST=
		              (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.220)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.221)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.222)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.223)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.224)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.225)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.226)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.227)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.228)(PORT=1521))
					  (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.229)(PORT=1521))
		)
        (LOAD_BALANCE=yes)
		(CONNECT_DATA=(SERVICE_NAME=ngdwb))        
        )';
		
		
		
		
--创建新A库指向老A库的DB_LINK
create public database link to_old_a
  connect to dwmigexp identified by "3edc#EDC"
  using'(DESCRIPTION=
        (ADDRESS_LIST=
		             (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.70)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.71)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.72)(PORT=1521))
					 (ADDRESS=(PROTOCOL=TCP)(HOST=10.97.186.73)(PORT=1521))
		)
        (LOAD_BALANCE=yes)
		(CONNECT_DATA=(SERVICE_NAME=ngdwa))
		)';
		
		
	
--创建本地库库指向新远端（张育珲）库的BD_LINK
create public database link qianyi
  connect to LXN identified by "oracle"
  using'(DESCRIPTION=
        (ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=62.234.148.85)(PORT=1521)))
        (LOAD_BALANCE==yes)
    (CONNECT_DATA=(SERVICE_NAME=XE))
        )';






		
		