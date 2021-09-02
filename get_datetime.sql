CREATE PROCEDURE [dbo].[get_datetime] AS
BEGIN
      
	 SELECT DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) ,0) AS 'Общая_дата',
	        DATEPART(YEAR, getdate()) AS 'Год',
	        DATEPART(MONTH, getdate()) AS 'Месяц',	 
		    DATEPART(DAY, getdate()) AS 'Число',
            DATEPART(HOUR, getdate()) AS 'Час',
	        DATEPART(MINUTE, getdate()) AS 'Минуты',
	        DATEPART(SECOND, getdate()) AS 'Секунды',
	        DATEPART(MILLISECOND, getdate()) AS 'МиллиСекунды'

END
GO


