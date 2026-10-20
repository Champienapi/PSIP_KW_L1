DO $$
DECLARE
    t record;
    invalid_count bigint;
    total_invalid bigint := 0;
BEGIN
    FOR t IN
        SELECT f_table_schema, f_table_name, f_geometry_column
        FROM geometry_columns
        WHERE f_table_schema = 'bdot'
    LOOP
        EXECUTE format(
            'SELECT COUNT(*) FROM %I.%I WHERE %I IS NOT NULL AND NOT ST_IsValid(%I)',
            t.f_table_schema, t.f_table_name,
            t.f_geometry_column, t.f_geometry_column
        ) INTO invalid_count;

        IF invalid_count > 0 THEN
            RAISE NOTICE 'Niepoprawne geometrie: %.% = %',
                t.f_table_schema, t.f_table_name, invalid_count;
        END IF;

        total_invalid := total_invalid + invalid_count;
    END LOOP;

    RAISE NOTICE 'Laczna liczba niepoprawnych geometrii: %', total_invalid;
END $$;
