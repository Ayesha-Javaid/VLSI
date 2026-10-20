import gdstk

lib = gdstk.read_gds("sram22_256x32m4w8.gds")
top_cells = lib.top_level()
print(f"Top-level cells found: {[c.name for c in top_cells]}")

if len(top_cells) != 1:
    raise SystemExit(f"Expected exactly 1 top cell, found {len(top_cells)}: {[c.name for c in top_cells]}")

cell = top_cells[0]
print(f"Patching cell: {cell.name}")

bbox_value = "0 0 422.880 291.640"
cell.set_property("FIXED_BBOX", bbox_value)

print("Properties on cell after patch:", cell.properties)

lib.write_gds("sram22_256x32m4w8_patched.gds")
print("Wrote sram22_256x32m4w8_patched.gds")
