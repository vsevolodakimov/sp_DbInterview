CREATE PROCEDURE [dbo].[not_users_cities]
AS
BEGIN
    SELECT [ID],
           [CityName] AS 'Город'
    FROM [DbInterview].[dbo].[ListCities]
	WHERE NOT EXISTS(SELECT 1 FROM [DbInterview].[dbo].[Users] WHERE [CityID] = [ID])
	ORDER BY [ID] ASC
END
GO


