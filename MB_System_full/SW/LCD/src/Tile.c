#include "Tile.h"
#include "malloc.h"
struct Tile* Tile_create() {
	struct Tile* tile = malloc(sizeof(struct Tile));
	tile->type = EMPTY;
	tile->front = NULL;
	tile->back = NULL;
	tile->left = NULL;
	tile->right = NULL;
	tile->prevTile = NULL;
	return tile;
};


void Tile_destroy(Tile* tile) {
	free(tile);
};

void Tile_changeType(Tile* tile, char newType){
	tile->type = newType;
};

