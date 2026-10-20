DO $$
DECLARE
    r integer;
    t record;
    target_table text;
    result_column text;
    expression text;
    unit_suffix text;
    processed integer;
BEGIN
    FOREACH r IN ARRAY ARRAY[6, 7, 8]
    LOOP
        target_table := format('grid.h3_agg_%s', r);
        processed := 0;

        RAISE NOTICE 'Rozpoczynam agregacje H3 resolution %', r;

        EXECUTE format('DROP TABLE IF EXISTS %s', target_table);

        EXECUTE format(
            'CREATE TABLE %s AS
             SELECT h3_index, resolution, geom, geom_2180
             FROM grid.h3_res_%s',
            target_table, r
        );

        FOR t IN
            SELECT f_table_name, f_geometry_column, type
            FROM geometry_columns
            WHERE f_table_schema = 'bdot'
            ORDER BY f_table_name
        LOOP
            IF t.type ILIKE '%POLYGON%' THEN
                unit_suffix := '_m2';
                expression := format(
                    'ST_Area(ST_CollectionExtract(
                        ST_Intersection(h.geom_2180, b.%I), 3))',
                    t.f_geometry_column
                );

            ELSIF t.type ILIKE '%LINESTRING%' THEN
                unit_suffix := '_m';
                expression := format(
                    'ST_Length(ST_CollectionExtract(
                        ST_Intersection(h.geom_2180, b.%I), 2))',
                    t.f_geometry_column
                );

            ELSIF t.type ILIKE '%POINT%' THEN
                unit_suffix := '_n';
                expression := format(
                    'ST_NumGeometries(ST_CollectionExtract(
                        ST_Intersection(h.geom_2180, b.%I), 1))',
                    t.f_geometry_column
                );

            ELSE
                RAISE EXCEPTION 'Nieobslugiwany typ: % (%)',
                    t.f_table_name, t.type;
            END IF;

            result_column := t.f_table_name || unit_suffix;

            EXECUTE format(
                'ALTER TABLE %s ADD COLUMN %I double precision DEFAULT 0',
                target_table, result_column
            );

            EXECUTE format(
                'UPDATE %s AS h
                 SET %I = COALESCE((
                     SELECT SUM(%s)
                     FROM bdot.%I AS b
                     WHERE ST_Intersects(h.geom_2180, b.%I)
                 ), 0)',
                target_table,
                result_column,
                expression,
                t.f_table_name,
                t.f_geometry_column
            );

            processed := processed + 1;
        END LOOP;

        EXECUTE format(
            'CREATE INDEX ON %s USING GIST (geom_2180)',
            target_table
        );

        RAISE NOTICE 'H3 res %: zagregowano % warstw BDOT10k',
            r, processed;
    END LOOP;
END $$;
