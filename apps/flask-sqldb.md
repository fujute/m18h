# HOL

1.Create App infra with database and storage account
* https://github.com/fujute/m18h/blob/master/sample.web.sql-18032019-e.ps1
* https://raw.githubusercontent.com/mspnp/reference-architectures/master/managed-web-app/basic-web-app/Paas-Basic/Templates/PaaS-Basic.json

2.Create table and insert sample data
* ref: https://docs.microsoft.com/en-us/sql/t-sql/lesson-1-creating-database-objects?view=sql-server-2017
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

3. connect simple python/flask to Azure SQL Server 
* Ref: https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connect-query-python 
```shell
from datetime import datetime  
from flask  import render_template, redirect, request
from flask import Flask
app = Flask(__name__)

import pyodbc
server = '<server>.database.windows.net'
database = '<database>'
username = '<username>'
password = '<password>'

driver= '{ODBC Driver 17 for SQL Server}'
cnxn = pyodbc.connect('DRIVER='+driver+';SERVER='+server+';PORT=1433;DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()
cursor.execute("SELECT productname,price FROM products")

dataout=' '

row = cursor.fetchone()
while row:
    # print (str(row[0]) + " " + str(row[1]))
    dataout =  dataout + (str(row[0]) + " " + str(row[1])) +"</br>"
    row = cursor.fetchone()


@app.route("/")
def hello():
    return "Hello !! "

@app.route("/products")
def members():
    return "<html><body>"+ dataout + "</body></html>"

if __name__ == "__main__":
    app.run()

cnxn.close()  
```
requirements.txt
```shell
click==6.7
Flask==1.0.2
itsdangerous==0.24
Jinja2==2.10
MarkupSafe==1.0
Werkzeug==0.14.1
pyodbc==4.0.26
```
# See Also:
## SQL Server
* https://docs.microsoft.com/en-us/sql/connect/python/python-driver-for-sql-server?view=sql-server-2017
* https://www.microsoft.com/en-us/sql-server/developer-get-started/python/ubuntu
* https://pythonspot.com/flask-web-app-with-python/
* https://docs.microsoft.com/en-us/sql/connect/python/pyodbc/step-1-configure-development-environment-for-pyodbc-python-development?view=sql-server-2017
* https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connect-query-python
## App Service
* https://docs.microsoft.com/en-us/azure/app-service/containers/quickstart-python
## Container
* https://code.visualstudio.com/docs/python/tutorial-deploy-app-service-on-linux
* https://github.com/Azure-App-Service/python/tree/master/3.7.0
