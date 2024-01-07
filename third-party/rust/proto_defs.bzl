# Modified from https://github.com/facebook/buck2/blob/7b713a68c49c6be472ea97c0be30adc4b79a3874/proto_defs.bzl

load("@prelude//rust:cargo_package.bzl", "cargo")

def rust_protobuf_library(
        name,
        srcs,
        build_script,
        protos,
        env = None,
        build_env = None,
        deps = None,
        test_deps = None,
        doctests = True):
    build_name = name + "-build"
    proto_name = name + "-proto"

    cargo.rust_binary(
        name = build_name,
        srcs = [build_script],
        crate_root = build_script,
        deps = [
            "//third-party/rust:tonic-build",
        ]
    )

    build_env = build_env or {}
    build_env.update(
        {
            "PROTOC": "$(exe //third-party/protobuf:protoc)",
            "PROTOC_INCLUDE": "$(location //third-party/protobuf:google_protobuf)",
        },
    )

    native.genrule(
        name = proto_name,
        srcs = protos,
        # The binary doesn't look at the command line, but with Buck1, if we don't have $OUT
        # on the command line, it doesn't set the environment variable, so put it on.
        cmd = "$(exe :{}) --required-for-buck1=$OUT".format(build_name),
        env = build_env,
        out = ".",
    )

    library_env = {
        # This is where prost looks for generated .rs files
        "OUT_DIR": "$(location :{})".format(proto_name),
    }

    if env != None:
        library_env.update(env)

    cargo.rust_library(
        name = name,
        srcs = srcs,
        env = library_env,
        rustc_flags = [
            "--cfg=buck2_build",
        ],
        deps = [
            "//third-party/rust:prost",
            "//third-party/rust:prost-types",
        ] + (deps or []),
    )
