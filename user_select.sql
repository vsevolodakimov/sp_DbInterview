CREATE procedure [dbo].[user_select]
	@id_user INT

as
BEGIN
      
	  IF NOT EXISTS (SELECT 1 FROM [Db_Interview].[dbo].[Users] WHERE [UserID] = @id_user)
	  BEGIN 
		   RAISERROR('”частника не существует', 16, 1)
	  END
	  ELSE 
	  BEGIN 
	    SELECT [Category] AS 'Пол',
               [LastName] AS 'Фамилия',
               [FirstName] AS 'Имя',
               [MiddleName] AS 'Отчество',
               [Age] AS 'Возраст',
               [RegDate] AS 'Дата_регистрации' 
		FROM [Db_Interview].[dbo].[Users] 
		WHERE [UserID] = @id_user
	  END

end


GO


