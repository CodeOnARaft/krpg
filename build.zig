const std = @import("std");
const rlz = @import("raylib-zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    //web exports are completely separate
    if (target.query.os_tag == .emscripten) {
        const exe_lib = try rlz.emcc.compileForEmscripten(b, "krpg", "src/main.zig", target, optimize);

        exe_lib.linkLibrary(raylib_artifact);
        exe_lib.root_module.addImport("raylib", raylib);

        // Note that raylib itself is not actually added to the exe_lib output file, so it also needs to be linked with emscripten.
        const link_step = try rlz.emcc.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{ exe_lib, raylib_artifact });
        //this lets your program access files like "resources/my-image.png":
        link_step.addArg("--embed-file");
        link_step.addArg("resources/");

        b.getInstallStep().dependOn(&link_step.step);
        const run_step = try rlz.emcc.emscriptenRunStep(b);
        run_step.step.dependOn(&link_step.step);
        const run_option = b.step("run", "Run krpg");
        run_option.dependOn(&run_step.step);
        return;
    }

    // create modules
    const map_mod = b.addModule("map", .{
        .root_source_file = b.path("src/map/_map.zig"),
    });

    const utility_mod = b.addModule("utility", .{
        .root_source_file = b.path("src/utility/_utility.zig"),
    });

    const settings_mod = b.addModule("settings", .{
        .root_source_file = b.path("src/settings/_settings.zig"),
    });

    const types_mod = b.addModule("settings", .{
        .root_source_file = b.path("src/types/_types.zig"),
    });

    // add imports
    map_mod.addImport("raylib", raylib);
    utility_mod.addImport("raylib", raylib);
    settings_mod.addImport("raylib", raylib);
    types_mod.addImport("raylib", raylib);

    map_mod.addImport("raygui", raygui);
    utility_mod.addImport("raygui", raygui);
    settings_mod.addImport("raygui", raygui);
    types_mod.addImport("raygui", raygui);

    map_mod.addImport("utility", utility_mod);
    map_mod.addImport("settings", settings_mod);
    map_mod.addImport("types", types_mod);

    settings_mod.addImport("settings", settings_mod);
    settings_mod.addImport("utility", utility_mod);
    settings_mod.addImport("types", types_mod);

    types_mod.addImport("settings", settings_mod);
    types_mod.addImport("utility", utility_mod);
    types_mod.addImport("map", map_mod);
    types_mod.addImport("types_mod", types_mod);

    utility_mod.addImport("types_mod", types_mod);

    const exe = b.addExecutable(.{ .name = "krpg", .root_source_file = b.path("src/main.zig"), .optimize = optimize, .target = target });

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    exe.root_module.addImport("map", map_mod);
    exe.root_module.addImport("utility", utility_mod);
    exe.root_module.addImport("settings", settings_mod);
    exe.root_module.addImport("types", types_mod);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run krpg");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
