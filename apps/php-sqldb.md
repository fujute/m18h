Ref:
https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connect-query-php

1.Create App infra with database and storage account
* https://github.com/fujute/m18h/blob/master/sample.web.sql-18032019-e.ps1
* https://raw.githubusercontent.com/mspnp/reference-architectures/master/managed-web-app/basic-web-app/Paas-Basic/Templates/PaaS-Basic.json

2.Create table and insert sample data
https://docs.microsoft.com/en-us/sql/t-sql/lesson-1-creating-database-objects?view=sql-server-2017
```shell
CREATE TABLE dbo.Products  
   (ProductID int PRIMARY KEY NOT NULL,  
   ProductName varchar(25) NOT NULL,  
   Price money NULL,  
   ProductDescription text NULL)  
GO

-- INSERT sample data  
INSERT dbo.Products (ProductName, ProductID, Price, ProductDescription)  
    VALUES ('Speaker', 101, 200, 'Wifi Speaker')   
INSERT dbo.Products (ProductName, ProductID, Price, ProductDescription)  
    VALUES ('Headphones', 102, 300, 'ANC Wireless')   
INSERT dbo.Products (ProductName, ProductID, Price, ProductDescription)  
    VALUES ('Adapter', 103, 400, 'USB Type C Adapter')  
GO
```

3. connect simple PHP to Azure SQL Server 
* Ref: https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connect-query-php
```shell
<?php
    $serverName = "<<DBserver>>.database.windows.net,1433"; // update to the right one
    $connectionOptions = array(
        "Database" => "<<databasename>>", // update to the right one
        "Uid" => "<<username>>", // update to the right one
        "PWD" => "<<password>>" // update to the right one
    );
    //Establishes the connection
    $conn = sqlsrv_connect($serverName, $connectionOptions);
    $tsql= "SELECT ProductName,Price from dbo.Products";
    $getResults= sqlsrv_query($conn, $tsql);
    echo ("Reading database name" . PHP_EOL);
    if ($getResults == FALSE)
        echo (sqlsrv_errors());
    while ($row = sqlsrv_fetch_array($getResults, SQLSRV_FETCH_ASSOC)) {
     echo ($row['ProductName'] . " " . $row['Price'] . PHP_EOL);
    }
    sqlsrv_free_stmt($getResults);
?>
```
