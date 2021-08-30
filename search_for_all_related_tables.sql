CREATE PROCEDURE [dbo].[search_for_all_related_tables]
(
  @schema_table VARCHAR(10), -- схема таблицы 
  @name_table VARCHAR(50) -- имя таблицы 
)
AS
BEGIN -- Начало Процедуры search_for_all_related_tables

SET NOCOUNT ON


DECLARE @column_name VARCHAR(30), -- название столбца 
		@value_column INT, -- значение столбца 
		@nestinglevel INT, -- Уровень вложенности связи по внешнему ключу
		@maxnum INT,
		@internalstep INT,
		@internal_schema_table VARCHAR(10), 
        @internal_name_table VARCHAR(50),
		@MaxNumberLinks INT, -- содержит максимальное число связей (по внешнему ключу) пользовательскиих таблиц.
		@countTable INT,
		@countPK INT,
		@output_message VARCHAR(60),
		@total_number_relation VARCHAR(60)


/*****************************************************************************************************/



SELECT @nestinglevel = 1 -- начальное значение уровня вложенности (Зависимости)


/*************** 1. Занесём все данные (из базы данных) о таблицах (т.е. связях) во временную таблицу #allTableRelation ********************/

SELECT 	--T5.TABLE_CATALOG AS 'База_данных',
       OBJECT_SCHEMA_NAME(T2.[object_id]) AS 'Схема_входных_данных',
       T2.[name] 'Таблица_входных_данных',  
       T3.[name] AS 'Столбец_входных_данных',
	   T7.key_ordinal AS 'Первичный_ключ',
	   --T7.is_identity AS 'Автоинкремент',
	   T5.DATA_TYPE AS 'Тип_данных', -- одновременно показывает одинаковый тип данных двух столбцов связанных таблиц
	   --T5.IS_NULLABLE AS 'Значения_NULL',
	   T6.Схема_таблицы_выходных_данных,
	   T6.Таблица_выходных_данных,
	   T6.Столбец_выходных_данных
INTO #allTableRelation -- Временная таблица содержащия все связи таблиц по внешним ключам
FROM [sys].[tables] AS T2 -- список таблиц базы данных
     JOIN
	 [sys].[schemas] AS T4
	 ON T2.[schema_id] = T4.[schema_id]
     JOIN
	 [sys].[columns] AS T3
	 ON T2.[object_id] = T3.[object_id]
	 JOIN
	 [INFORMATION_SCHEMA].[COLUMNS] AS T5 -- 'Тип_данных' и 'Значения_NULL'
	 ON T2.[name] = T5.TABLE_NAME AND T3.[name] = T5.COLUMN_NAME
	 OUTER APPLY(
	              SELECT OBJECT_SCHEMA_NAME(f.parent_object_id) AS 'Схема_таблицы_выходных_данных',
				         f.name AS 'Название_внешнего_ключа',  
					     OBJECT_NAME (f.referenced_object_id) AS 'Таблица_выходных_данных',  
					     COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS 'Столбец_выходных_данных' 
				  FROM [sys].[foreign_keys] AS f  
					   JOIN 
					   [sys].[foreign_key_columns] AS fc   
					   ON f.[object_id] = fc.constraint_object_id   
				  WHERE f.parent_object_id = T2.[object_id]
				        AND
						fc.parent_column_id = T3.[column_id]
	            ) AS T6
     OUTER APPLY(	              
					SELECT i.[name] AS index_name,
						   key_ordinal,
						   is_identity
					FROM [sys].[indexes] AS i
						 JOIN 
						 [sys].[index_columns] AS ic 
						 ON i.[object_id] = ic.[object_id] AND i.index_id = ic.index_id
						 JOIN 
						 [sys].[columns] AS c 
						 ON ic.[object_id] = c.[object_id] AND c.column_id = ic.column_id
					WHERE i.is_primary_key = 1 
						  AND 
						  i.[object_id] = T2.[object_id]
						  AND
						  ic.index_column_id = T3.[column_id]
		        ) AS T7 
WHERE T2.[type] = 'U' -- выбираются только пользовательские таблицы


