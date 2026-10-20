DO $$
DECLARE
    t record;
BEGIN
    FOR t IN
        SELECT f_table_name, f_geometry_column
        FROM geometry_columns
        WHERE f_table_schema = 'bdot'
    LOOP
        EXECUTE format(
            'CREATE INDEX IF NOT EXISTS %I ON bdot.%I USING GIST (%I)',
            'idx_' || t.f_table_name || '_geom',
            t.f_table_name,
            t.f_geometry_column
        );
    END LOOP;
END $$;

CREATE INDEX IF NOT EXISTS idx_h3_6_2180
ON grid.h3_res_6 USING GIST (geom_2180);

CREATE INDEX IF NOT EXISTS idx_h3_7_2180
ON grid.h3_res_7 USING GIST (geom_2180);

CREATE INDEX IF NOT EXISTS idx_h3_8_2180
ON grid.h3_res_8 USING GIST (geom_2180);
