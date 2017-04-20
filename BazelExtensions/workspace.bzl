def _impl(repository_ctx):
    repository_ctx.download_and_extract(repository_ctx.attr.url, '.', stripPrefix=repository_ctx.attr.strip_prefix)

    # Note: the root directory that these commands execute is external/name
    # after the source code has been fetched
    target_name = repository_ctx.attr.target_name

    repo_tools = repository_ctx.attr.repo_tools_path
    if repo_tools:
        repo_tools_bin = repository_ctx.path(repo_tools)
        repo_tools_result = repository_ctx.execute([repo_tools_bin, target_name])

    for cmd in repository_ctx.attr.cmds:
        repository_ctx.execute(cmd)

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
            "cmds": attr.string_list(),
            "build_file_content": attr.string(mandatory=True),
            "repo_tools_path": attr.label()
    }
)

# New Pod Repository
#
# @param name: the name of this repo
#
# @param url: the url of this repo
#
# @param owner: the owner at Pinterest of this code
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
# @see repository_context.execute

def new_pod_repository(name, url, owner, strip_prefix = "", repo_tools = "//tools/PodSpecToBUILD/bin:RepoTools", build_file_content = "", cmds = []):
    pod_repo_(
            name = name,
            target_name = name,
            url = url,
            strip_prefix = strip_prefix,
            build_file_content =  build_file_content,
            cmds = cmds,
            repo_tools_path = repo_tools
    )

