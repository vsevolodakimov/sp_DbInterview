CREATE PROCEDURE [dbo].[Multiplication_By_5]
(
    @Dividend VARCHAR(MAX) 
)
AS
BEGIN
	
SET NOCOUNT ON


	DECLARE @Result VARCHAR(MAX), -- Переменная для возвращаеиого значения (Результат деления)
	        @countElements INT,    -- Колличество цифр в числе @Dividend
			@CountAll INT = 1,     -- для счётчика цикла
	        @Char char(1),        -- для помещения сюда цифры по одной
			@ResultMult INT,       -- Результат умножения цифры на 5
			@firstSimbol char(1), -- Первый символ в числе @Dividend
			@lastSimbol char(1)  -- Последний символ в числе @Dividend

    -- Заполнение переменных которые будут иметь постоянное значение
	SELECT @countElements = LEN(@Dividend),
	       @firstSimbol = SUBSTRING(@Dividend, 1, 1),
		   @lastSimbol = SUBSTRING(@Dividend, @countElements, 1)


    /************************************************************************************/

	CREATE TABLE #Multiplication
	(
	  id INT PRIMARY KEY, -- Порядковый номер цифры в числе @Dividend
	  first_figure INT NOT NULL, -- Первый символ(цифра) в числе, результат которого является у множение цифры(из числа @Dividend) на 5
	  last_figure INT NOT NULL  -- Второй символ(цифра) в числе, результат которого является у множение цифры(из числа @Dividend) на 5 
	)

	-- Таблица результат деления на 2 
	CREATE TABLE #ResultMerger
	(
	 id INT PRIMARY KEY, -- Порядковый номер цифры в числе @Dividend
	 symbol char(1)    -- цифра
	)

	/************************************************************************************/

	-- Запускаем цикл который заполняет таблицу #Multiplication 
	WHILE @CountAll <= @countElements
	BEGIN
	  
	   SELECT @Char = SUBSTRING(@Dividend, @CountAll, 1), -- Вытаскиваем цифру из строки @Dividend  с позиции @CountAll и помещаем её в переменную @Char
              @ResultMult = CAST(@Char AS INT) * 5     -- цифру в переменной @Char умножаем на 5, и результат умножения заноситм в переменную @ResultMult

	   INSERT INTO #Multiplication
	   (
	     id, -- Порядковый номерр цифры @Char которая находится в числе @Dividend
	     first_figure, 
	     last_figure
	   )
	   SELECT @CountAll,
	          CASE WHEN LEN(CAST(@ResultMult AS VARCHAR)) = 1 THEN 0 ELSE CAST(SUBSTRING(CAST(@ResultMult AS VARCHAR), 1, 1) AS INT) END,
			  CASE WHEN LEN(CAST(@ResultMult AS VARCHAR)) = 1 THEN CAST(SUBSTRING(CAST(@ResultMult AS VARCHAR), 1, 1) AS INT) ELSE CAST(SUBSTRING(CAST(@ResultMult AS VARCHAR), 2, 1) AS INT) END

	   SET @CountAll = @CountAll + 1

	END


	/************************************************************************************/

	INSERT INTO #ResultMerger
	(
	 id, -- Порядковый номер цифры в числе @Dividend
	 symbol -- цифра
	)
	-- первый символ
	SELECT T3.id,
	       CAST(T3.first_figure AS CHAR)
	FROM #Multiplication AS T3
	WHERE T3.id = 1

	UNION ALL

	-- Символы со второго и до предпоследнего
	SELECT T2.id,
		   CAST(T1.last_figure + T2.first_figure AS CHAR)
	FROM #Multiplication AS T1
	     JOIN
		 #Multiplication AS T2
		 ON T1.id + 1 = T2.id
	

	/************************************************************************************/

	-- Проверка на первую цифру из числа
	IF @firstSimbol = '1'   	    
		SELECT @Result = ISNULL(@Result + '','') + QUOTENAME(T5.symbol) 
        FROM #ResultMerger AS T5
	    WHERE T5.id <> 1 -- пропускаем символ 0          
        ORDER BY T5.id ASC
	ELSE
		SELECT @Result = ISNULL(@Result + '','') + QUOTENAME(T5.symbol) 
        FROM #ResultMerger AS T5		         
        ORDER BY T5.id ASC



    -- Убираем символы []
	SET @Result = REPLACE(@Result, '[', '')
	SET @Result = REPLACE(@Result, ']', '')


     -- Проверка четное или нечетное число 
	IF @lastSimbol IN ('1', '3', '5', '7', '9')
	BEGIN

	    --  Если число нечётное то прибавляем в конец символы "5"
		SET @Result =  @Result + '5'
	
    END
	ELSE
	BEGIN

	  -- Если число чётное то прибавляем ноль в конец 
	  SET @Result =  @Result + '0'
	END
         

	DROP TABLE #Multiplication
	DROP TABLE #ResultMerger

	SELECT @Result
END



GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ХП умножает на 5 число записанное в виде строки' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'Multiplication_By_5'
GO


