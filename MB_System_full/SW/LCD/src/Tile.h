#ifndef TILE_H
#define TILE_H
#include <stdlib.h>
#define HEAD 'X'
#define TAIL 'O'
#define EMPTY 'e'
#define FOOD 'f'

typedef struct Tile Tile;
struct Tile {
	char type;
	Tile* prevTile;
	Tile* front;
	Tile* back;
	Tile* left;
	Tile* right;
};

struct Tile* Tile_create();

void Tile_destroy(Tile* tile);

void Tile_changeType(Tile* tile, char newType);

#endif