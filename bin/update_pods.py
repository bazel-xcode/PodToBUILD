#!/usr/bin/env python3
# update_pods.py Installs pods specified in Pods.WORKSPACE to $SRC_ROOT/Vendor/

from subprocess import Popen, PIPE
import os
import sys
import argparse
import shutil

SRC_ROOT = None

# All known pods, populated after execing `Pods.WORKSPACE`
POD_PATHS = []

# RepoTools binary is adjacent to update_pods.py
def _getRepoToolPath():
    return os.path.dirname(os.path.realpath(__file__)) + "/RepoTools"

def _exec(repository_ctx, command, cwd = None):
    if repository_ctx.GetTrace():
        print("running: " + " ".join(command))
    if cwd:
        origWD = os.getcwd()
        os.chdir(os.path.join(os.path.abspath(sys.path[0]), cwd))

    process = Popen(command, stdout=PIPE, stderr=PIPE)
    result, error = process.communicate()
    if process.returncode != 0:
        print("_exec failed %d %s %s" % (process.returncode, result, error))
        sys.exit(1)

    if repository_ctx.GetTrace():
        print(result)
    if cwd:
        os.chdir(origWD)
    return result

def _cli_bool(b):
    if b:
        return "true"
    return "false"

REPO_TOOL_NAME = "RepoTool"
INIT_REPO_PLACEHOLDER = "__INIT_REPO__"

class RepoToolsInvocationInfo(object):
    def __init__(self, repository_ctx):
        self.child_pods = []
        self.repository_ctx = repository_ctx

    def add_child_pod(self, pod):
        """ Adds the full context of the child pod """
        self.child_pods.append(pod)


class PodWorkspace(object):
    """ PodRepositoryContext """

    def __init__(self):
        self.pods = []

    def add(self, pod):
        """ Adds a pod to all known pods """
        # If there's already a pod defined, then don't add it again.
        for existing_pod in self.pods:
            if existing_pod.target_name == pod.target_name:
                return
        self.pods.append(pod)

    def update(self):
        invocation_info_by_target = {}
        for pod in self.pods:
            invocation_info_by_target[pod.target_name] = RepoToolsInvocationInfo(repository_ctx=pod)

        for pod in self.pods:
            if pod.url and pod.url.startswith("Vendor"):
                parent_pod = pod.url.split("/")[1]
                if parent_pod != pod.target_name:
                    invocation_info_by_target[parent_pod].add_child_pod(pod)

        for pod in self.pods:
            _update_repo_impl(invocation_info_by_target[pod.target_name])

class PodRepositoryContext(object):
    """ PodRepositoryContext """

    def __init__(self,
            target_name,
            url,
            podspec_url,
            strip_prefix,
            user_options,
            install_script_tpl,
            inhibit_warnings = False,
            trace = False,
            enable_modules = True,
            generate_module_map = False,
            generate_header_map = True,
            header_visibility = "pod_support",
            is_dynamic_framework = False,
            is_xcframework = False,
            src_root = None):
        self.target_name = target_name
        self.url = url
        self.podspec_url = podspec_url
        self.strip_prefix = strip_prefix
        self.user_options = user_options
        self.install_script_tpl = install_script_tpl
        self.inhibit_warnings = inhibit_warnings
        self.trace = trace
        self.enable_modules = enable_modules
        self.generate_module_map = generate_module_map
        self.generate_header_map = generate_header_map
        self.header_visibility = header_visibility
        self.is_dynamic_framework = is_dynamic_framework
        self.is_xcframework = is_xcframework
        self.src_root = src_root

    def GetPodRootDir(self):
        return self.src_root + "/Vendor/" + self.target_name

    def GetIdentifier(self):
        identifier_dict = self.__dict__.copy()
        del identifier_dict['src_root']
        return str(identifier_dict)

    def GetTrace(self):
        global OVERRIDE_TRACE
        if OVERRIDE_TRACE:
            return True
        return self.trace

def HashFile(path):
    f = open(path, "rb")
    f_hash = str(hash(f.read()))
    f.close()
    return str(f_hash)

