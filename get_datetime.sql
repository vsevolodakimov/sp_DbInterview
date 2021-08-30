CREATE PROCEDURE [dbo].[get_datetime] AS
BEGIN
      
	 SELECT getdate() AS 'Общая_дата',
	        SELECT DATEDIFF(DAY, 0, GETDATE()) AS 'Колличество_дней',
	        DATEPART(YEAR, getdate()) AS 'Год',
	        DATEPART(MONTH, getdate()) AS 'Месяц',	 
		    DATEPART(DAY, getdate()) AS 'Число',
            DATEPART(HOUR, getdate()) AS 'Час',
	        DATEPART(MINUTE, getdate()) AS 'Минуты',
	        DATEPART(SECOND, getdate()) AS 'Секунды',
	        DATEPART(MILLISECOND, getdate()) AS 'МиллиСекунды'

END
GO


