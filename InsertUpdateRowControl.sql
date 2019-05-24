CREATE PROC [ADF].[controltable_rowchanges] @TableName [nvarchar](4000) AS

DECLARE @sqlStatement varchar(MAX), @TableOnly nvarchar(255), @tSQLStatement nvarchar(4000)

	SET @tSQLStatement = (SELECT AzureTSQL FROM adf.SQLControlTableStatements WHERE TableName = @TableName)
	SET @TableOnly	= RIGHT(@TableName,LEN(@TableName)-CHARINDEX('.',@TableName))

SET @SqlStatement = ' CREATE TABLE #temp_columnlist_' + @TableOnly + ' WITH (DISTRIBUTION = ROUND_ROBIN, HEAP) AS '
					+ char(10) + '( SELECT ORDINAL_POSITION, COLUMN_NAME, IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE (TABLE_SCHEMA + ''.'' + TABLE_NAME) = ''' + @TableName + ''');'
					+ char(10)
					+ char(10) + ' DECLARE @total int = (select MAX(ORDINAL_POSITION) from #temp_columnlist_' + @TableOnly + ')'
					+ char(10) + ' DECLARE @i int = 1, @Concat AS VARCHAR(MAX) = '''''
					+ char(10) + ' WHILE (@i <= @total) BEGIN '
					+ char(10) + char(9) + ' DECLARE @ColumnName VARCHAR(200) = (select COLUMN_NAME FROM #temp_columnlist_' + @TableOnly + ' WHERE ORDINAL_POSITION = @i)'
					+ char(10) + char(9) + ' DECLARE @IsNullable varchar(3) = (select IS_NULLABLE FROM #temp_columnlist_' + @TableOnly + ' WHERE ORDINAL_POSITION = @i)'
					+ char(10)
					+ char(10) + char(9) + ' IF @IsNullable = ''NO'' BEGIN SET @Concat += '' AND s.'' + @ColumnName + ''=t.'' + @ColumnName + char(10) END'
					+ char(10) + char(9) + ' ELSE IF @IsNullable = ''YES'' BEGIN SET @Concat += '' AND(s.'' + @ColumnName + ''=t.'' + @ColumnName + '' OR(s.'' + @ColumnName + '' IS NULL AND t.'' + @ColumnName + '' IS NULL))'' + char(10) END'
					+ char(10) + ' SET @i += 1 END;'
					+ char(10) + ' DROP TABLE #temp_columnlist_' + @TableOnly + ';'
					+ char(10)
					+ char(10) + ' DECLARE @insertUpdateChange int = (select COUNT(*) from adf.ControlTables AS c INNER JOIN adf.AZURE_DATA_FACTORY_CHANGE_LOG AS l ON l.[FullPath] = c.[TableName] WHERE TableName = ''' + @TableName + ''' AND c.[InsertUpdateCount]  <> l.[InsertUpdateCount])'
					+ char(10) + ' IF @insertUpdateChange = 1 BEGIN '
					+ char(10) + ' DECLARE @insertSQLStatement varchar(MAX)'
					+ char(10) + ' SET @insertSQLStatement = ''INSERT INTO ' + @TableName + ''''
					+ char(10) + '			+ char(10) + '' SELECT * FROM ' + REPLACE(@TableName, '_T.', '_ADF_S.') + ' AS s'''
					+ char(10) + '			+ char(10) + '' WHERE NOT EXISTS (' + REPLACE(REPLACE(@tSQLStatement, '''', ''''''), 'WHERE', 'AS t WHERE') + ''''
					+ char(10) + '			+ char(10) + @Concat + '');'''
					+ char(10) + ' EXEC(@InsertSQLStatement)'
					+ char(10)
					+ char(10) + ' EXEC [ADF].[change_log_insertupdatecount] ''' + @TableName + ''''
					+ char(10) + ' PRINT ''ROWS INSERTED'''
					+ char(10) + ' END'
					+ char(10)
					+ char(10) + ' DECLARE @deleteUpdateChange int = (select COUNT(*) from adf.ControlTables AS c INNER JOIN adf.AZURE_DATA_FACTORY_CHANGE_LOG AS l ON l.[FullPath] = c.[TableName] WHERE TableName = ''' + @TableName + ''' AND c.[DeleteUpdateCount]  <> l.[DeleteUpdateCount])'
					+ char(10) + ' IF @deleteUpdateChange = 1 BEGIN '
					+ char(10) + ' CREATE TABLE #temp_delete_' + @TableOnly + ' WITH (DISTRIBUTION = ROUND_ROBIN, HEAP) AS '
					+ char(10) + ' ( ' + @tSQLStatement + ');'
					+ char(10)
					+ char(10) + ' DECLARE @deleteSQLStatement varchar(MAX)'
					+ char(10) + ' SET @deleteSQLStatement = ''DELETE FROM #temp_delete_' + @TableOnly + ''''
					+ char(10) + '			+ char(10) + '' WHERE NOT EXISTS (SELECT * FROM ' + REPLACE(@TableName, '_T.', '_ADF_S.') + ' AS s WHERE'''
					+ char(10) + '			+ char(10) + REPLACE(RIGHT(@Concat, LEN(@Concat)-4),''t.'',''#temp_delete_' + @TableOnly + '.'') + '');'''
					+ char(10) + ' EXEC(@deleteSQLStatement)'
					+ char(10) + ' DELETE FROM ' + @TableName + REPLACE(@tSQLStatement, 'SELECT * FROM ' + @TableName, ' ') + ';'
					+ char(10)
					+ char(10) + ' INSERT INTO ' + @TableName
					+ char(10) + ' SELECT * FROM #temp_delete_' + @TableOnly + ';'
					+ char(10) + ' DROP TABLE #temp_delete_' + @TableOnly + ';'
					+ char(10)
					+ char(10) + ' EXEC [ADF].[change_log_deleteupdatecount] ''' + @TableName + ''''
					+ char(10) + ' PRINT ''ROWS REMOVED'''
					+ char(10) + ' END'

	--PRINT @SqlStatement
	EXEC (@SqlStatement)

GO