/******* 2. Создаём Промежуточную временную таблицу в которой и будут содержаться все необходимые таблицы (и их ссылки) для удаления данных *************/


CREATE TABLE #PredResult
( 
  row1 INT NULL, -- УРОВЕНЬ ВЛОЖЕННОСТИ 
  in_scnema VARCHAR(10) NULL, -- Схема_входных_данных
  in_name_table VARCHAR(50) NULL, -- Таблица_входных_данных
  in_name_col  VARCHAR(50) NULL, -- Столбец_входных_данных
  in_type_data VARCHAR(20) NULL, -- одновременно показывает одинаковый тип данных двух столбцов связанных таблиц 
  out_scnema VARCHAR(10) NULL, -- Схема_таблицы_выходных_данных
  out_name_table VARCHAR(50) NULL, -- Таблица_выходных_данных
  out_name_col  VARCHAR(50) NULL -- Столбец_выходных_данных 
)


/******* 3. Предварительная временная таблица в которой будут содержаться все необходимые таблицы для удаления данных **********/


CREATE TABLE #listTablesWithlinks
( 
  lTWl_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  row1 INT NULL, -- уровень вложенности
  in_scnema VARCHAR(10) NULL, -- Схема_входных_данных
  in_name_table VARCHAR(50) NULL, -- Таблица_входных_данных
  in_name_col  VARCHAR(50) NULL, -- Столбец_входных_данных
  in_type_data VARCHAR(20) NULL, -- одновременно показывает одинаковый тип данных двух столбцов связанных таблиц 
  out_scnema VARCHAR(10) NULL, -- Схема_таблицы_выходных_данных
  out_name_table VARCHAR(50) NULL, -- Таблица_выходных_данных
  out_name_col  VARCHAR(50) NULL -- Столбец_выходных_данных 
)


/******************** создание промежуточной таблицы для работы в цикле *********************************/

CREATE TABLE #interdata  
(
  num INT IDENTITY(1, 1) PRIMARY KEY, 
  scnema VARCHAR(10) NOT NULL, -- Схема_входных_данных
  name_table VARCHAR(50) NOT NULL -- Таблица_входных_данных
)

/*********************** Заполнение таблицы #PredResult **************************************************/


INSERT INTO #listTablesWithlinks 
(
  row1,
  in_scnema,
  in_name_table,
  in_name_col,
  in_type_data,
  out_scnema,
  out_name_table,
  out_name_col
)
SELECT @nestinglevel,
       Схема_входных_данных,	
       Таблица_входных_данных,	
	   Столбец_входных_данных,	
	   Тип_данных,	
	   Схема_таблицы_выходных_данных,	
	   Таблица_выходных_данных,	
	   Столбец_выходных_данных
FROM #allTableRelation
WHERE Схема_таблицы_выходных_данных = @schema_table -- схема таблицы с которой удаляются данные 
	  AND
	  Таблица_выходных_данных = @name_table -- Таблица с которой удаляются данные  




/********** Получения общего числа соединений во всех таблицах БД по внешнему ключу **************************/


CREATE TABLE #NumberConnectionsTables
(
  scnema VARCHAR(10) NOT NULL, 
  nametable VARCHAR(50) NOT NULL,
  countconnect INT NOT NULL
   
)



INSERT INTO #NumberConnectionsTables
(
  scnema, 
  nametable,
  countconnect
) 
SELECT Схема_входных_данных, 
       Таблица_входных_данных,
	   COUNT(*) -- Столбец содержит общее число соединений с другими таблицами через внешний ключ
FROM #allTableRelation
WHERE  Таблица_выходных_данных IS NOT NULL
GROUP BY Схема_входных_данных, 
         Таблица_входных_данных


-- Получаем общее число соединений по внешнему ключу во всех таблицах текущей БД
SELECT @MaxNumberLinks = SUM(countconnect)
FROM #NumberConnectionsTables


/****************************************************************************/


