extends Node
class_name AutoloadUtils

static func get_autoload(name: String) -> Node:
    var main_loop := Engine.get_main_loop()
    if main_loop == null:
        push_error("[AutoloadUtils] Main loop unavailable when requesting autoload: " + name)
        return null
    var root := main_loop.root
    if root == null:
        push_error("[AutoloadUtils] Root viewport unavailable when requesting autoload: " + name)
        return null
    if root.has_node(name):
        return root.get_node(name)
    push_error("[AutoloadUtils] Autoload not found: " + name)
    return null
