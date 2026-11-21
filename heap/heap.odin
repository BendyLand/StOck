package heap

import "../types"

Map :: distinct map[string]types.Data
Struct :: distinct map[string]types.Data
Array :: distinct [dynamic]types.Data

Object :: union {
    ^Array,
    ^Map,  
    ^Struct 
    // future types: custom function closures, classes, etc.
}

Heap :: struct {
    next_id: i64,
    objects: map[i64]Object, // your simulated heap
}