-- Проверка имеет ли таблица в которой надо удалить данные связь с другими таблицами. Если такая связь имеется то продолжаем дальше заполнять таблицу #listTablesWithlinks
IF EXISTS (SELECT in_name_table FROM #listTablesWithlinks)
BEGIN -- начало IF

   WHILE 1 = 1 -- Включаем бесконечное колличество итераций цикла потому-что число вложенных связей между таблицами заранее неизвествно. 
   BEGIN -- начало внешнего цикла WHILE 
        
		INSERT INTO #interdata 
		(
		  scnema, -- Схема_входных_данных
		  name_table -- Таблица_входных_данных
		)
		SELECT DISTINCT -- DISTINCT ставится потому-что может быть связь одновременно более чем на один столбец
			   in_scnema,
			   in_name_table
		FROM #listTablesWithlinks
		WHERE row1 = @nestinglevel -- уровень вложености


		SELECT @maxnum = (SELECT MAX(num) FROM #interdata),
		       @internalstep = 1 -- перед началом внутреннего цикла задаём шагу значение 1 
		
		SET @nestinglevel = @nestinglevel + 1 -- уроаень вложенности перед началом внутреннего цикла WHILE уведичиваем на 1


		WHILE @internalstep <= @maxnum 
		BEGIN -- Начало внутреннего цикла WHILE
		
		   -- заполняем промежуточные переменые значениями (проще говоря постепенно пробегаем по всем таблицам и схемам)
		   SELECT @internal_schema_table = scnema, -- Схема_входных_данных
		          @internal_name_table = name_table -- Таблица_входных_данных
		   FROM #interdata
		   WHERE num = @internalstep -- порядковый номер шага (итерации) внутреннего цикла WHILE


		   INSERT INTO #listTablesWithlinks 
		   (
		    row1, 
		    in_scnema,
		    in_name_table,
		    in_name_col,
		    in_type_data,
		    out_scnema,
		    out_name_table,
		    out_name_col
		   )
		   SELECT @nestinglevel, -- уровень вложенности увеличен на 1 
			      Схема_входных_данных,	
			      Таблица_входных_данных,	
			      Столбец_входных_данных,	
			      Тип_данных,	
			      Схема_таблицы_выходных_данных,	
			      Таблица_выходных_данных,	
			      Столбец_выходных_данных
		   FROM #allTableRelation
		   WHERE Схема_таблицы_выходных_данных = @internal_schema_table -- схема таблицы с которой удаляются данные 
			     AND
			     Таблица_выходных_данных = @internal_name_table -- Таблица с которой удаляются данные 

		   -- увеличиваем порядковый номер итерации внутреннего цикла WHILE на 1 
		   SET @internalstep = @internalstep + 1       

		END -- конец внутреннего цикла WHILE

		-- Удаляем все данные с таблицы #interdata и сбрасываем все счётчики
		TRUNCATE TABLE #interdata 

   -- выход из внешнего цикла WHILE когда все уровни вложености найденны
   IF NOT EXISTS (SELECT in_name_table FROM #listTablesWithlinks WHERE row1 = @nestinglevel)
   BEGIN 

      SELECT @output_message =  'НЕ замкнутая система связей таблиц.',
	         @total_number_relation = 'Общее число связей пользовательских таблиц в БД' + ' ' + CONVERT(VARCHAR(20), DB_NAME())
 
      BREAK -- Команда до срочного выхода из цикла

   END

   -- Досрочный выход из цикла когда в таблице замкнутая система связей зависимостей
   IF (@MaxNumberLinks <= (SELECT MAX(lTWl_id) FROM #listTablesWithlinks))
   BEGIN 

      SELECT @output_message = 'Замкнутая система связей таблиц.',
             @total_number_relation = 'Общее число связей пользовательских таблиц в БД' + ' ' + CONVERT(VARCHAR(20), DB_NAME())

      BREAK -- Команда до срочного выхода из цикла

   END


   END -- окончание внешнего цикла WHILE 





INSERT INTO #PredResult
( 
  row1,
  in_scnema,
  in_name_table,
  in_name_col,
  in_type_data,
  out_scnema,
  out_name_table,
  out_name_col
)
SELECT DISTINCT
       T2.row1,		
	   T2.in_scnema,	
	   T2.in_name_table,	
	   T2.in_name_col,	
	   T2.in_type_data,	
	   T2.out_scnema,	
	   T2.out_name_table,	
	   T2.out_name_col
FROM #listTablesWithlinks AS T2
WHERE T2.lTWl_id = (
                    SELECT MIN(lTWl_id)     
					FROM #listTablesWithlinks
					WHERE in_scnema = T2.in_scnema
						  AND	
						  in_name_table = T2.in_name_table
						  AND
						  in_name_col = T2.in_name_col
						  AND
						  in_type_data = T2.in_type_data
						  AND
						  out_scnema = 	T2.out_scnema
						  AND
						  out_name_table = T2.out_name_table
						  AND
						  out_name_col = T2.out_name_col
                   )



SELECT row1 AS 'Уровень_вложенности', 
       DENSE_RANK () OVER (PARTITION BY row1 ORDER BY row1 ASC, in_scnema ASC, in_name_table ASC) AS 'Порядковый_номер_таблицы',
	   ROW_NUMBER() OVER (PARTITION BY row1, in_scnema, in_name_table ORDER BY row1 ASC, in_scnema ASC, in_name_table ASC, in_name_col ASC ) AS 'Порядковый_номер_столбца', -- (бывают такие случаи что два и более поля таблицы ссылаются на одно поле другой таблицы)
       in_scnema, 
       in_name_table,
       in_name_col,
       in_type_data,
       out_scnema,
       out_name_table,
       out_name_col
INTO #Result -- СОЗДАНИЕ РЕЗУЛЬТИРУЮЩИЙ ТАБЛИЦЫ В КОТОРОЙ УКАЗАННА ВСЯ ИЕРРАРХИЯ СВЯЗЕЙ 
FROM #PredResult





-- Просмотр данных о сваязанных таблицах
SELECT [Уровень_вложенности], 
       [Порядковый_номер_таблицы],
	   [Порядковый_номер_столбца], -- (бывают такие случаи что два и более полей таблицы ссылаются на одно поле другой таблицы)
       in_scnema AS 'Схема_таблицы_входных_данных',
       in_name_table AS 'Таблица_входных_данных', -- (т.е. в таблицу "in_name_table" попадают данные из таблицы "out_name_table")
       in_name_col AS 'Столбец_входных_данных', -- Столбец_входных_данных
       out_scnema AS 'Схема_таблицы_выходных_данных',
       out_name_table AS 'Таблица_выходных_данных', -- 
       out_name_col AS 'Столбец_выходных_данных', -- Столбец который отправляет свои данные в столбец "in_name_col"
	   in_type_data AS 'Тип_данных_для_связанных_столбцов' --
FROM #Result -- 
ORDER BY [Уровень_вложенности] ASC,
         [Порядковый_номер_таблицы] ASC,
		 [Порядковый_номер_столбца] ASC


PRINT '1. ' + @output_message
PRINT '2. ' + @total_number_relation + ' равно' + ' ' + CONVERT(VARCHAR(4), @MaxNumberLinks)


-- Удаляем временные таблицы
DROP TABLE #allTableRelation
DROP TABLE #listTablesWithlinks
DROP TABLE #interdata
DROP TABLE #PredResult
DROP TABLE #NumberConnectionsTables
DROP TABLE #Result 


END -- конец IF
ELSE 
BEGIN 

 SELECT NULL AS 'Уровень_вложенности', 
        NULL AS 'Порядковый_номер_таблицы',
	    NULL AS 'Порядковый_номер_столбца', 
        NULL AS 'Схема_таблицы_входных_данных',
        NULL AS 'Таблица_входных_данных', 
        NULL AS 'Столбец_входных_данных', 
        NULL AS 'Схема_таблицы_выходных_данных',
        NULL AS 'Таблица_выходных_данных', -- 
        NULL AS 'Столбец_выходных_данных', 
	    NULL AS 'Тип_данных_для_связанных_столбцов' 


PRINT 'Данные таблицы' + '  ' + @name_table + '  ' + 'в другие таблицы не отправляются либо данная таблица не существует.'


-- Удаляем временные таблицы
DROP TABLE #allTableRelation
DROP TABLE #listTablesWithlinks
DROP TABLE #interdata
DROP TABLE #NumberConnectionsTables
DROP TABLE #PredResult
 
END

END -- Конец Процедуры search_for_all_related_tables


GO


