drc off
crashbackups disable
locking disable

gds read sram22_256x32m4w8.gds
load sram22_256x32m4w8

box values 0um 0um 422.880um 291.640um
property FIXED_BBOX [box values]

puts "=== PROPERTY IMMEDIATELY AFTER SETTING ==="
puts [property list FIXED_BBOX]
puts "=== END CHECK ==="

gds write sram22_256x32m4w8_patched.gds
quit -noprompt
