def _exec(repository_ctx, transformed_command):
    if repository_ctx.attr.trace:
        print("__EXEC", transformed_command)
    output = repository_ctx.execute(transformed_command)
    if output.return_code != 0:
        print("__OUTPUT", output.return_code, output.stdout, output.stderr)
        fail("Could not exec command " + " ".join(transformed_command))
    elif repository_ctx.attr.trace:
        print("__OUTPUT", output.return_code, output.stdout, output.stderr)

    return output

# Compiler Options


global_copts = [
    '-Wnon-modular-include-in-framework-module',
    "-g",
    "-stdlib=libc++",
    "-DCOCOAPODS=1",
    "-DOBJC_OLD_DISPATCH_PROTOTYPES=0",
    "-fdiagnostics-show-note-include-stack",
    "-fno-common",
    "-fembed-bitcode-marker",
    "-fmessage-length=0",
    "-fpascal-strings",
    "-fstrict-aliasing",
    "-Wno-error=nonportable-include-path"
]

inhibit_warnings_global_copts = [
    "-Wno-everything",
]

def _fetch_remote_repo(repository_ctx, repo_tool_bin, target_name, url):
    fetch_cmd = [
        repo_tool_bin,
        target_name,
        "fetch",
        "--url",
        url,
        "--sub_dir",
        repository_ctx.attr.strip_prefix,
        "--trace",
        "true" if repository_ctx.attr.trace else "false"
    ]

    fetch_output = _exec(repository_ctx, fetch_cmd)
    if fetch_output.return_code != 0:
        fail("Could not retrieve pod " + target_name)

# Link a local repository into external/__TARGET_NAME__


def _link_local_repo(repository_ctx, target_name, url):
    cd = _exec(repository_ctx, ["pwd"]).stdout.split("\n")[0]
    from_dir = url + "/"
    to_dir = cd + "/"
    all_files = _exec(repository_ctx, ["ls", url]).stdout.split("\n")
    # Link all of the files at the root directly
    # ln -s url/* doesn't work.
    for repo_file in all_files:
        if len(repo_file) == 0:
            continue
        link_cmd = [
            "ln",
            "-sf",
            from_dir + repo_file,
            to_dir + repo_file
        ]
        _exec(repository_ctx, link_cmd)

def _cli_bool(b):
    if b:
        return "true"
    return "false"

def _impl(repository_ctx):
    if repository_ctx.attr.trace:
        print("__RUN with repository_ctx", repository_ctx.attr)
    # Note: the root directory that these commands execute is external/name
    # after the source code has been fetched
    target_name = repository_ctx.attr.target_name
    url = repository_ctx.attr.url
    repo_tools_labels = repository_ctx.attr.repo_tools_labels
    command_dict = repository_ctx.attr.command_dict
    tool_bin_by_name = {}
    repo_tool_dict = repository_ctx.attr.repo_tool_dict
    inhibit_warnings = repository_ctx.attr.inhibit_warnings

    if command_dict and repo_tools_labels:
        for tool_label in repo_tools_labels:
            tool_name = repo_tool_dict[str(tool_label)]
            tool_bin_by_name[tool_name] = repository_ctx.path(tool_label)

    if url.startswith("http") or url.startswith("https"):
        _fetch_remote_repo(
            repository_ctx, tool_bin_by_name["RepoTool"], target_name, url)
    else:
        _link_local_repo(repository_ctx, target_name, url)

    # This seems needed
    _exec(repository_ctx, ["mkdir", "-p", "external/" + target_name])

    idx = 0
    cmd_len = len(command_dict)
    for some in command_dict:
        cmd = command_dict[str(idx)]
        transformed_command = cmd
        cmd_path = cmd[0]
        repo_tool_bin = tool_bin_by_name.get(cmd_path)
        # Alias the command path to the binary program
        if repo_tool_bin:
            transformed_command[0] = repo_tool_bin
        # Set the first argument for RepoTool to "target_name"
        if cmd_path == "RepoTool":
            transformed_command.append(target_name)
            transformed_command.append("init")
            for user_option in repository_ctx.attr.user_options:
                transformed_command.append("--user_option")
                transformed_command.append(user_option)

            if inhibit_warnings:
                for global_copt in inhibit_warnings_global_copts:
                    transformed_command.append("--global_copt")
                    transformed_command.append(global_copt)

            for global_copt in global_copts:
                transformed_command.append("--global_copt")
                transformed_command.append(global_copt)

            transformed_command.extend([
                "--trace",
                _cli_bool(repository_ctx.attr.trace),
                "--enable_modules",
                _cli_bool(repository_ctx.attr.enable_modules),
                "--header_visibility",
                repository_ctx.attr.header_visibility,
                "--generate_module_map",
                _cli_bool(repository_ctx.attr.generate_module_map)
            ])

        _exec(repository_ctx, transformed_command)
        idx = idx + 1
    build_file_content = repository_ctx.attr.build_file_content
    if build_file_content and len(build_file_content) > 0:
        # Write the build file
        repository_ctx.file("BUILD", repository_ctx.attr.build_file_content)


