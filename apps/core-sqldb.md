# Step-by-Step:
Ref: https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connect-query-php

1. Create App infra with database and storage account 
* https://github.com/fujute/m18h/blob/master/sample.web.sql-18032019-e.ps1 
* https://raw.githubusercontent.com/mspnp/reference-architectures/master/managed-web-app/basic-web-app/Paas-Basic/Templates/PaaS-Basic.json

2. .NET Core console
```shell
dotnet new console
```
3. vi sqlconsole.csproj
```shell
<Project Sdk="Microsoft.NET.Sdk">
<ItemGroup>
    <PackageReference Include="System.Data.SqlClient" Version="4.6.0" />
</ItemGroup>

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>netcoreapp2.2</TargetFramework>
  </PropertyGroup>

</Project>
```
4. vi Program.cs
```shell
using System;
using System.Data.SqlClient;
using System.Text;

namespace sqltest
{
    class Program
    {
        static void Main(string[] args)
        {
            try 
            { 
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();

                builder.DataSource = "<<DatabaseServerName.database.windows.net,1433>>"; 
                builder.UserID = "<<username>>";            
                builder.Password = "<<password>>";     
                builder.InitialCatalog = "<<app-database-name>>";
         
                using (SqlConnection connection = new SqlConnection(builder.ConnectionString))
                {
                    Console.WriteLine("\nQuery database name:");
                    Console.WriteLine("=========================================\n");
                    
                    connection.Open();       
                    StringBuilder sb = new StringBuilder();
                    sb.Append("SELECT DB_NAME()");
                    String sql = sb.ToString();

                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        using (SqlDataReader reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                Console.WriteLine("{0}", reader.GetString(0));
                            }
                        }
                    }                    
                }
            }
            catch (SqlException e)
            {
                Console.WriteLine(e.ToString());
            }
            Console.WriteLine("\nDone. Press enter.");
            Console.ReadLine(); 
        }
    }
}
```
5. Test the sample program
```shell
dotnet restore
dotnet run
```


## See also:
* https://docs.microsoft.com/en-us/azure/sql-database/sql-database-single-database-get-started-template
