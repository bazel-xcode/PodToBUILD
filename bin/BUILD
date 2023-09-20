# Export this file for the repository_rule case
exports_files(["RepoTools"])

config_setting(
    name = "internal_testing_workaround",
    # There is a middleman bug in 6.x.x which breaks CI. This needs some
    # cleanup in here.
    values = {
        "features": "rules_pods.testing",
    }
)

# `update_pods` Vendorizes pods
sh_binary(
    name = "update_pods", 
    srcs = ["update_pods.py"],
    # Load all vendored srcs into the program
    data = select({
        ":internal_testing_workaround": [],
        "//conditions:default": ["//BazelExtensions:vendored_srcs", "RepoTools"],
    }),
    visibility = ["//visibility:public"]
)