def GetVersion(invocation_info):
    repository_ctx = invocation_info.repository_ctx
    self_hash = HashFile(os.path.realpath(__file__))
    repo_tool_hash = HashFile(_getRepoToolPath())
    ctx_hash = str(hash(repository_ctx.GetIdentifier()))
    child_pods = str(hash("".join([c.url for c in invocation_info.child_pods]))) if invocation_info.child_pods else ""
    return self_hash + repo_tool_hash + ctx_hash + child_pods

# Compiler Options

GLOBAL_COPTS = [
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

INHIBIT_WARNINGS_GLOBAL_COPTS = [
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
        repository_ctx.strip_prefix,
        "--trace",
        "true" if repository_ctx.GetTrace() else "false"
    ]

    _exec(repository_ctx, fetch_cmd, repository_ctx.GetPodRootDir())


def _link_local_repo(repository_ctx, target_name, url):
    cd = repository_ctx.GetPodRootDir()
    from_dir = url + "/"
    to_dir = cd + "/"
    all_files = _exec(repository_ctx, ["ls", url]).decode().split("\n")
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

def _needs_update(invocation_info):
    repository_ctx = invocation_info.repository_ctx
    target_name = repository_ctx.target_name
    pod_root_dir = repository_ctx.GetPodRootDir()
    _exec(repository_ctx, ["/bin/bash", "-c", "mkdir -p " + pod_root_dir])
    _exec(repository_ctx, ["/bin/bash", "-c", "touch .pod-version"], pod_root_dir)
    cached_version = _exec(repository_ctx, ["/bin/bash", "-c", "cat .pod-version"], pod_root_dir).split(b'\n')[0]
    return GetVersion(invocation_info) != cached_version

def _load_repo_if_needed(repository_ctx, repo_tool_bin_path):
    url = repository_ctx.url
    target_name = repository_ctx.target_name
    if not url:
        # We allow putting source code in the Vendor/PodName and then initing
        # the repo with that code.
        return


    if _is_http_url(url) or url.startswith("/"):
        _exec(repository_ctx, ["rm", "-rf", repository_ctx.GetPodRootDir()])
    _exec(repository_ctx, ["mkdir", "-p", repository_ctx.GetPodRootDir()])

    if _is_http_url(url):
        _fetch_remote_repo(repository_ctx, repo_tool_bin_path, target_name, url)
    elif url.startswith("/"):
        _link_local_repo(repository_ctx, target_name, url)
    elif not url.startswith("Vendor"):
        # Assume that if a directory is already in vendor, then we should not
        # link
        _link_local_repo(repository_ctx, target_name, SRC_ROOT + "/" + url)

def _update_repo_impl(invocation_info):
    repository_ctx = invocation_info.repository_ctx
    if repository_ctx.GetTrace():
        print("__RUN with repository_ctx", repository_ctx.__dict__)

    global POD_PATHS
    POD_PATHS.append(repository_ctx.GetPodRootDir())

    if not _needs_update(invocation_info):
        return

    # Note: the pod is not cleaned out if the sourcecode is loaded from the
    # current directory
    print("Updating Pod " + repository_ctx.target_name + "...")

    # Note: the root directory that these commands execute is external/name
    # after the source code has been fetched
    target_name = repository_ctx.target_name
    url = repository_ctx.url
    install_script_tpl = repository_ctx.install_script_tpl
    inhibit_warnings = repository_ctx.inhibit_warnings

    repo_tool_bin_path = _getRepoToolPath()
    tool_bin_by_name = {}
    tool_bin_by_name[REPO_TOOL_NAME] = repo_tool_bin_path

    _load_repo_if_needed(repository_ctx, repo_tool_bin_path)

    # Build up substitutions for the install script
    substitutions = {}
    for name in tool_bin_by_name:
        # Alias the command path to the binary program
        repo_tool_bin = tool_bin_by_name.get(name)
        if not repo_tool_bin:
            fail("invalid repo_tool:" + name)

        entry = [repo_tool_bin]

        # RepoTool in this context is a special placeholder for a RepoTool
        # invocation ( INIT_REPO_PLACEHOLDER )
        if name == REPO_TOOL_NAME:
            # Set the first argument for RepoTool to "target_name"
            entry.append(target_name)
            entry.append("init")

            ## We need to assimilate the child pod options
            for user_option in repository_ctx.user_options:
                entry.extend(["--user_option", "'" + user_option + "'"])

            if inhibit_warnings:
                for global_copt in INHIBIT_WARNINGS_GLOBAL_COPTS:
                    entry.extend(["--global_copt", global_copt])

            for global_copt in GLOBAL_COPTS:
                entry.extend(["--global_copt", global_copt])

            if repository_ctx.url and repository_ctx.url.startswith("Vendor"):
                entry.extend([
                    "--path",
                    repository_ctx.url
                ])

            entry.extend([
                "--trace",
                _cli_bool(repository_ctx.GetTrace()),
                "--enable_modules",
                _cli_bool(repository_ctx.enable_modules),
                "--header_visibility",
                repository_ctx.header_visibility,
                "--generate_module_map",
                _cli_bool(repository_ctx.generate_module_map),
                "--generate_header_map",
                _cli_bool(repository_ctx.generate_header_map),
                "--is_dynamic_framework",
                _cli_bool(repository_ctx.is_dynamic_framework),
                "--is_xcframework",
                _cli_bool(repository_ctx.is_xcframework)
            ])

            for child_pod in invocation_info.child_pods:
                entry.extend(["--child_path", child_pod.target_name])
                entry.extend(["--child_path", child_pod.url])
                for user_option in child_pod.user_options:
                    entry.extend(["--user_option", "'" + user_option + "'"])

            substitutions[INIT_REPO_PLACEHOLDER] = " ".join(entry)
        else:
            substitutions[name] = " ".join(entry)

    # Build up the script
    script = ""

    if repository_ctx.podspec_url:
        # For now, we curl the podspec url before the script runs
        if _is_http_url(repository_ctx.podspec_url):
            script += "curl -O " + repository_ctx.podspec_url
            script += "\n"
        else:
            # Dump a podspec into this directory
            if repository_ctx.podspec_url.startswith("/"):
                script += "ditto " + repository_ctx.podspec_url + " ."
                script += "\n"
            else:
                workspace_dir = repository_ctx.src_root
                script += "ditto " + workspace_dir + "/" + repository_ctx.podspec_url + " ."
                script += "\n"

    if repository_ctx.install_script_tpl:
        for sub in substitutions:
            install_script_tpl = install_script_tpl.replace(sub, substitutions[sub])
        script += install_script_tpl
    else:
        script += substitutions[INIT_REPO_PLACEHOLDER]

    _exec(repository_ctx,
            ["/bin/bash", "-c", script],
            repository_ctx.GetPodRootDir())

    with open(repository_ctx.GetPodRootDir() + "/.pod-version", "w") as version_file:
        version_file.write(GetVersion(invocation_info))

def new_pod_repository(name,
            url = None,
            podspec_url = None,
            strip_prefix = "",
            user_options = [],
            install_script = None,
            inhibit_warnings = True,
            trace = False,
            enable_modules = True,
            generate_module_map = False,
            generate_header_map = False,
            owner = "", # This is a Noop
            header_visibility = "pod_support",
            is_dynamic_framework = False,
            is_xcframework = False):
    """Declare a repository for a Pod
    Args:
         name: the name of this repo

         url: the url of this repo.
            The url may either:
            - A http url pointing to a zip or tar archive, i.e:
              https://github.com/pinterest/PINOperation/archive/1.2.1.zip

            - an absolute path ( used for local development ). Note: We symlink the
              entire contents into /Vendor/__name__.

            - None. If the url is none, we will attempt to init the repository
              without loading source. This is useful for custom Pods that aren't
              provided from a URL.

         podspec_url: the podspec url. By default, we will look in the root of
         the repository, and read a .podspec file. This requires having
         CocoaPods installed on build nodes. If a JSON podspec is provided here,
         then it is not required to run CocoaPods.

         owner: the owner of this dependency

         strip_prefix: a directory prefix to strip from the extracted files.
         Many archives contain a top-level directory that contains all of the
         useful files in archive.

         For most sources, this is typically not needed.

         user_options: an array of key value operators that act on code
         generated `target`s.

         Supported operators:
         PlusEquals ( += ). Add an item to an array

         Implemented for:
         `objc_library` [ `copts`, `deps`, `features`, `sdk_frameworks` ]

         Example usage: add a custom define to the target, Texture's `copts`
         field

         ```
            user_options = [ "Texture.copts += -DTEXTURE_DEBUG " ]
         ```

         install_script: a script used for installation.

         The placeholder __INIT_REPO__ indicates at which point the BUILD file is
         generated, if any.

         inhibit_warnings: whether compiler warnings should be inhibited.

         trace: dump out useful debug info for a given repo.

         generate_module_map: whether a module map should be generated.

         enable_modules: set generated rules enable_modules parameter

         header_visibility: DEPRECATED: This is replaced by headermaps:
         https://github.com/bazelbuild/bazel/pull/3712

         is_dynamic_framework: set to True if the pod uses prebuilt dynamic framework(s)
         
         is_xcframework: set to True if the pod uses prebuilt xcframework
    """

    # The SRC_ROOT is the directory of the WORKSPACE and Pods.WORKSPACE
    global SRC_ROOT
    global WORKSPACE

    repository_ctx = PodRepositoryContext(
            target_name = name,
            url = url,
            podspec_url = podspec_url,
            strip_prefix = strip_prefix,
            user_options = user_options,
            install_script_tpl = install_script,
            inhibit_warnings = inhibit_warnings,
            trace = trace,
            enable_modules = enable_modules,
            generate_module_map = generate_module_map,
            generate_header_map = generate_header_map,
            header_visibility = header_visibility,
            is_dynamic_framework = is_dynamic_framework,
            is_xcframework = is_xcframework,
            src_root = SRC_ROOT)
    WORKSPACE.add(repository_ctx)

def _cleanup_pods():
    """Cleanup removed Pods from Vendor"""
    pods_dir = SRC_ROOT + "/Vendor"
    known_pods = set(POD_PATHS)

    for dirname in os.listdir(pods_dir):
        full_path = pods_dir + "/" + dirname
        if full_path in known_pods:
            continue
        if not os.path.isfile(full_path + "/.pod-version"):
            continue
        shutil.rmtree(full_path)

def _is_http_url(url):
    return url.startswith("http://") or url.startswith("https://")

# Build a release of `RepoTools` if needed. Under a release package,
# the makefile is a noop.
def _build_repo_tools():
    print("Building PodToBUILD dependencies...")
    _exec(PodRepositoryContext(None, None, None, None, None, None, None, trace=True), [
        "make",
        "release"],
        os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

# If using `bazel run` to Vendorize pods, copy the contents required into
# //Vendor/rules_pods. This is required to ensure consistency.
def _vendorize_bazel_extensions_if_needed():
    current_dir = os.path.dirname(os.path.realpath(__file__))
    rules_pods_root = os.path.dirname(current_dir)
    install_root = os.path.dirname(rules_pods_root)
    if os.path.basename(install_root) == "external":
        bazel_extension_dir = os.path.join(rules_pods_root, "BazelExtensions")
        pods_dir = SRC_ROOT + "/Vendor"
        rules_pods_root =  os.path.join(pods_dir, "rules_pods")
        vendor_path =  os.path.join(rules_pods_root, "BazelExtensions")
        if os.path.isdir(rules_pods_root):
            shutil.rmtree(rules_pods_root)
        os.makedirs(rules_pods_root)
        shutil.copytree(bazel_extension_dir, vendor_path)

def load(path):
    """
    Loads a Pods.WORKSPACE file
    """
    global SRC_ROOT
    # Eval the Pods.WORKSPACE
    # Here, we simply collect pods
    with open(SRC_ROOT +  "/" + path, "r") as workspace:
        workspace_str = workspace.read()
        d = dict(locals(), **globals())
        exec(workspace_str, d, d)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_root",
        required=False,
        help="""
    An absolute path to the project's root ( directory of Pods.WORKSPACE and
    WORKSPACE )
    """)

    parser.add_argument("--trace",
        dest="trace",
        action="store_true",
        help="Dump debug info")
    args = parser.parse_args()

    global SRC_ROOT
    SRC_ROOT = args.src_root

    global WORKSPACE
    WORKSPACE = PodWorkspace()
    if not SRC_ROOT:
        SRC_ROOT = os.getcwd()

    print("Updating pods in " + SRC_ROOT)
    global OVERRIDE_TRACE
    OVERRIDE_TRACE = args.trace

    _build_repo_tools()

    load("Pods.WORKSPACE")
    WORKSPACE.update()
    _cleanup_pods()
    _vendorize_bazel_extensions_if_needed()

main()
