load("@prelude//http_archive/exec_deps.bzl", "HttpArchiveExecDeps")
load(":releases.bzl", "releases")

RoverReleaseInfo = provider(fields = [
    "version",
    "url",
    "sha256",
])

def _get_rover_release(
        version: str,
        platform: str) -> RoverReleaseInfo:
    if not version in releases:
        fail("Unknown rover release version '{}'. Available versions: {}".format(
            version,
            ", ".join(releases.keys()),
        ))
    rover_version = releases[version]
    artifact = "rover-v{}-{}.tar.gz".format(version, platform)
    if not artifact in rover_version:
        fail("Unsupported platform '{}'. Available artifacts: {}".format(
            platform,
            ", ".join(rover_version.keys()),
        ))
    rover_artifact = rover_version[artifact]
    return RoverReleaseInfo(
        version = version,
        url = rover_artifact["url"],
        sha256 = rover_artifact["sha256"],
    )

def _turn_http_archive_into_rover_distribution(
        providers: ProviderCollection,
        rover_filename: str) -> list[Provider]:
    downloads = providers[DefaultInfo].sub_targets
    include = downloads["include"][DefaultInfo]
    rover = downloads[rover_filename][DefaultInfo]

    return [DefaultInfo(
        sub_targets = {
            "rover": [
                rover,
                RunInfo(args = rover.default_outputs[0]),
            ],
        },
    )]

def _download_rover_distribution_impl(ctx: AnalysisContext) -> Promise:
    rover_filename = "dist/rover" + ctx.attrs.exe_extension

    return ctx.actions.anon_target(native.http_archive, {
        "exec_deps": ctx.attrs._http_archive_exec_deps,
        "sha256": ctx.attrs.sha256,
        "sub_targets": [
            rover_filename,
            "include",
        ],
        "urls": [ctx.attrs.url],
    }).promise.map(lambda providers: _turn_http_archive_into_rover_distribution(
        providers = providers,
        rover_filename = rover_filename,
    ))

download_rover_distribution = rule(
    impl = _download_rover_distribution_impl,
    attrs = {
        "exe_extension": attrs.string(),
        "sha256": attrs.string(),
        "url": attrs.string(),
        "_http_archive_exec_deps": attrs.default_only(attrs.exec_dep(providers = [HttpArchiveExecDeps], default = "prelude//http_archive/tools:exec_deps")),
    },
)

def _host_platform():
    os = host_info().os
    arch = host_info().arch
    if os.is_linux and arch.is_x86_64:
        return "x86_64-unknown-linux-gnu"
    elif os.is_linux and arch.is_aarch64:
        return "aarch64-unknown-linux-gnu"
    elif os.is_macos and arch.is_x86_64:
        return "x86_64-apple-darwin"
    elif os.is_macos and arch.is_aarch64:
        return "aarch64-apple-darwin"
    elif os.is_windows and arch.is_x86_64:
        return "x86_64-pc-windows-msvc"
    else:
        fail("Unknown platform: os={}, arch={}".format(os, arch))

def rover_distribution(
        name: str,
        version: str,
        platform: [None, str] = None):
    if platform == None:
        platform = _host_platform()
    exe_extension = ".exe" if platform.startswith("win") else ""
    release = _get_rover_release(version, platform)
    download_rover_distribution(
        name = name,
        url = release.url,
        sha256 = release.sha256,
        exe_extension = exe_extension,
    )
