def _exec(repository_ctx, transformed_command):
    if repository_ctx.attr.trace:
        print("__EXEC", transformed_command)
    output = repository_ctx.execute(transformed_command)
    if repository_ctx.attr.trace:
        print("__OUTPUT", output.return_code, output.stdout, output.stderr)

    return output

# Build extensions is a collection of bazel extensions that are loaded into an
# external repository's BUILD file
build_extensions = """
# pch_with_name_hint
#   Take in a name hint and return the PCH with that name
#
# Parameters
#
#   hint - Suggestion of pch file name. If any part of this is in a PCH
#   filename it will match
#
#   sources - a list of source file patterns with pch extensions to search

def pch_with_name_hint(hint, sources):
    # Recursive glob the sources directories and the root directory
    candidates = native.glob(["*.pch", hint + "/*.pch"] + sources)
    if len(candidates) == 0:
        return None

    # We want to get the candidates in order of lowest to highest
    for candidate in candidates:
        if hint in candidate:
            return candidate
    # It is a convention in iOS/OSX development to use a PCH
    # with the name of the target.
    # This is a hack because, the recursive glob may find some
    # arbitrary PCH.
    return None
"""

global_copts = [
    # Disable all warnings
    "-Wno-everything",
    "-fmodules"
]

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

    if command_dict and repo_tools_labels:
        for tool_label in repo_tools_labels:
            tool_name = repo_tool_dict[str(tool_label)]
            tool_bin_by_name[tool_name] = repository_ctx.path(tool_label)

    fetch_cmd = [
        tool_bin_by_name["RepoTool"],
        target_name,
        "fetch",
        "--url",
        url,
        "--sub_dir",
        repository_ctx.attr.strip_prefix,
        "--trace",
        "true" if repository_ctx.attr.trace else "no"
    ]

    fetch_output = _exec(repository_ctx, fetch_cmd)
    if fetch_output.return_code != 0:
        fail("Could not retrieve pod " + target_name)

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
            for global_copt in global_copts:
                transformed_command.append("--global_copt")
                transformed_command.append(global_copt)
            if repository_ctx.attr.trace:
                transformed_command.append("--trace")
                transformed_command.append("true")
        _exec(repository_ctx, transformed_command)
        idx = idx + 1
    build_file_content = repository_ctx.attr.build_file_content
    if build_file_content and len(build_file_content) > 0:
        # Write the build file
        repository_ctx.file("BUILD", repository_ctx.attr.build_file_content)

    repository_ctx.file("build_extensions.bzl", build_extensions)

pod_repo_ = repository_rule(
    implementation = _impl,
    local = True,
    attrs = {
            "target_name": attr.string(mandatory=True),
            "url": attr.string(mandatory=True),
            "strip_prefix": attr.string(),
            "user_options": attr.string_list(),
            "build_file_content": attr.string(mandatory=True),
            "repo_tools_labels": attr.label_list(),
            "repo_tool_dict": attr.string_dict(),
            "command_dict": attr.string_list_dict(),
            "trace": attr.bool(default=False, mandatory=True)
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
# "//tools/PodSpecToBUILD/bin:RepoTools" if PodSpecToBUILD is in //tools
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
                       strip_prefix = "",
                       user_options = [],
                       build_file_content = "",
                       cmds = { "0" : ["RepoTool"] },
                       repo_tools = { "//tools/PodSpecToBUILD/bin:RepoTools"  : "RepoTool" },
                       trace = False
                       ):
    tool_labels = []
    for tool in repo_tools:
        tool_labels.append(tool)
    pod_repo_(
            name = name,
            target_name = name,
            url = url,
            user_options = user_options,
            strip_prefix = strip_prefix,
            build_file_content =  build_file_content,
            command_dict = cmds,
            repo_tools_labels = tool_labels,
            repo_tool_dict = repo_tools,
            trace = trace
    )