pod_repo_ = repository_rule(
    implementation=_impl,
    local=False,
    attrs={
        "target_name": attr.string(mandatory=True),
        "url": attr.string(mandatory=True),
        "strip_prefix": attr.string(),
        "user_options": attr.string_list(),
        "build_file_content": attr.string(mandatory=True),
        "repo_tools_labels": attr.label_list(),
        "repo_tool_dict": attr.string_dict(),
        "command_dict": attr.string_list_dict(),
        "inhibit_warnings": attr.bool(default=False, mandatory=True),
        "trace": attr.bool(default=False, mandatory=True),
        "enable_modules": attr.bool(default=True, mandatory=True),
        "generate_module_map": attr.bool(default=True, mandatory=True),
        "header_visibility": attr.string(),
    }
)

# New Pod Repository
#
# @param name: the name of this repo
#
# @param url: the url of this repo
#
# @param owner: the owner of this dependency
#
# @note Github automatically creates zip files for a commit hash:
# Ex commit: 751edba685e997ea4d8501dcf16df53aac5355a4
# https://github.com/pinterest/PINCache/archive/751edba685e997ea4d8501dcf16df53aac5355a4.zip
# In some cases, the strip prefix will be the commit hash, but make sure the
# code has the correct directory structure when using this.
#
# @param strip_prefix: a directory prefix to strip from the extracted files.
# Many archives contain a top-level directory that contains all of the useful
# files in archive. Instead of needing to specify this prefix over and over in
# the build_file, this field can be used to strip it from all of the extracted
# files.
#
# @param repo_tools: a program to run after downloading the archive.
# Typically, this program is responsible for performing modifications to a
# source repository, in order to support bazel.  i.e.
# "@rules_pods//bin:RepoTools" if PodSpecToBUILD is in //tools
#
# @param build_file_content: string content of a new build file
#
# @param cmds: commands executed within this repository.
# The first part of the command is a string representation of the order the
# commands will be run in. Skylark seems to break when we try to use an array of
# arrays.
#
# @see repository_context.execute
#
# @param repo_tools: a mapping of binaries to command names.
# If we are running something like "mv" or "sed" these binaries are already on
# path, so there is no need to add an entry for them.
#
# @param trace: dump out useful debug info


def new_pod_repository(name,
                       url,
                       owner,
                       strip_prefix="",
                       user_options=[],
                       build_file_content="",
                       cmds={"0": ["RepoTool"]},
                       repo_tools={
                           "@rules_pods//bin:RepoTools": "RepoTool"
                       },
                       inhibit_warnings=False,
                       trace=False,
                       enable_modules=True,
                       generate_module_map=None,
                       header_visibility="pod_support",
                       ):
    if generate_module_map == None:
        generate_module_map = enable_modules

    tool_labels = []
    for tool in repo_tools:
        tool_labels.append(tool)
    pod_repo_(
        name=name,
        target_name=name,
        url=url,
        user_options=user_options,
        strip_prefix=strip_prefix,
        build_file_content=build_file_content,
        command_dict=cmds,
        repo_tools_labels=tool_labels,
        repo_tool_dict=repo_tools,
        inhibit_warnings=inhibit_warnings,
        trace=trace,
        enable_modules=enable_modules,
        generate_module_map=generate_module_map,
        header_visibility=header_visibility
    )
