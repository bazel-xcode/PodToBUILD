def _exec(repository_ctx, transformed_command):
    if repository_ctx.attr.trace:
        print("__EXEC", transformed_command)
    output = repository_ctx.execute(transformed_command)
    if repository_ctx.attr.trace:
        print("__OUTPUT", output.stdout, output.stderr)

def _extension(f):
  parts = f.split('/')
  return parts[len(parts) - 1]

def _impl(repository_ctx):
    if repository_ctx.attr.trace:
        print("__RUN with repository_ctx", repository_ctx.attr)
    # Note: the root directory that these commands execute is external/name
    # after the source code has been fetched
    target_name = repository_ctx.attr.target_name
    url = repository_ctx.attr.url
    download = _extension(url)
    _exec(repository_ctx, ["curl", "-LOk", url])
    _exec(repository_ctx, ["unzip", download])
    strip_prefix = repository_ctx.attr.strip_prefix

    # TODO: Jerry remove strip_prefix from the public API. 
    # We should automatically find the .podspec according to CocoaPod semantics
    # rather than dealing with the overhead of trying to figure it out for each
    # pod and URL.
    if strip_prefix and len(strip_prefix) > 0:
        _exec(repository_ctx, ["ditto", strip_prefix + "/", "."])

    _exec(repository_ctx, ["mkdir", "-p", "external/" + target_name])

    repo_tools_labels = repository_ctx.attr.repo_tools_labels
    command_dict = repository_ctx.attr.command_dict
    tool_bin_by_name = {}
    repo_tool_dict = repository_ctx.attr.repo_tool_dict

    if command_dict and repo_tools_labels:
        for tool_label in repo_tools_labels:
            tool_name = repo_tool_dict[str(tool_label)]
            tool_bin_by_name[tool_name] = repository_ctx.path(tool_label)

    ## This seems to be needed here
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
        _exec(repository_ctx, transformed_command)
        idx = idx + 1
    build_file_content = repository_ctx.attr.build_file_content
    if build_file_content and len(build_file_content) > 0:
        # Write the build file
        repository_ctx.file("BUILD", repository_ctx.attr.build_file_content)

pod_repo_ = repository_rule(
    implementation = _impl,
    local = True,
    attrs = {
            "target_name": attr.string(mandatory=True),
            "url": attr.string(mandatory=True),
            "strip_prefix": attr.string(),
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
            strip_prefix = strip_prefix,
            build_file_content =  build_file_content,
            command_dict = cmds,
            repo_tools_labels = tool_labels,
            repo_tool_dict = repo_tools,
            trace = trace
    )

