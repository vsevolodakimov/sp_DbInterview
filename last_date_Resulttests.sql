CREATE PROCEDURE [dbo].[last_date_Resulttests]
AS
BEGIN


SELECT CASE WHEN T2.[Category] = 1 THEN 'Мужчина' ELSE 'Женщина' END AS 'Пол',
       T2.[LastName],
       T2.[FirstName],
       T2.[MiddleName],
       T2.[Age],
	   T3.[CityName],
	   DATEADD(DAY, DATEDIFF(DAY, 0, T2.[RegDate]), 0) AS 'RegDate',
	   T5.[SurveyID],
	   T5.[Start]
FROM [DbInterview].[dbo].[Users] AS T2
     JOIN
	 [DbInterview].[dbo].[ListCities] AS T3
	 ON T2.[CityID] = T3.[ID]
	 CROSS APPLY(
	             SELECT TOP 1 
	                    T4.[SurveyID],
	                    T4.[Start]
                  FROM [DbInterview].[dbo].[Resulttests] AS T4
				  WHERE T4.[PolledID] = T2.[UserID]
				  ORDER BY T4.[Start] ASC
	            ) AS T5

END





















GO


