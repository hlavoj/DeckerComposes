CREATE LOGIN developer WITH PASSWORD = 'Dev16eloperPaSs@dasdf313';
CREATE USER developer FOR LOGIN developer;
ALTER SERVER ROLE sysadmin ADD MEMBER developer;


CREATE LOGIN [developer] WITH PASSWORD = 'Dev16eloperPaSs@dasdf313';
CREATE DATABASE [PetProjectDb];
USE [PetProjectDb];
CREATE USER [developer] FOR LOGIN [developer];
ALTER ROLE db_owner ADD MEMBER [developer];