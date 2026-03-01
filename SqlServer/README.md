# SQL Server Docker

SQL Server 2025 Developer Edition running in Docker.

## Connection Details

| Property | Value |
|----------|-------|
| Server   | `localhost,1433` |
| Username | `sa` |
| Password | `YourStrong@Passw0rd` |

## Connection Strings

**ADO.NET / C#**
```
Server=localhost,1433;Database=master;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;
```

**JDBC (Java)**
```
jdbc:sqlserver://localhost:1433;databaseName=master;user=sa;password=YourStrong@Passw0rd;trustServerCertificate=true;
```

**ODBC**
```
Driver={ODBC Driver 18 for SQL Server};Server=localhost,1433;Database=master;Uid=sa;Pwd=YourStrong@Passw0rd;TrustServerCertificate=yes;
```

**Entity Framework Core**
```
Server=localhost,1433;Database=YourDb;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;
```

> **Note:** `TrustServerCertificate=True` is required because the container uses a self-signed certificate. Replace `master` with your actual database name as needed.

## Usage

Start the container:
```bash
docker-compose up -d
```

Stop the container:
```bash
docker-compose down
```
