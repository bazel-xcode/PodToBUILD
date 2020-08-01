import json
import os

def render_podfile(pods):
    """
    This renders out a podfile for a build test
    """
    print("project 'PodsHost/PodsHost.xcodeproj'")
    print("target 'ios-app' do")
   
    skip_pods = [
        # This a macOS pod build we build for iOS
        # It should read podspecs.
        "Chameleon"
    ]
    for pod in pods:
        if pod in skip_pods:
            continue
        print("    pod \"" + pod + "\"")
    print("end")


def render_buildfile(pods):
    """
    This renders out a podfile for a build test
    """
    print("objc_library(name='all', deps=[")
   
    skip_pods = [
        # This a macOS pod build we build for iOS
        # It should read podspecs.
        "Chameleon",

        # These are malformed in the podfile deps
        "lottie-ios",
        "R.swift",
        "R.swift.Library",
        "ReactiveCocoa",
        "SQLite.swift",
    ]
    for pod in pods:
        if pod in skip_pods:
            continue
        print("\"//Vendor/" + pod + "\",")
    print("])")

# Notes:
# dump these urls into ~/Library/Caches/CocoaPods/
# prime the cocoapods search cache ( pod search x )?
# objc_url = 'https://api.github.com/search/repositories?q=language:objc&sort=stars&order=desc&per_page=100'
# swift_url = 'https://api.github.com/search/repositories?q=language:swift&sort=stars&order=desc&per_page=100'
def main():
    # curl
    with open(os.environ["HOME"] + "/Library/Caches/CocoaPods/Top100SwiftPods.json") as top_pods:
        repo_res = json.load(top_pods)

    # This is a value of search terms keyed by pods
    with open(os.environ["HOME"] + "/Library/Caches/CocoaPods/search_index.json") as all_pods:
        pods_json = json.load(all_pods)
        pod_repo = pods_json["master"]

    top_pods = []

    # This returns the max results from a github search query
    max_results = 50

    for repo in repo_res["items"]:
        name = repo["name"]
        # Find a search term including the name
        search = pod_repo.get(name, None)
        if not search:
            continue
        
        # Find a pod of the name
        if not name in search:
            continue
        top_pods.append(name)
        if len(top_pods) == max_results:
            break
    #render_podfile(top_pods)
    render_buildfile(top_pods)

main()    
