# Map, Ground and Level Objects

## Some decisions about how the map works

### Ground Sectors

* Each Ground Sector is 25x50 triangles
* Each triangle is scaled by GroundSector.GroundSectorScale
* Each Ground Sector has a tile value of X, Z
* Ground Sector will draw at X * ground_scale * 25, Z * ground_scale * 50
* No negative tile values (no -1,0 ground_sector)