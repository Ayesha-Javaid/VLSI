drc off
crashbackups disable
locking disable

gds read sram22_256x32m4w8.gds
load sram22_256x32m4w8

property add FIXED_BBOX "0 0 422.880 291.640"

gds write sram22_256x32m4w8_patched.gds
quit -noprompt