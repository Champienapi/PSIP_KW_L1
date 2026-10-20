import json
from pathlib import Path

import h3
from osgeo import ogr

SOURCE = "/data/powiat.shp"
OUTPUT = Path("/app/output")
RESOLUTIONS = [6, 7, 8]

OUTPUT.mkdir(parents=True, exist_ok=True)

dataset = ogr.Open(SOURCE)
if dataset is None:
    raise RuntimeError("Nie mozna odczytac pliku powiat.shp")

layer = dataset.GetLayer()
feature = layer.GetNextFeature()
if feature is None:
    raise RuntimeError("Brak geometrii powiatu")

geometry = feature.GetGeometryRef()
geojson = json.loads(geometry.ExportToJson())

# OGR: longitude, latitude
# H3 polygon_to_cells przy geo_json_conformant=True przyjmuje GeoJSON lon, lat
shape = h3.geo_to_h3shape(geojson)

for resolution in RESOLUTIONS:
    cells = sorted(h3.h3shape_to_cells(shape, resolution))
    features = []

    for cell in cells:
        boundary = h3.cell_to_boundary(cell)
        ring = [[lon, lat] for lat, lon in boundary]
        ring.append(ring[0])

        features.append({
            "type": "Feature",
            "properties": {
                "h3_index": cell,
                "resolution": resolution
            },
            "geometry": {
                "type": "Polygon",
                "coordinates": [ring]
            }
        })

    output_file = OUTPUT / f"h3_res_{resolution}.geojson"
    output_file.write_text(
        json.dumps({"type": "FeatureCollection", "features": features}),
        encoding="utf-8"
    )

    print(f"H3 resolution {resolution}: {len(cells)} komorek")

print("Generowanie zakonczone.")
