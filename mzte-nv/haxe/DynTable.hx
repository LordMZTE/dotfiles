package;

import lua.Table;

abstract DynTable(AnyTable) from AnyTable to AnyTable {
    public inline function new() {
        this = Table.create();
    }

    @:arrayAccess
    public inline function get(k:Dynamic):Dynamic return this[untyped k];

    @:arrayAccess
    public inline function set(k:Dynamic, v:Dynamic) this[untyped k] = v;
}
