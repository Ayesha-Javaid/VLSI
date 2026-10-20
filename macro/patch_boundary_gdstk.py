import gdstk

lib = gdstk.read_gds("sram22_256x32m4w8.gds")
cell = lib.top_level()[0]
print(f"Patching cell: {cell.name}")

boundary_rect = gdstk.rectangle((0, 0), (422.880, 291.640), layer=235, datatype=4)
cell.add(boundary_rect)

layers_after = sorted(set((p.layer, p.datatype) for p in cell.polygons))
print("Layers after patch:", layers_after)

lib.write_gds("sram22_256x32m4w8_patched.gds")
print("Wrote sram22_256x32m4w8_patched.gds")
