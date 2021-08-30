CREATE PROCEDURE [dbo].[sp_select_users]
AS 
  SELECT TOP 100
         [LastName] AS 'Фамилия',
         [FirstName] AS 'Имя',
         ISNULL([MiddleName], '' )AS 'Отчество',
		 [CityID] 
  FROM [DbInterview].[dbo].[Users]
  WHERE [Category] = 1 
  ORDER BY [LastName] ASC
GO


