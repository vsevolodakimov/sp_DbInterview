CREATE procedure [dbo].[select_user]
	@id_user INT

as
BEGIN
      
	  IF EXISTS (SELECT * FROM [Db_Interview].[dbo].[Users] WHERE [UserID] = @id_user)
	  BEGIN 
		  SELECT CASE WHEN T2.[Category] = 1 THEN 'Мужчина' ELSE 'Женщина' END AS 'Пол',
				 CASE T2.[LastName] WHEN IS NULL THEN '' ELSE T2.[LastName] END AS 'Фамилия',
				 ISNULL(T2.[FirstName], '')  AS 'Имя',
				 ISNULL(T2.[MiddleName], '')  AS 'Отчество',
				 T2.[Age] AS 'Возраст',
				 T2.[RegDate] AS 'Дата_регистрации',
				 T3.[CityName] AS 'Город'
		   FROM [Db_Interview].[dbo].[Users] AS T2
				JOIN 
				[Db_Interview].[dbo].[ListCities] AS T3
				ON T2.[CityID] = T3.ID
		  WHERE [UserID] = @id_user
	  END
	  ELSE 
	  BEGIN 
	   SELECT 'Такого участника несуществует'
	  END

end



GO


